import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/slots/slots_screen.dart';

class MySportsScreen extends StatefulWidget {
  const MySportsScreen({super.key});

  @override
  State<MySportsScreen> createState() => _MySportsScreenState();
}

class _MySportsScreenState extends State<MySportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GroundCubit>().fetchOwnerGrounds();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppText(
          text: "My Sports & Turfs",
          size: 18,
          weight: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add-sport');
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const AppText(
          text: "Add New Sport",
          color: Colors.white,
          weight: FontWeight.w600,
        ),
      ),
      body: BlocBuilder<GroundCubit, GroundState>(
        builder: (context, state) {
          if (state is GroundLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (state is GroundLoaded) {
            if (state.grounds.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.grounds.length,
              itemBuilder: (context, index) {
                final ground = state.grounds[index];
                return _GroundCard(ground: ground);
              },
            );
          }

          if (state is GroundError) {
            return Center(
              child: AppText(text: state.message, color: Colors.red),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedFootball,
            size: 80,
            color: Colors.grey.withOpacity(0.2),
          ),
          const AppSizedBox(height: 16),
          const AppText(
            text: "No sports registered yet",
            size: 16,
            weight: FontWeight.w600,
            color: Colors.grey,
          ),
          const AppSizedBox(height: 8),
          const AppText(
            text: "Click '+' to add your first turf",
            size: 14,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _GroundCard extends StatelessWidget {
  final dynamic ground;
  const _GroundCard({required this.ground});

  @override
  Widget build(BuildContext context) {
    final bool isVerified = ground['is_verified'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              ground['imageUrl'] ?? 'https://via.placeholder.com/400x200',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: ground['name'] ?? 'Turf Name',
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppText(
                        text: isVerified ? "Verified" : "Pending",
                        size: 11,
                        weight: FontWeight.w600,
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const AppSizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const AppSizedBox(width: 4),
                    Expanded(
                      child: AppText(
                        text: ground['address'] ?? 'Address',
                        size: 12,
                        color: Colors.grey,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const AppSizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: "₹${ground['price_per_hour']}/hr",
                      size: 14,
                      weight: FontWeight.w700,
                      color: const Color(0xFFFF6B00),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SlotsScreen(),
                              ),
                            );
                          },
                          child: const AppText(
                            text: "Manage Slots",
                            size: 12,
                            weight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                        const AppSizedBox(width: 8),
                        TextButton(
                          onPressed: () {},
                          child: const AppText(
                            text: "Edit",
                            size: 12,
                            weight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
