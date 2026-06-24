import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';

enum _ScanStatus { scanning, loading, found, notFound, notOwned, error }

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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_status != _ScanStatus.scanning) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || code.isEmpty) return;

    setState(() => _status = _ScanStatus.loading);
    await _controller.stop();

    try {
      final booking = await _bookingRepo.getBookingForCheckIn(code);
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

      final users = await _bookingRepo.fetchUsers([booking['user_id'] as String]);
      final user = users.isNotEmpty ? users.first : null;

      setState(() {
        _booking = {
          ...booking,
          'ground_name': ground?['name'] ?? 'Unknown Ground',
          'sport': ground?['category'] ?? '',
          'player_name': user?['full_name'] ?? user?['name'] ?? 'Player',
        };
        _status = _ScanStatus.found;
      });
    } catch (e) {
      setState(() {
        _status = _ScanStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _approve() async {
    final bookingId = _booking?['id'] as String?;
    if (bookingId == null) return;
    setState(() => _isCheckingIn = true);
    try {
      await _bookingRepo.checkInBooking(bookingId);
      setState(() {
        _booking = {..._booking!, 'checked_in': true, 'checked_in_at': DateTime.now().toIso8601String()};
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
          if (_status != _ScanStatus.scanning)
            Container(
              color: const Color(0xFFF5F6FA),
              child: Center(child: _resultCard()),
            ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    switch (_status) {
      case _ScanStatus.loading:
        return const CircularProgressIndicator(color: AppColors.primaryDarkGreen);
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
      case _ScanStatus.error:
        return _message(
          icon: Icons.error_outline,
          color: AppColors.error,
          title: 'Something went wrong',
          subtitle: _errorMessage ?? 'Please try again.',
        );
      case _ScanStatus.found:
        return _bookingCard();
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

  Widget _bookingCard() {
    final booking = _booking!;
    final isCheckedIn = booking['checked_in'] == true;
    DateTime? slotTime;
    try {
      slotTime = DateTime.parse(booking['slot_time'] as String);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCheckedIn ? Icons.check_circle : Icons.confirmation_number_outlined,
              size: 40,
              color: isCheckedIn ? AppColors.primaryDarkGreen : AppColors.accentOrange,
            ),
            const AppSizedBox(height: 12),
            AppText(text: booking['player_name'] as String, size: 18, weight: FontWeight.w800),
            const AppSizedBox(height: 4),
            AppText(
              text: booking['ground_name'] as String,
              size: 14,
              color: AppColors.primaryDarkGreen,
              weight: FontWeight.w600,
            ),
            const AppSizedBox(height: 12),
            _row('Sport', _formatSport(booking['sport'] as String? ?? '')),
            if (slotTime != null)
              _row('Slot', DateFormat('d MMM, h:mm a').format(slotTime)),
            _row('Amount', '₹${((booking['amount'] as num? ?? 0) / 100).toStringAsFixed(0)}'),
            _row('Status', (booking['status'] as String? ?? '').toUpperCase()),
            const AppSizedBox(height: 20),
            if (isCheckedIn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: AppText(
                    text: 'Already checked in',
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
              )
            else
              AppButton(
                title: 'Approve / Check In',
                isLoading: _isCheckingIn,
                onTap: _approve,
              ),
            const AppSizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _scanAgain,
                child: const AppText(
                  text: 'Scan Another Ticket',
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: AppText(text: label, size: 12, color: AppColors.textSecondaryLight),
            ),
            Expanded(
              child: AppText(text: value, size: 13, weight: FontWeight.w700),
            ),
          ],
        ),
      );

  String _formatSport(String id) => id
      .split('_')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
}
