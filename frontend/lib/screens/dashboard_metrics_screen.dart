import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';

class DashboardMetricsScreen extends StatefulWidget {
  const DashboardMetricsScreen({super.key});

  @override
  State<DashboardMetricsScreen> createState() => _DashboardMetricsScreenState();
}

class _DashboardMetricsScreenState extends State<DashboardMetricsScreen> {
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData(_selectedPeriod));
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData(period);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.metrics == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final metrics = provider.metrics;
          final totalSales = metrics?['totalSales'] ?? 0;
          final totalBills = metrics?['totalBills'] ?? 0;
          final highSales = provider.highSales;
          final lowSales = provider.lowSales;

          return RefreshIndicator(
            onRefresh: () => provider.fetchDashboardData(_selectedPeriod),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  _buildSummaryCards(totalSales, totalBills),
                  const SizedBox(height: 24),
                  if (highSales.isNotEmpty || lowSales.isNotEmpty)
                    _buildCharts(highSales, lowSales)
                  else
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No sales data available for this period', style: TextStyle(color: Colors.grey)),
                    )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSegmentButton('daily', 'Daily'),
        const SizedBox(width: 8),
        _buildSegmentButton('weekly', 'Weekly'),
        const SizedBox(width: 8),
        _buildSegmentButton('monthly', 'Monthly'),
      ],
    );
  }

  Widget _buildSegmentButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _onPeriodChanged(value);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSummaryCards(num totalSales, num totalBills) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Sales',
            value: '₹${totalSales.toStringAsFixed(2)}',
            icon: Icons.currency_rupee,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Total Invoices',
            value: '$totalBills',
            icon: Icons.receipt_long,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildCharts(List<dynamic> highSales, List<dynamic> lowSales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highSales.isNotEmpty) ...[
          const Text('Top Performing Products (Revenue)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildBarChart(highSales, Colors.green),
          ),
          const SizedBox(height: 32),
        ],
        if (lowSales.isNotEmpty) ...[
          const Text('Lowest Performing Products (Revenue)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildBarChart(lowSales, Colors.orange),
          ),
        ],
      ],
    );
  }

  Widget _buildBarChart(List<dynamic> data, Color color) {
    List<BarChartGroupData> barGroups = [];
    double maxRevenue = 0;

    for (int i = 0; i < data.length; i++) {
      final revenue = (data[i]['totalRevenue'] as num).toDouble();
      if (revenue > maxRevenue) maxRevenue = revenue;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
             BarChartRodData(
               toY: revenue,
               color: color,
               width: 22,
               borderRadius: BorderRadius.circular(4),
             )
          ],
        )
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final name = data[group.x.toInt()]['_id'] ?? 'Unknown';
              return BarTooltipItem(
                '$name\n₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                final name = (data[index]['_id'] ?? 'Unknown').toString();
                final shortName = name.length > 8 ? '${name.substring(0, 6)}..' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(shortName, style: const TextStyle(fontSize: 10)),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      )
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
