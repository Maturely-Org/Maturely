import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/portfolio_analytics.dart';

class BankDistributionChart extends StatelessWidget {
  final List<BankDistribution> banks;
  final double? size;

  const BankDistributionChart({
    super.key,
    required this.banks,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
        final s = size ?? maxW.clamp(160.0, 240.0);

        if (banks.isEmpty) {
          return SizedBox(
            height: s,
            child: Center(
              child: Text(
                'No data available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          );
        }

        final titleFontSize = s < 190 ? 10.0 : 12.0;

        return SizedBox(
          height: s,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: s * 0.22,
              sections: banks
                  .map(
                    (bank) => PieChartSectionData(
                      color: _parseColor(bank.color),
                      value: bank.percentage,
                      title: '${bank.percentage.toStringAsFixed(1)}%',
                      radius: s * 0.34,
                      titleStyle: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.blue;
    } catch (_) {
      return Colors.blue;
    }
  }
}

class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyTrend> trends;
  final double? height;

  const MonthlyTrendChart({
    super.key,
    required this.trends,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
        final h = height ?? (maxW < 380 ? 210.0 : 250.0);
        final isNarrow = maxW < 380;

        if (trends.isEmpty) {
          return SizedBox(
            height: h,
            child: Center(
              child: Text(
                'No trend data available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          );
        }

        final maxY = trends
            .map((t) => t.cumulativeAmount)
            .reduce((a, b) => a > b ? a : b);
        final minX = 0.0;
        final maxX = trends.length.toDouble() - 1;

        final safeMaxY = maxY > 0 ? maxY : 1000.0;
        final leftReserved = isNarrow ? 46.0 : 60.0;
        final bottomReserved = isNarrow ? 26.0 : 30.0;
        final labelFont = isNarrow ? 9.0 : 10.0;

        int showEvery() {
          if (trends.length <= 6) return 1;
          if (trends.length <= 10) return 2;
          return isNarrow ? 3 : 2;
        }

        final step = showEvery();

        return SizedBox(
          height: h,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: safeMaxY * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: trends.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.cumulativeAmount);
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: !isNarrow),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: leftReserved,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '?${(value / 1000).toStringAsFixed(0)}K',
                          style: TextStyle(fontSize: labelFont),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: bottomReserved,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= trends.length) return const SizedBox.shrink();
                        if (index % step != 0 && index != trends.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final month = trends[index].month;
                        return Text(
                          '${month.month}/${month.year.toString().substring(2)}',
                          style: TextStyle(fontSize: labelFont),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMaxY / 5,
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StatusDistributionChart extends StatelessWidget {
  final List<StatusDistribution> statuses;
  final double? size;

  const StatusDistributionChart({
    super.key,
    required this.statuses,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 150.0;
        final s = size ?? maxW.clamp(140.0, 220.0);

        if (statuses.isEmpty) {
          return SizedBox(
            height: s,
            child: Center(
              child: Text(
                'No status data available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          );
        }

        final titleFontSize = s < 170 ? 10.0 : 12.0;

        return SizedBox(
          height: s,
          child: PieChart(
            PieChartData(
              sectionsSpace: 1,
              centerSpaceRadius: s * 0.27,
              sections: statuses
                  .map(
                    (status) => PieChartSectionData(
                      color: _parseColor(status.color),
                      value: status.percentage,
                      title: '${status.count}',
                      radius: s * 0.30,
                      titleStyle: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.blue;
    } catch (_) {
      return Colors.blue;
    }
  }
}

class ChartLegend extends StatelessWidget {
  final List<ChartDataPoint> items;
  final bool isHorizontal;

  const ChartLegend({
    super.key,
    required this.items,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseColor(item.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${item.subtitle})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
        .toList();

    if (isHorizontal) {
      return Wrap(children: children);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.blue;
    } catch (_) {
      return Colors.blue;
    }
  }
}
