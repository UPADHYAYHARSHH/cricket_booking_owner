import os
import re

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r'// Action buttons: Decline & Approve\s*Row\(\s*children: \[\s*Expanded\(\s*child: OutlinedButton\([\s\S]*?text: "Approve"[\s\S]*?\),\s*\),\s*\],\s*\),'

replacement = """// Action buttons: Decline & Approve
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
                              ),"""

new_content = re.sub(pattern, replacement, content)
if new_content == content:
    print("Replace failed")
else:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Replace succeeded")
