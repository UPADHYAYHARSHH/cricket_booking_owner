import re

with open('e:/Downloads/box_cricket/cricket_booking_owner/lib/owner_booking/presentation/screens/revenue/revenue_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_build = '''    @override
    Widget build(BuildContext context) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B8457), Color(0xFF065236)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button + title
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const AppText(
                  text: 'Revenue',
                  size: 20,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Total revenue hero number
            AppText(
              text: 'Total Earnings',
              color: AppColors.white.withValues(alpha: 0.7),
              size: 13,
              weight: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            AppText(
              text: '?\',
              color: AppColors.white,
              size: 36,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 20),

            // Mini stats row
            Row(
              children: [
                _MiniStat(
                  icon: Icons.receipt_long_rounded,
                  label: 'Bookings',
                  value: '\',
                ),
                const SizedBox(width: 20),
                _MiniStat(
                  icon: Icons.trending_up_rounded,
                  label: 'Avg Value',
                  value: '?\',
                ),
              ],
            ),
          ],
        ),
      );
    }'''

new_build = '''  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B8457), Color(0xFF065236)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const AppText(
                text: 'Revenue',
                size: 20,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: 'Total Earnings',
                      color: AppColors.white.withValues(alpha: 0.7),
                      size: 13,
                      weight: FontWeight.w500,
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      text: '?\',
                      color: AppColors.white,
                      size: 32,
                      weight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
              // Mini stats on the right for compactness
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MiniStat(
                    icon: Icons.receipt_long_rounded,
                    label: 'Bookings',
                    value: '\',
                  ),
                  const SizedBox(height: 8),
                  _MiniStat(
                    icon: Icons.trending_up_rounded,
                    label: 'Avg Value',
                    value: '?\',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }'''

# Replace old_build with new_build, but be careful with indentation
old_build_clean = re.sub(r'\s+', '', old_build)
# Instead of doing exact match, let's just replace the build method using regex
pattern = r'  @override\s+Widget build\(BuildContext context\) \{.*?return Container\(.*?width: double\.infinity,.*?padding: EdgeInsets\.only\(.*?top: MediaQuery\.of\(context\)\.padding\.top \+ 12,.*?left: 20,.*?right: 20,.*?bottom: 20,.*?\),.*?decoration: const BoxDecoration\(.*?gradient: LinearGradient\(.*?colors: \[Color\(0xFF0B8457\), Color\(0xFF065236\)\],.*?begin: Alignment\.topLeft,.*?end: Alignment\.bottomRight,.*?\),.*?\),.*?child: Column\(.*?crossAxisAlignment: CrossAxisAlignment\.start,.*?children: \[.*?// Back button \+ title.*?Row\(.*?children: \[.*?GestureDetector\(.*?onTap: \(\) => Navigator\.pop\(context\),.*?child: Container\(.*?padding: const EdgeInsets\.all\(8\),.*?decoration: BoxDecoration\(.*?color: AppColors\.white\.withValues\(alpha: 0\.15\),.*?borderRadius: BorderRadius\.circular\(AppSizes\.radiusSm\),.*?\),.*?child: const Icon\(.*?Icons\.arrow_back_ios_new_rounded,.*?color: AppColors\.white,.*?size: 18,.*?\),.*?\),.*?\),.*?const SizedBox\(width: 12\),.*?const AppText\(.*?text: \'Revenue\',.*?size: 20,.*?weight: FontWeight\.w700,.*?color: AppColors\.white,.*?\),.*?\],.*?\),.*?const SizedBox\(height: 28\),.*?// Total revenue hero number.*?AppText\(.*?text: \'Total Earnings\',.*?color: AppColors\.white\.withValues\(alpha: 0\.7\),.*?size: 13,.*?weight: FontWeight\.w500,.*?\),.*?const SizedBox\(height: 8\),.*?AppText\(.*?text: \'?\$\{revenue\.toInt\(\)\}\',.*?color: AppColors\.white,.*?size: 36,.*?weight: FontWeight\.bold,.*?\),.*?const SizedBox\(height: 20\),.*?// Mini stats row.*?Row\(.*?children: \[.*?_MiniStat\(.*?icon: Icons\.receipt_long_rounded,.*?label: \'Bookings\',.*?value: \'\\',.*?\),.*?const SizedBox\(width: 20\),.*?_MiniStat\(.*?icon: Icons\.trending_up_rounded,.*?label: \'Avg Value\',.*?value: \'?\$\{avg\.toInt\(\)\}\',.*?\),.*?\],.*?\),.*?\],.*?\),.*?\);.*?\}'

content = re.sub(pattern, new_build, content, flags=re.DOTALL)

with open('e:/Downloads/box_cricket/cricket_booking_owner/lib/owner_booking/presentation/screens/revenue/revenue_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
