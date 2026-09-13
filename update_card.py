import os

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

notify_method = """
  Future<void> _notifyUser() async {
    setState(() => _isActionLoading = true);
    try {
      final bookingId = widget.booking['id'].toString();
      await context.read<BookingsCubit>().notifyUserToPay(bookingId);
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text("Notification Sent"),
          description: const Text("User has been reminded to complete payment."),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text("Error notifying user"),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _declineRequest() async {
"""

content = content.replace("Future<void> _declineRequest() async {", notify_method)

build_buttons = """
                              Row(
                                children: widget.booking['status'] == 'approved' ? [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: (_isActionLoading || _remainingSeconds <= 0)
                                          ? null
                                          : _notifyUser,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryDarkGreen,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                        ),
                                      ),
                                      child: _isActionLoading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const AppText(
                                              text: "Notify User",
                                              size: 12,
                                              weight: FontWeight.w700,
                                              color: AppColors.white,
                                            ),
                                    ),
                                  ),
                                ] : [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isActionLoading ? null : _declineRequest,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                        ),
                                      ),
                                      child: const AppText(
                                        text: "Decline",
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.md),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: (_isActionLoading || _remainingSeconds <= 0)
                                          ? null
                                          : _approveRequest,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryDarkGreen,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                        ),
                                      ),
                                      child: _isActionLoading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const AppText(
                                              text: "Approve",
                                              size: 12,
                                              weight: FontWeight.w700,
                                              color: AppColors.white,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
"""

old_build_buttons = """
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isActionLoading ? null : _declineRequest,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                        ),
                                      ),
                                      child: const AppText(
                                        text: "Decline",
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.md),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: (_isActionLoading || _remainingSeconds <= 0)
                                          ? null
                                          : _approveRequest,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryDarkGreen,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                        ),
                                      ),
                                      child: _isActionLoading
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const AppText(
                                              text: "Approve",
                                              size: 12,
                                              weight: FontWeight.w700,
                                              color: AppColors.white,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
"""

content = content.replace(old_build_buttons.strip(), build_buttons.strip())

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated pending_approval_card UI")
