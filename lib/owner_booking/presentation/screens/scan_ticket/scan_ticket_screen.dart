import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';
import 'package:turfpro_owner/utils/qr_crypto.dart';

enum _ScanStatus {
  scanning,
  loading,
  found,
  notFound,
  notOwned,
  error,
  invalidQr,
  timeWarning,
  sportMismatch,
}

/// Lets the owner scan a player's ticket QR (which encodes the booking id),
/// look up the booking, and approve / check the player in at the venue.
class ScanTicketScreen extends StatefulWidget {
  const ScanTicketScreen({super.key});

  @override
  State<ScanTicketScreen> createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends State<ScanTicketScreen> {
  final _bookingRepo = getIt<BookingRepository>();
  final _controller = MobileScannerController();

  _ScanStatus _status = _ScanStatus.scanning;
  Map<String, dynamic>? _booking;
  String? _errorMessage;
  bool _isCheckingIn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extracts the booking ID from the QR code string.
  /// QR format: "$orderId | Ground: ${ground.name} | Owner: ${ownerId} | Ground ID: ${groundId}"
  String? _extractBookingId(String qrString) {
    // Try to extract booking ID from formatted QR string
    if (qrString.contains(' | ')) {
      final parts = qrString.split(' | ');
      if (parts.isNotEmpty) {
        final bookingId = parts[0].trim();
        // Validate it looks like a UUID or order ID
        if (bookingId.isNotEmpty &&
            (bookingId.contains('-') || bookingId.startsWith('order_'))) {
          return bookingId;
        }
      }
    }

    // Fallback: if the raw string looks like a UUID directly
    if (qrString.contains('-') && qrString.length >= 30) {
      return qrString.trim();
    }

    return null;
  }

  /// Checks if the current time is within the valid check-in window.
  /// Returns null if valid, or a warning message if outside the window.
  String? _checkTimeWindow(Map<String, dynamic> booking) {
    DateTime? slotTime;
    try {
      slotTime = DateTime.parse(booking['slot_time'] as String);
    } catch (_) {
      return null; // Can't parse time, allow check-in
    }

    final now = DateTime.now();
    final difference = slotTime.difference(now);

    // Allow check-in up to 10 minutes before slot start
    if (difference.inMinutes > 10) {
      final minsEarly = difference.inMinutes;
      return 'Warning: This slot starts in $minsEarly minutes. Check-in is allowed up to 10 minutes before.';
    }

    // Allow check-in up to 2 hours after slot start
    if (difference.inHours < -2) {
      return 'Warning: This slot started more than 2 hours ago.';
    }

    return null; // Within valid window
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_status != _ScanStatus.scanning) return;
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.isEmpty) return;

    setState(() => _status = _ScanStatus.loading);
    await _controller.stop();

    // Decrypt the QR data if it's encrypted
    String processedCode = code;
    if (QrCrypto.isEncryptedQr(code)) {
      final decrypted = QrCrypto.decryptQrData(code);
      if (decrypted == null) {
        setState(() {
          _status = _ScanStatus.invalidQr;
          _errorMessage =
              'Failed to decrypt QR code. Invalid or corrupted data.';
        });
        return;
      }
      processedCode = decrypted;
    }

