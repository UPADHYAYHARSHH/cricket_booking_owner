import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/revenue/revenue_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/revenue/revenue_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/location_dropdown.dart';
import 'revenue_analytics.dart';

enum _Period { weekly, monthly }

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

class _RevenueScreenState extends State<RevenueScreen> {
  String? _selectedLocationId;
  _Period _period = _Period.weekly;

  @override
  void initState() {
    super.initState();
    context.read<RevenueCubit>().fetchRevenueData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDarkGreen),
        title: const AppText(text: 'Revenue', size: 18, weight: FontWeight.w700),
        centerTitle: true,
      ),
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
                  AppText(text: state.message, color: AppColors.error, size: 14),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.read<RevenueCubit>().fetchRevenueData(),
                    child: const AppText(
                      text: 'Retry',
                      color: AppColors.primaryDarkGreen,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final loaded = state as RevenueLoaded;
          final filtered = filterByLocation(loaded.bookings, _selectedLocationId);

          return RefreshIndicator(
            color: AppColors.primaryDarkGreen,
            onRefresh: () => context.read<RevenueCubit>().fetchRevenueData(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                LocationDropdown(
                  locations: loaded.locations,
                  selectedLocationId: _selectedLocationId,
                  onSelected: (id) => setState(() => _selectedLocationId = id),
                ),
                const SizedBox(height: 20),
                _SummaryRow(bookings: filtered),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Revenue Trend',
                  trailing: _PeriodToggle(
                    period: _period,
                    onChanged: (p) => setState(() => _period = p),
                  ),
                ),
                const SizedBox(height: 16),
                _TrendChartCard(
                  points: _period == _Period.weekly
                      ? weeklySeries(filtered)
                      : monthlySeries(filtered),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Revenue by Ground'),
                const SizedBox(height: 16),
                _GroundRevenueCard(points: groundWiseRevenue(filtered)),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Revenue by Sport'),
                const SizedBox(height: 16),
                _SportRevenueCard(points: sportWiseRevenue(filtered)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          text: title.toUpperCase(),
          color: AppColors.primaryDarkGreen,
          size: 13,
          weight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  const _SummaryRow({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final revenue = totalRevenue(bookings);
    final count = totalBookingsCount(bookings);
    final avg = averageBookingValue(bookings);

    return Row(
      children: [
        _SummaryCard(label: 'Total Revenue', value: '₹${revenue.toInt()}'),
        const SizedBox(width: 12),
        _SummaryCard(label: 'Bookings', value: '$count'),
        const SizedBox(width: 12),
        _SummaryCard(label: 'Avg / Booking', value: '₹${avg.toInt()}'),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            AppText(text: value, size: 18, weight: FontWeight.w800, color: AppColors.primaryDarkGreen),
            const SizedBox(height: 4),
            AppText(text: label, size: 11, color: Colors.grey, align: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;
  const _PeriodToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(label: 'Weekly', selected: period == _Period.weekly, onTap: () => onChanged(_Period.weekly)),
          _ToggleOption(label: 'Monthly', selected: period == _Period.monthly, onTap: () => onChanged(_Period.monthly)),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AppText(
          text: label,
          size: 11,
          weight: FontWeight.w700,
          color: selected ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  final List<RevenuePoint> points;
  const _TrendChartCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxAmount = points.fold<double>(0, (m, p) => p.amount > m ? p.amount : m);
    final maxY = maxAmount <= 0 ? 100.0 : maxAmount * 1.25;

    return _ChartCard(
      height: 220,
      child: points.every((p) => p.amount == 0)
          ? const _EmptyChartMessage(text: 'No revenue in this period yet.')
          : BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '₹${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= points.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            points[i].label,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                          color: AppColors.primaryDarkGreen,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _GroundRevenueCard extends StatelessWidget {
  final List<RevenuePoint> points;
  const _GroundRevenueCard({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((p) => p.amount == 0)) {
      return const _ChartCard(height: 120, child: _EmptyChartMessage(text: 'No ground revenue yet.'));
    }

    final maxAmount = points.first.amount;
    return _ChartCard(
      height: null,
      child: Column(
        children: [
          for (int i = 0; i < points.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == points.length - 1 ? 0 : 14),
              child: _RankedBarRow(
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
  final String label;
  final double amount;
  final double fraction;
  final Color color;
  const _RankedBarRow({
    required this.label,
    required this.amount,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText(text: label, size: 13, weight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            AppText(text: '₹${amount.toInt()}', size: 13, weight: FontWeight.w700, color: AppColors.primaryDarkGreen),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(height: 8, width: constraints.maxWidth, color: const Color(0xFFF0F1F4)),
                Container(height: 8, width: constraints.maxWidth * fraction.clamp(0.02, 1.0), color: color),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SportRevenueCard extends StatelessWidget {
  final List<RevenuePoint> points;
  const _SportRevenueCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final total = points.fold<double>(0, (s, p) => s + p.amount);
    if (points.isEmpty || total == 0) {
      return const _ChartCard(height: 120, child: _EmptyChartMessage(text: 'No sport-wise revenue yet.'));
    }

    return _ChartCard(
      height: null,
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: [
                  for (int i = 0; i < points.length; i++)
                    PieChartSectionData(
                      value: points[i].amount,
                      color: _chartPalette[i % _chartPalette.length],
                      radius: 28,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < points.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == points.length - 1 ? 0 : 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _chartPalette[i % _chartPalette.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText(text: points[i].label, size: 12, weight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        AppText(
                          text: '${(points[i].amount / total * 100).toStringAsFixed(0)}%',
                          size: 12,
                          weight: FontWeight.w700,
                          color: Colors.grey,
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

class _ChartCard extends StatelessWidget {
  final double? height;
  final Widget child;
  const _ChartCard({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
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
      child: AppText(text: text, size: 13, color: Colors.grey),
    );
  }
}

class _RevenueSkeleton extends StatelessWidget {
  const _RevenueSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: height,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        block(36),
        block(80),
        block(220),
        block(180),
        block(160),
      ],
    );
  }
}
