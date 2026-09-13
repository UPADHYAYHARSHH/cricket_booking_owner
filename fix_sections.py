import os

filepath = 'lib/owner_booking/presentation/screens/dashboard/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_block = """
                      // Pending Approvals Section (displayed on home screen when there are requests)
                      if (state.pendingApprovals.isNotEmpty) ...[
                        _buildStaggeredChild(3, Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                    ),
                                    child: const Icon(
                                      Icons.hourglass_top_rounded,
                                      size: 16,
                                      color: Color(0xFFE65100),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const AppText(
                                    text: "Pending Approvals",
                                    color: AppColors.textPrimaryLight,
                                    size: 16,
                                    weight: FontWeight.w700,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE65100),
                                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                    ),
                                    child: AppText(
                                      text: "${state.pendingApprovals.length}",
                                      color: Colors.white,
                                      size: 11,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BookingsScreen(),
                                  ),
                                ),
                                child: const AppText(
                                  text: "View All",
                                  color: AppColors.primaryDarkGreen,
                                  size: 13,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 14),
                        ...List.generate(state.pendingApprovals.length, (index) {
                          final booking = state.pendingApprovals[index] as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: PendingApprovalCard(
                              key: ValueKey(booking['id']),
                              booking: booking,
                            ),
                          );
                        }),
                        const SizedBox(height: 28),
                      ],
"""

new_block = """
                      // Pending Approvals & Awaiting Payments Sections
                      ...(() {
                        final requested = state.pendingApprovals.where((b) => b['status'] != 'approved').toList();
                        final approved = state.pendingApprovals.where((b) => b['status'] == 'approved').toList();
                        
                        Widget buildSection(String title, List<dynamic> bookings, Color color, Color bgColor, IconData icon) {
                          if (bookings.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStaggeredChild(3, Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: bgColor,
                                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                          ),
                                          child: Icon(
                                            icon,
                                            size: 16,
                                            color: color,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AppText(
                                          text: title,
                                          color: AppColors.textPrimaryLight,
                                          size: 16,
                                          weight: FontWeight.w700,
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                          ),
                                          child: AppText(
                                            text: "${bookings.length}",
                                            color: Colors.white,
                                            size: 11,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const BookingsScreen(),
                                        ),
                                      ),
                                      child: const AppText(
                                        text: "View All",
                                        color: AppColors.primaryDarkGreen,
                                        size: 13,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 14),
                              ...List.generate(bookings.length, (index) {
                                final booking = bookings[index] as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                  child: PendingApprovalCard(
                                    key: ValueKey(booking['id']),
                                    booking: booking,
                                  ),
                                );
                              }),
                              const SizedBox(height: 28),
                            ],
                          );
                        }
                        
                        return [
                          buildSection("Pending Approvals", requested, const Color(0xFFE65100), const Color(0xFFFFF3E0), Icons.hourglass_top_rounded),
                          buildSection("Awaiting Payment", approved, AppColors.primaryDarkGreen, AppColors.primaryDarkGreen.withOpacity(0.1), Icons.payment),
                        ];
                      })(),
"""

content = content.replace(old_block.strip(), new_block.strip())

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated dashboard sections")
