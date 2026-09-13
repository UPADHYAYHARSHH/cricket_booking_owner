import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/booking_details_screen.dart';

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _walletData;
  List<dynamic> _withdrawals = [];
  bool _isLoadingWallet = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<BookingsCubit>().fetchBookings();
    _fetchWalletAndHistory();
  }

  Future<void> _fetchWalletAndHistory() async {
    setState(() => _isLoadingWallet = true);
    try {
      // Fetch Wallet
      final walletResponse = await _supabase.rpc('get_owner_wallet');
      
      // Fetch Withdrawals history
      final ownerId = _supabase.auth.currentUser?.id;
      final withdrawalsResponse = await _supabase
          .from('withdrawals')
          .select('*')
          .eq('owner_id', ownerId ?? '')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _walletData = walletResponse as Map<String, dynamic>?;
          _withdrawals = withdrawalsResponse as List<dynamic>;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      if (mounted) {
        setState(() => _isLoadingWallet = false);
      }
    }
  }

  Future<void> _requestWithdrawal(double amount) async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      await _supabase.rpc('request_withdrawal', params: {'p_amount': amount});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal requested successfully!')),
        );
        Navigator.pop(context); // Close dialog
        _fetchWalletAndHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request withdrawal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _showWithdrawDialog() {
    final available = (_walletData?['available_balance'] ?? 0.0) as num;
    if (available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available balance to withdraw.')),
      );
      return;
    }

    final controller = TextEditingController(text: available.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const AppText(text: 'Request Withdrawal', size: 18, weight: FontWeight.bold),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(text: 'Available: ₹$available', color: AppColors.primaryDarkGreen, weight: FontWeight.w600),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (?)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const AppText(text: 'Cancel', color: Colors.grey),
                ),
                ElevatedButton(
                  onPressed: _isRequesting ? null : () {
                    final amount = double.tryParse(controller.text);
                    if (amount == null || amount <= 0 || amount > available) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid amount')),
                      );
                      return;
                    }
                    _requestWithdrawal(amount);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDarkGreen),
                  child: _isRequesting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const AppText(text: 'Withdraw', color: Colors.white),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableBalance = _walletData?['available_balance'] ?? 0.0;
    final totalEarnings = _walletData?['total_earnings'] ?? 0.0;
    
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        centerTitle: true,
        title: const AppText(
          text: 'Earnings & Payouts',
          size: 18,
          weight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Wallet Header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surfaceLight,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildWalletCard('Available', '₹$availableBalance', AppColors.primaryDarkGreen),
                    _buildWalletCard('Total Earned', '₹$totalEarnings', Colors.grey.shade700),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingWallet ? null : _showWithdrawDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const AppText(text: 'Request Withdrawal', color: Colors.white, weight: FontWeight.bold, size: 16),
                  ),
                ),
              ],
            ),
          ),
          
          // Tabs
          Container(
            color: AppColors.surfaceLight,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryDarkGreen,
              unselectedLabelColor: AppColors.textSecondaryLight,
              indicatorColor: AppColors.primaryDarkGreen,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: "Withdrawals"),
                Tab(text: "Booking Revenue"),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWithdrawalsTab(),
                _buildBookingsRevenueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(String title, String amount, Color amountColor) {
    return Column(
      children: [
        AppText(text: title, size: 12, color: AppColors.textSecondaryLight),
        const SizedBox(height: 4),
        AppText(text: amount, size: 22, weight: FontWeight.bold, color: amountColor),
      ],
    );
  }

  Widget _buildWithdrawalsTab() {
    if (_isLoadingWallet) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryDarkGreen));
    }
    if (_withdrawals.isEmpty) {
      return const Center(child: AppText(text: 'No withdrawals found', color: AppColors.textSecondaryLight));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _withdrawals.length,
      itemBuilder: (context, index) {
        final w = _withdrawals[index];
        final amount = w['amount'];
        final status = w['status']?.toString().toUpperCase() ?? 'UNKNOWN';
        final date = DateTime.tryParse(w['created_at'].toString())?.toLocal();
        final dateStr = date != null ? DateFormat('MMM d, yyyy • h:mm a').format(date) : '';
        
        Color statusColor = Colors.orange;
        if (status == 'SUCCESS') statusColor = Colors.green;
        if (status == 'REJECTED' || status == 'FAILED') statusColor = Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: AppText(text: 'Withdrawal Request', weight: FontWeight.w600),
            subtitle: AppText(text: dateStr, size: 12, color: Colors.grey),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(text: '₹$amount', weight: FontWeight.bold, size: 16),
                AppText(text: status, color: statusColor, size: 11, weight: FontWeight.w700),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsRevenueTab() {
    return BlocBuilder<BookingsCubit, BookingsState>(
      builder: (context, state) {
        if (state is BookingsLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryDarkGreen));
        } else if (state is BookingsError) {
          return Center(child: AppText(text: state.message, color: AppColors.error));
        } else if (state is BookingsLoaded) {
          final revenueBookings = state.allBookings.where((b) {
            final status = b['status']?.toString().toLowerCase();
            return status == 'paid' || status == 'confirmed';
          }).toList();

          if (revenueBookings.isEmpty) {
            return const Center(child: AppText(text: 'No booking revenues yet', color: AppColors.textSecondaryLight));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: revenueBookings.length,
            itemBuilder: (context, index) {
              final b = revenueBookings[index];
              final amount = b['owner_earnings'] ?? 0;
              final status = b['payout_status']?.toString().toUpperCase() ?? 'PENDING';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: AppText(text: 'Booking #${b['id'].toString().substring(0, 8)}', weight: FontWeight.w600),
                  subtitle: AppText(text: b['player_name'] ?? 'Player', size: 13),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(text: '+ ₹$amount', weight: FontWeight.bold, size: 15, color: Colors.green),
                      AppText(text: status, color: status == 'SETTLED' ? Colors.green : Colors.orange, size: 11, weight: FontWeight.w700),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
