import os

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_timer = """
  void _checkAndStartTimer() {
    _timer?.cancel();
    final createdAt = _parseUtcToLocal(widget.booking['created_at']);
    if (createdAt != null) {
      final deadline = createdAt.add(const Duration(minutes: 45));
"""

new_timer = """
  void _checkAndStartTimer() {
    _timer?.cancel();
    final isApproved = widget.booking['status']?.toString().toLowerCase() == 'approved';
    final timeStr = isApproved ? (widget.booking['approved_at'] ?? widget.booking['created_at']) : widget.booking['created_at'];
    final referenceTime = _parseUtcToLocal(timeStr);
    
    if (referenceTime != null) {
      final deadline = referenceTime.add(const Duration(minutes: 45));
"""

content = content.replace(old_timer.strip(), new_timer.strip())

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated timer logic")
