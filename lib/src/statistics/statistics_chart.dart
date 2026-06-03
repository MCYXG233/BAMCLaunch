import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../ui/theme/colors.dart';

/// 统计图表类型
enum StatisticsChartType {
  dailyPlayTime,
  instanceDistribution,
}

/// 时间范围选项
enum TimeRange {
  week,
  month,
}

/// 每日游戏时长柱状图组件
class DailyPlayTimeChart extends StatelessWidget {
  final Map<DateTime, int> data;
  final Color barColor;
  final Color labelColor;
  final double barWidth;

  const DailyPlayTimeChart({
    super.key,
    required this.data,
    this.barColor = const Color(0xFF6C63FF),
    this.labelColor = const Color(0xFF9E9E9E),
    this.barWidth = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
      );
    }

    final sortedDates = data.keys.toList()..sort();
    final maxValue = data.values.fold<int>(0, (max, v) => v > max ? v : max);
    final maxY = maxValue > 0 ? (maxValue * 1.2).ceilToDouble() : 3600.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => BAColors.darkSurface,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = sortedDates[group.x.toInt()];
              final seconds = data[date] ?? 0;
              return BarTooltipItem(
                '${_formatDate(date)}\n${_formatDuration(seconds)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedDates.length) {
                  return const SizedBox.shrink();
                }
                final date = sortedDates[index];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatDurationShort(value.toInt()),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: labelColor.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedDates.asMap().entries.map((entry) {
          final index = entry.key;
          final date = entry.value;
          final value = (data[date] ?? 0).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDurationShort(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }
}

/// 实例时长饼图组件
class InstanceDistributionChart extends StatefulWidget {
  final Map<String, int> data;
  final List<Color>? colors;

  const InstanceDistributionChart({
    super.key,
    required this.data,
    this.colors,
  });

  @override
  State<InstanceDistributionChart> createState() => _InstanceDistributionChartState();
}

class _InstanceDistributionChartState extends State<InstanceDistributionChart> {
  int _touchedIndex = -1;

  static const List<Color> _defaultColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
    Color(0xFFF38181),
    Color(0xFFAA96DA),
    Color(0xFFFCBAD3),
    Color(0xFFA8D8EA),
    Color(0xFFFFB347),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
      );
    }

    final total = widget.data.values.fold<int>(0, (sum, v) => sum + v);
    final colors = widget.colors ?? _defaultColors;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: widget.data.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final mapEntry = entry.value;
                final isTouched = index == _touchedIndex;
                final percentage = total > 0 ? (mapEntry.value / total * 100) : 0;

                return PieChartSectionData(
                  color: colors[index % colors.length],
                  value: mapEntry.value.toDouble(),
                  title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
                  radius: isTouched ? 60 : 50,
                  titleStyle: TextStyle(
                    fontSize: isTouched ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildLegend(total),
        ),
      ],
    );
  }

  Widget _buildLegend(int total) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.data.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final mapEntry = entry.value;
          final colors = widget.colors ?? _defaultColors;
          final percentage = total > 0 ? (mapEntry.value / total * 100) : 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mapEntry.key,
                    style: TextStyle(
                      color: BAColors.textPrimaryOf(context),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 周/月视图切换组件
class TimeRangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BAColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context,
            '本周',
            TimeRange.week,
          ),
          _buildOption(
            context,
            '本月',
            TimeRange.month,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, TimeRange range) {
    final isSelected = selectedRange == range;

    return GestureDetector(
      onTap: () => onRangeChanged(range),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BAColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : BAColors.textSecondaryOf(context),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 统计卡片组件
class StatisticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;

  const StatisticsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BAColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BAColors.borderOf(context).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: BAColors.textSecondaryOf(context),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: BAColors.textPrimaryOf(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: BAColors.textSecondaryOf(context),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
