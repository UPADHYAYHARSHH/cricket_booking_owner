import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/revenue/revenue_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/revenue/revenue_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/location_dropdown.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
import 'revenue_analytics.dart';

enum _Period { weekly, monthly, custom }

const _chartPalette = [
  AppColors.primaryDarkGreen,
  AppColors.accentOrange,
  Color(0xFF3B82F6),
  AppColors.goldenYellow,
  Color(0xFF9C27B0),
  Color(0xFFE53935),
  Color(0xFF26A69A),
  Color(0xFF8D6E63),
];

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedLocationId;
  _Period _period = _Period.weekly;
  DateTime? _customStart;
  DateTime? _customEnd;
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = SharedPrefsService.instance.selectedLocationId;
    context.read<RevenueCubit>().fetchRevenueData();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primaryDarkGreen,
                onPrimary: AppColors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _period = _Period.custom;
      });
    }
  }

  Widget _stagger(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final p = _staggerController.value;
        final item = ((p - start) / (end - start)).clamp(0.0, 1.0);
        final curved = Curves.easeOutCubic.transform(item);
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - curved)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: BlocBuilder<RevenueCubit, RevenueState>(
        builder: (context, state) {
          if (state is RevenueLoading || state is RevenueInitial) {
            return const _RevenueSkeleton();
          }

          if (state is RevenueError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    text: state.message,
                    color: AppColors.textSecondaryLight,
                    size: 14,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<RevenueCubit>().fetchRevenueData(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const AppText(
                      text: 'Retry',
                      color: AppColors.white,
                      weight: FontWeight.w600,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGreen,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final loaded = state as RevenueLoaded;
          final filtered = filterByDateRange(
            filterByLocation(loaded.bookings, _selectedLocationId),
            _customStart,
            _customEnd,
          );
          final revenue = totalRevenue(filtered);
          final count = totalBookingsCount(filtered);
          final avg = averageBookingValue(filtered);

          // Determine trend chart points
          List<RevenuePoint> trendPoints;
          String trendLabel;
          if (_period == _Period.custom && _customStart != null && _customEnd != null) {
            trendPoints = customRangeSeries(filtered, _customStart!, _customEnd!);
            trendLabel = '${DateFormat('d MMM').format(_customStart!)} – ${DateFormat('d MMM').format(_customEnd!)}';
          } else if (_period == _Period.monthly) {
            trendPoints = monthlySeries(filtered);
            trendLabel = 'Last 6 months';
          } else {
            trendPoints = weeklySeries(filtered);
            trendLabel = 'Last 7 days';
          }

          return RefreshIndicator(
            color: AppColors.primaryDarkGreen,
            onRefresh: () =>
                context.read<RevenueCubit>().fetchRevenueData(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Hero Header
                SliverToBoxAdapter(child: _stagger(0, _HeroHeader(
                  revenue: revenue,
                  count: count,
                  avg: avg,
                ))),

                // Location Dropdown
                SliverToBoxAdapter(
                  child: _stagger(1, Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: LocationDropdown(
                      locations: loaded.locations,
                      selectedLocationId: _selectedLocationId,
                      onSelected: (id) {
                        setState(() => _selectedLocationId = id);
                        SharedPrefsService.instance.setSelectedLocationId(id);
                      },
                    ),
                  )),
                ),

                // Period Toggle
                SliverToBoxAdapter(
                  child: _stagger(2, Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppText(
                          text: 'Revenue Trend',
                          size: 16,
                          weight: FontWeight.w700,
                        ),
                        _PeriodToggle(
                          period: _period,
                          onChanged: (p) => setState(() => _period = p),
                          onCustomTap: _pickDateRange,
                        ),
                      ],
                    ),
                  )),
                ),

                // Custom date range chip
                if (_period == _Period.custom && _customStart != null && _customEnd != null)
                  SliverToBoxAdapter(
                    child: _stagger(2, Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: _DateRangeChip(
                        start: _customStart!,
                        end: _customEnd!,
                        onTap: _pickDateRange,
                        onClear: () => setState(() {
                          _customStart = null;
                          _customEnd = null;
                          _period = _Period.weekly;
                        }),
                      ),
                    )),
                  ),

                // Trend Chart
                SliverToBoxAdapter(
                  child: _stagger(3, Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _TrendChartCard(
                      points: trendPoints,
                      subtitle: _period == _Period.custom ? trendLabel : null,
                    ),
                  )),
                ),

                // Revenue by Ground
                SliverToBoxAdapter(
                  child: _stagger(4, Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: const AppText(
                      text: 'Revenue by Ground',
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                  )),
                ),
                SliverToBoxAdapter(
                  child: _stagger(4, Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _GroundRevenueCard(
                      points: groundWiseRevenue(filtered),
                    ),
                  )),
                ),

                // Revenue by Sport
                SliverToBoxAdapter(
                  child: _stagger(5, Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: const AppText(
                      text: 'Revenue by Sport',
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                  )),
                ),
                SliverToBoxAdapter(
                  child: _stagger(5, Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    child: _SportRevenueCard(
                      points: sportWiseRevenue(filtered),
                    ),
                  )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final double revenue;
  final int count;
  final double avg;

  const _HeroHeader({
    required this.revenue,
    required this.count,
    required this.avg,
  });

  @override
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
                      text: '₹${revenue.toInt()}',
                      color: AppColors.white,
                      size: 32,
                      weight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
              // Mini stats on the right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MiniStat(
                    icon: Icons.receipt_long_rounded,
                    label: 'Bookings',
                    value: '$count',
                  ),
                  const SizedBox(height: 8),
                  _MiniStat(
                    icon: Icons.trending_up_rounded,
                    label: 'Avg Value',
                    value: '₹${avg.toInt()}',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizes.radiusXs),
          ),
          child: Icon(icon, color: AppColors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: value,
              color: AppColors.white,
              size: 15,
              weight: FontWeight.w700,
            ),
            AppText(
              text: label,
              color: AppColors.white.withValues(alpha: 0.6),
              size: 11,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Period Toggle ───────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;
  final VoidCallback onCustomTap;
  const _PeriodToggle({
    required this.period,
    required this.onChanged,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: 'Weekly',
            selected: period == _Period.weekly,
            onTap: () => onChanged(_Period.weekly),
          ),
          _ToggleOption(
            label: 'Monthly',
            selected: period == _Period.monthly,
            onTap: () => onChanged(_Period.monthly),
          ),
          _ToggleOption(
            label: 'Custom',
            selected: period == _Period.custom,
            onTap: onCustomTap,
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AppText(
          text: label,
          size: 12,
          weight: FontWeight.w600,
          color: selected ? AppColors.white : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

// ─── Trend Chart ─────────────────────────────────────────────────────────────

class _TrendChartCard extends StatelessWidget {
  final List<RevenuePoint> points;
  final String? subtitle;
  const _TrendChartCard({required this.points, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        points.fold<double>(0, (m, p) => p.amount > m ? p.amount : m);
    final maxY = maxAmount <= 0 ? 100.0 : maxAmount * 1.25;

    return _ChartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppText(
                text: subtitle!,
                size: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          if (points.every((p) => p.amount == 0))
            const SizedBox(
              height: 200,
              child: _EmptyChartMessage(text: 'No revenue in this period yet.'),
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, rodIndex, rod, mouse) => BarTooltipItem(
                        '₹${rod.toY.toInt()}',
                        const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              points[i].label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: points[i].amount,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: AppColors.borderLight,
                            ),
                            color: AppColors.primaryDarkGreen,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Ground Revenue ──────────────────────────────────────────────────────────

class _GroundRevenueCard extends StatelessWidget {
  final List<RevenuePoint> points;
  const _GroundRevenueCard({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((p) => p.amount == 0)) {
      return const _ChartCard(
        child: SizedBox(
          height: 120,
          child: _EmptyChartMessage(text: 'No ground revenue yet.'),
        ),
      );
    }

    final maxAmount = points.first.amount;
    return _ChartCard(
      child: Column(
        children: [
          for (int i = 0; i < points.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == points.length - 1 ? 0 : 16,
              ),
              child: _RankedBarRow(
                rank: i + 1,
                label: points[i].label,
                amount: points[i].amount,
                fraction: maxAmount == 0 ? 0 : points[i].amount / maxAmount,
                color: _chartPalette[i % _chartPalette.length],
              ),
            ),
        ],
      ),
    );
  }
}

class _RankedBarRow extends StatelessWidget {
  final int rank;
  final String label;
  final double amount;
  final double fraction;
  final Color color;

  const _RankedBarRow({
    required this.rank,
    required this.label,
    required this.amount,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isTopRank = rank <= 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Rank badge
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isTopRank
                    ? color.withValues(alpha: 0.15)
                    : AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
              ),
              child: Center(
                child: AppText(
                  text: '$rank',
                  size: 11,
                  weight: FontWeight.w700,
                  color: isTopRank ? color : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppText(
                text: label,
                size: 13,
                weight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppText(
              text: '₹${amount.toInt()}',
              size: 14,
              weight: FontWeight.w700,
              color: AppColors.primaryDarkGreen,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: 6,
                  width: constraints.maxWidth,
                  color: AppColors.borderLight,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 6,
                  width: constraints.maxWidth * fraction.clamp(0.02, 1.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sport Revenue ───────────────────────────────────────────────────────────

class _SportRevenueCard extends StatelessWidget {
  final List<RevenuePoint> points;
  const _SportRevenueCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final total = points.fold<double>(0, (s, p) => s + p.amount);
    if (points.isEmpty || total == 0) {
      return const _ChartCard(
        child: SizedBox(
          height: 120,
          child: _EmptyChartMessage(text: 'No sport-wise revenue yet.'),
        ),
      );
    }

    return _ChartCard(
      child: Row(
        children: [
          // Donut chart with center total
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: [
                      for (int i = 0; i < points.length; i++)
                        PieChartSectionData(
                          value: points[i].amount,
                          color: _chartPalette[i % _chartPalette.length],
                          radius: 24,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      text: '${points.length}',
                      size: 18,
                      weight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                    AppText(
                      text: 'Sports',
                      size: 10,
                      color: AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < points.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == points.length - 1 ? 0 : 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _chartPalette[i % _chartPalette.length],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText(
                            text: points[i].label,
                            size: 12,
                            weight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppText(
                          text:
                              '₹${points[i].amount.toInt()}',
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bgLight,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: AppText(
                            text:
                                '${(points[i].amount / total * 100).toStringAsFixed(0)}%',
                            size: 10,
                            weight: FontWeight.w700,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Range Chip ─────────────────────────────────────────────────────────

class _DateRangeChip extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateRangeChip({
    required this.start,
    required this.end,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 16,
              color: AppColors.primaryDarkGreen,
            ),
            const SizedBox(width: 8),
            AppText(
              text: '${fmt.format(start)} – ${fmt.format(end)}',
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.primaryDarkGreen,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Cards ────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyChartMessage extends StatelessWidget {
  final String text;
  const _EmptyChartMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 36,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: 8),
          AppText(
            text: text,
            size: 13,
            color: AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _RevenueSkeleton extends StatelessWidget {
  const _RevenueSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double? width}) => Shimmer.fromColors(
          baseColor: AppColors.borderLight,
          highlightColor: AppColors.bgLight,
          child: Container(
            height: height,
            width: width ?? double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Location dropdown skeleton
        block(48),
        const SizedBox(height: 20),
        // Summary cards skeleton
        Row(
          children: [
            Expanded(child: block(80)),
            const SizedBox(width: 12),
            Expanded(child: block(80)),
            const SizedBox(width: 12),
            Expanded(child: block(80)),
          ],
        ),
        const SizedBox(height: 28),
        // Chart skeleton
        block(260),
        const SizedBox(height: 28),
        // Ground revenue skeleton
        block(180),
        const SizedBox(height: 28),
        // Sport revenue skeleton
        block(160),
      ],
    );
  }
}