    await _processScannedCode(processedCode);
  }

  Future<void> _approve() async {
    final bookingId = _booking?['id'] as String?;
    final userId = _booking?['user_id'] as String?;
    final groundName = _booking?['ground_name'] as String? ?? 'Unknown Ground';
    if (bookingId == null) return;
    setState(() => _isCheckingIn = true);
    try {
      await _bookingRepo.checkInBooking(bookingId);

      // Send notification to the user
      if (userId != null) {
        final now = DateTime.now();
        final checkInTime = DateFormat('h:mm a').format(now);
        final checkInDate = DateFormat('d MMM yyyy').format(now);

        await _bookingRepo.sendCheckInNotification(
          userId: userId,
          bookingId: bookingId,
          groundName: groundName,
          checkInTime: checkInTime,
          checkInDate: checkInDate,
        );
      }

      setState(() {
        _booking = {
          ..._booking!,
          'checked_in': true,
          'checked_in_at': DateTime.now().toIso8601String(),
        };
        _isCheckingIn = false;
      });
    } catch (_) {
      setState(() => _isCheckingIn = false);
    }
  }

  void _scanAgain() {
    setState(() {
      _status = _ScanStatus.scanning;
      _booking = null;
      _errorMessage = null;
    });
    _controller.start();
  }

  Future<void> _scanFromGallery() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _status = _ScanStatus.loading);

      // Scan the image for QR code using mobile_scanner
      final capture = await _controller.analyzeImage(image.path);

      if (capture == null || capture.barcodes.isEmpty) {
        setState(() {
          _status = _ScanStatus.invalidQr;
          _errorMessage = 'No QR code found in the selected image.';
        });
        return;
      }

      final code = capture.barcodes.first.rawValue;
      if (code == null || code.isEmpty) {
        setState(() {
          _status = _ScanStatus.invalidQr;
          _errorMessage = 'QR code is empty or unreadable.';
        });
        return;
      }

      // Decrypt the QR data if it's encrypted
      String processedCode = code;
      if (QrCrypto.isEncryptedQr(code)) {
        final decrypted = QrCrypto.decryptQrData(code);
        if (decrypted == null) {
          setState(() {
            _status = _ScanStatus.invalidQr;
            _errorMessage =
                'Failed to decrypt QR code. Invalid or corrupted data.';
          });
          return;
        }
        processedCode = decrypted;
      }

      // Process the scanned code the same way as camera scan
      await _processScannedCode(processedCode);
    } catch (e) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = 'Failed to scan image: $e';
      });
    }
  }

  Future<void> _processScannedCode(String code) async {
    final bookingId = _extractBookingId(code);
    if (bookingId == null) {
      setState(() {
        _status = _ScanStatus.invalidQr;
        _errorMessage = 'Format mismatch.\nRaw data: $code';
      });
      return;
    }

    try {
      final booking = await _bookingRepo.getBookingForCheckIn(bookingId);
      if (booking == null) {
        setState(() => _status = _ScanStatus.notFound);
        return;
      }

      final ground = booking['grounds'] as Map<String, dynamic>?;
      final ownerId = ground?['owner_id'] as String?;
      final currentOwnerId = FirebaseAuth.instance.currentUser?.uid;
      if (ownerId == null || ownerId != currentOwnerId) {
        setState(() => _status = _ScanStatus.notOwned);
        return;
      }

      final users = await _bookingRepo.fetchUsers([
        booking['user_id'] as String,
      ]);
      final user = users.isNotEmpty ? users.first : null;

      // Validate sport: booking's sport_name should match ground's category
      final groundCategory = (ground?['category'] as String? ?? '')
          .toLowerCase();
      final bookingSport = (booking['sport_name'] as String? ?? '')
          .toLowerCase();
      String? sportWarning;
      if (groundCategory.isNotEmpty &&
          bookingSport.isNotEmpty &&
          groundCategory != bookingSport) {
        sportWarning =
            'Sport mismatch: Ground is "${_formatSport(groundCategory)}" but booking is for "${_formatSport(bookingSport)}".';
      }

      final timeWarning = _checkTimeWindow(booking);

      setState(() {
        _booking = {
          ...booking,
          'ground_name': ground?['name'] ?? 'Unknown Ground',
          'sport': ground?['category'] ?? '',
          'booking_sport': booking['sport_name'] ?? '',
          'player_name': user?['full_name'] ?? user?['name'] ?? 'Player',
          'time_warning': timeWarning,
          'sport_warning': sportWarning,
        };
        if (sportWarning != null) {
          _status = _ScanStatus.sportMismatch;
        } else {
          _status = timeWarning != null
              ? _ScanStatus.timeWarning
              : _ScanStatus.found;
        }
      });
    } catch (e) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const AppText(
          text: 'Scan Ticket',
          size: 18,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_status == _ScanStatus.scanning)
            MobileScanner(controller: _controller, onDetect: _onDetect)
          else
            const SizedBox.shrink(),
          if (_status == _ScanStatus.scanning)
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          if (_status == _ScanStatus.scanning)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _scanFromGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        AppText(
                          text: 'Scan from Gallery',
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_status != _ScanStatus.scanning)
            Container(
              color: AppColors.bgLight,
              child: Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _resultCard(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    switch (_status) {
      case _ScanStatus.loading:
        return const CircularProgressIndicator(
          color: AppColors.primaryDarkGreen,
        );
      case _ScanStatus.notFound:
        return _message(
          icon: Icons.error_outline,
          color: AppColors.error,
          title: 'Ticket not found',
          subtitle: "This QR code doesn't match any booking.",
        );
      case _ScanStatus.notOwned:
        return _message(
          icon: Icons.block,
          color: AppColors.error,
          title: 'Not your venue',
          subtitle: "This ticket isn't for one of your venues.",
        );
      case _ScanStatus.invalidQr:
        return _message(
          icon: Icons.qr_code_scanner,
          color: AppColors.error,
          title: 'Invalid QR Code',
          subtitle:
              _errorMessage ??
              "This doesn't appear to be a valid CricBook ticket QR code.",
        );
      case _ScanStatus.timeWarning:
        return _bookingCard(context);
      case _ScanStatus.sportMismatch:
        return _bookingCard(context);
      case _ScanStatus.error:
        return _message(
          icon: Icons.error_outline,
          color: AppColors.error,
          title: 'Something went wrong',
          subtitle: _errorMessage ?? 'Please try again.',
        );
      case _ScanStatus.found:
        return _bookingCard(context);
      case _ScanStatus.scanning:
        return const SizedBox.shrink();
    }
  }

  Widget _message({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: color),
          const AppSizedBox(height: 16),
          AppText(text: title, size: 18, weight: FontWeight.w700, color: color),
          const AppSizedBox(height: 8),
          AppText(
            text: subtitle,
            size: 13,
            color: AppColors.textSecondaryLight,
            align: TextAlign.center,
          ),
          const AppSizedBox(height: 24),
          AppButton(title: 'Scan Again', onTap: _scanAgain),
        ],
      ),
    );
  }

  Widget _bookingCard(BuildContext context) {
    final booking = _booking!;
    final isCheckedIn = booking['checked_in'] == true;
    final timeWarning = booking['time_warning'] as String?;
    final sportWarning = booking['sport_warning'] as String?;
    DateTime? slotTime;
    try {
      slotTime = DateTime.parse(booking['slot_time'] as String);
    } catch (_) {}

    DateTime? checkedInAt;
    try {
      final checkedInStr = booking['checked_in_at'] as String?;
      if (checkedInStr != null) checkedInAt = DateTime.parse(checkedInStr);
    } catch (_) {}

    String timeRange = _getFormattedTimeRange(booking['period'] as String?);
    String slotDisplay = '';
    if (slotTime != null) {
      slotDisplay = DateFormat('d MMM').format(slotTime);
      if (timeRange.isNotEmpty) {
        slotDisplay += '\n$timeRange';
      } else {
        slotDisplay += '\n${DateFormat('h:mm a').format(slotTime)}';
      }
    }

    final sportKey = (booking['sport'] as String? ?? '').toLowerCase();
    final bookingSportKey = (booking['booking_sport'] as String? ?? '')
        .toLowerCase();
    final displaySport = bookingSportKey.isNotEmpty
        ? _formatSport(bookingSportKey)
        : _formatSport(sportKey);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ClipPath(
        clipper: _TicketClipper(holeRadius: 16, topOffset: 200),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Pattern
              Container(
                height: 200,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? const Color(0xFFF0F9F4)
                      : const Color(0xFFFFF8EC),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCheckedIn
                            ? AppColors.primaryDarkGreen.withOpacity(0.1)
                            : AppColors.accentOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCheckedIn
                            ? Icons.check_circle_rounded
                            : Icons.confirmation_number_rounded,
                        size: 40,
                        color: isCheckedIn
                            ? AppColors.primaryDarkGreen
                            : AppColors.accentOrange,
                      ),
                    ),
                    const AppSizedBox(height: 12),
                    AppText(
                      text: booking['player_name'] as String,
                      size: 22,
                      weight: FontWeight.w900,
                      align: TextAlign.center,
                    ),
                    const AppSizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const AppSizedBox(width: 4),
                        Flexible(
                          child: AppText(
                            text: booking['ground_name'] as String,
                            size: 13,
                            color: Colors.grey,
                            weight: FontWeight.w600,
                            align: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dashed Divider
              Row(
                children: List.generate(
                  40,
                  (index) => Expanded(
                    child: Container(
                      height: 1.5,
                      color: index % 2 == 0
                          ? Colors.grey.shade300
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),

              // Details Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _detailBlock(
                            'Sport',
                            displaySport,
                            icon: _getSportIcon(sportKey),
                          ),
                        ),
                        Expanded(
                          child: _detailBlock(
                            'Amount',
                            '₹${(booking['amount'] as num? ?? 0).toStringAsFixed(0)}', // Fixed amount display
                            icon: Icons.currency_rupee_rounded,
                          ),
                        ),
                      ],
                    ),
                    const AppSizedBox(height: 24),
                    Row(
                      children: [
                        if (slotTime != null)
                          Expanded(
                            child: _detailBlock(
                              'Slot',
                              slotDisplay,
                              icon: Icons.access_time_rounded,
                            ),
                          ),
                        Expanded(
                          child: _detailBlock(
                            'Status',
                            (booking['status'] as String? ?? 'CONFIRMED')
                                .toUpperCase(),
                            icon: Icons.info_outline_rounded,
                            valueColor: isCheckedIn
                                ? AppColors.primaryDarkGreen
                                : null,
                          ),
                        ),
                      ],
                    ),

                    if (isCheckedIn && checkedInAt != null) ...[
                      const AppSizedBox(height: 24),
                      _detailBlock(
                        'Checked In At',
                        DateFormat('d MMM yyyy, h:mm a').format(checkedInAt),
                        icon: Icons.how_to_reg_rounded,
                        valueColor: AppColors.primaryDarkGreen,
                        center: true,
                      ),
                    ],

                    // Warnings
                    if (sportWarning != null) ...[
                      const AppSizedBox(height: 20),
                      _warningBox(sportWarning, isError: true),
                    ],

                    if (timeWarning != null && !isCheckedIn) ...[
                      const AppSizedBox(height: 16),
                      _warningBox(timeWarning, isError: false),
                    ],

                    const AppSizedBox(height: 32),

                    // Actions
                    if (isCheckedIn)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: AppColors.primaryDarkGreen,
                              size: 20,
                            ),
                            AppSizedBox(width: 8),
                            AppText(
                              text: 'Verified & Checked In',
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.primaryDarkGreen,
                            ),
                          ],
                        ),
                      )
                    else
                      AppButton(
                        title: 'Approve / Check In',
                        isLoading: _isCheckingIn,
                        onTap: _approve,
                      ),

                    const AppSizedBox(height: 16),
                    TextButton(
                      onPressed: _scanAgain,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const AppText(
                        text: 'Scan Another Ticket',
                        size: 14,
                        weight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailBlock(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
    bool center = false,
  }) {
    Widget textWidget = AppText(
      text: value,
      size: 14,
      weight: FontWeight.w800,
      color: valueColor ?? Colors.black87,
      align: center ? TextAlign.center : TextAlign.start,
    );

    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.grey),
              const AppSizedBox(width: 4),
            ],
            AppText(
              text: label,
              size: 12,
              color: Colors.grey,
              weight: FontWeight.w600,
            ),
          ],
        ),
        const AppSizedBox(height: 6),
        textWidget,
      ],
    );
  }

  String _getFormattedTimeRange(String? period) {
    if (period == null || !period.contains('|')) return '';
    final parts = period.split('|');
    if (parts.length <= 1) return '';

    final times = parts[1]
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (times.isEmpty) return '';

    List<int> hours24 = [];
    for (String time in times) {
      final timeParts = time.split(':');
      if (timeParts.isNotEmpty) {
        int h = int.tryParse(timeParts[0]) ?? 0;
        hours24.add(h);
      }
    }
    hours24.sort();
    if (hours24.isEmpty) return '';

    List<String> ranges = [];
    int blockStart = hours24.first;
    int prevHour = hours24.first;

    String formatHour(int h) {
      int wrappedH = h % 24;
      final amPm = wrappedH >= 12 ? 'PM' : 'AM';
      int hour12 = wrappedH > 12
          ? wrappedH - 12
          : (wrappedH == 0 ? 12 : wrappedH);
      return '${hour12.toString().padLeft(2, '0')}:00 $amPm';
    }

    for (int i = 1; i < hours24.length; i++) {
      if (hours24[i] == prevHour + 1) {
        prevHour = hours24[i];
      } else {
        ranges.add('${formatHour(blockStart)} - ${formatHour(prevHour + 1)}');
        blockStart = hours24[i];
        prevHour = hours24[i];
      }
    }
    ranges.add('${formatHour(blockStart)} - ${formatHour(prevHour + 1)}');

    String rangeStr = ranges.join(',\n');
    if (times.length > 1) {
      return '${times.length} Slots\n$rangeStr';
    }
    return rangeStr;
  }

  Widget _warningBox(String text, {required bool isError}) {
    final color = isError ? AppColors.error : AppColors.accentOrange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const AppSizedBox(width: 10),
          Expanded(
            child: AppText(
              text: text,
              size: 12,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSport(String id) => id
      .split('_')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  IconData _getSportIcon(String category) {
    switch (category.toLowerCase()) {
      case 'box_cricket':
      case 'cricket':
        return Icons.sports_cricket;
      case 'football':
      case 'futsal':
        return Icons.sports_soccer;
      case 'badminton':
      case 'tennis':
      case 'pickleball':
      case 'table_tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'basketball':
        return Icons.sports_basketball;
      case 'swimming':
        return Icons.pool;
      case 'golf':
        return Icons.sports_golf;
      default:
        return Icons.sports;
    }
  }
}

class _TicketClipper extends CustomClipper<Path> {
  final double holeRadius;
  final double topOffset;

  _TicketClipper({required this.holeRadius, required this.topOffset});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0.0, topOffset - holeRadius);

    // Left cutout
    path.arcToPoint(
      Offset(0.0, topOffset + holeRadius),
      radius: Radius.circular(holeRadius),
      clockwise: true,
    );

    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, topOffset + holeRadius);

    // Right cutout
    path.arcToPoint(
      Offset(size.width, topOffset - holeRadius),
      radius: Radius.circular(holeRadius),
      clockwise: true,
    );

    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) =>
      oldClipper.holeRadius != holeRadius || oldClipper.topOffset != topOffset;
}
