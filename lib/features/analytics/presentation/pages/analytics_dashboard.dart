import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../widgets/charts.dart';
import '../../domain/entities/portfolio_analytics.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class AnalyticsDashboard extends ConsumerWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(portfolioAnalyticsProvider);
    final maskEnabled = ref.watch(settingsProvider).maskSensitiveData;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: analyticsAsync.when(
        data: (analytics) => _AnalyticsContent(analytics: analytics, maskEnabled: maskEnabled),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(error: error.toString()),
      ),
    );
  }
}

class _AnalyticsContent extends ConsumerWidget {
  final PortfolioAnalytics analytics;
  final bool maskEnabled;

  const _AnalyticsContent({required this.analytics, required this.maskEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(portfolioAnalyticsProvider);
        await ref.read(portfolioAnalyticsProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Portfolio Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
            pinned: true,
            backgroundColor: Colors.indigo[900],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(portfolioAnalyticsProvider),
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSummarySection(context),
                   const SizedBox(height: 24),
                   _SectionHeader(title: 'Growth & Trends', icon: Icons.trending_up, color: Colors.green),
                   const SizedBox(height: 12),
                   _buildTrendsCard(context),
                   const SizedBox(height: 24),
                   _SectionHeader(title: 'Asset Distribution', icon: Icons.pie_chart, color: Colors.blue),
                   const SizedBox(height: 12),
                   _buildDistributionCards(context),
                   const SizedBox(height: 24),
                   _SectionHeader(title: 'Upcoming Maturities', icon: Icons.event, color: Colors.orange),
                   const SizedBox(height: 12),
                   _buildMaturityCard(context),
                   const SizedBox(height: 24),
                   _SectionHeader(title: 'Top Performers', icon: Icons.star, color: Colors.purple),
                   const SizedBox(height: 12),
                   _buildTopPerformersCard(context),
                   const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final s = analytics.summary;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _MetricCard(title: 'Total Invested', value: maskEnabled ? '₹ ••••••' : '₹${_format(s.totalAmountDeposited)}', icon: Icons.account_balance, color: Colors.blue),
        _MetricCard(title: 'Total Value', value: maskEnabled ? '₹ ••••••' : '₹${_format(s.totalDueAmount)}', icon: Icons.account_balance_wallet, color: Colors.indigo),
        _MetricCard(title: 'Active Deposits', value: s.activeDeposits.toString(), icon: Icons.check_circle, color: Colors.green),
        _MetricCard(title: 'Projected Growth', value: '₹${_format(s.totalInterestEarned)}', icon: Icons.trending_up, color: Colors.teal),
      ],
    );
  }

  Widget _buildTrendsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Monthly Growth Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: MonthlyTrendChart(trends: analytics.monthlyTrends),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCards(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Bank Distribution', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                BankDistributionChart(banks: analytics.bankDistribution),
                const SizedBox(height: 16),
                _ChartLegendVertical(items: analytics.bankDistribution.map((b) => ChartDataPoint(label: b.bankName, value: b.percentage, color: b.color)).toList()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Status Split', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                StatusDistributionChart(statuses: analytics.statusDistribution),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaturityCard(BuildContext context) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
       child: Padding(
         padding: const EdgeInsets.all(16),
         child: analytics.maturityTimeline.isEmpty 
           ? const Center(child: Text('No upcoming maturities'))
           : Column(
               children: analytics.maturityTimeline.take(4).map((m) => ListTile(
                 leading: CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.1), child: const Icon(Icons.timer, color: Colors.orange, size: 20)),
                 title: Text('${m.month.month}/${m.month.year}'),
                 subtitle: Text('${m.count} deposits maturing'),
                 trailing: Text(maskEnabled ? '₹ •••' : '₹${_format(m.amount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
               )).toList(),
             ),
       ),
    );
  }

  Widget _buildTopPerformersCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: analytics.topPerformers.map((p) => ListTile(
            dense: true,
            leading: const Icon(Icons.star, color: Colors.amber, size: 20),
            title: Text(p.title),
            trailing: Text(p.displayValue, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
          )).toList(),
        ),
      ),
    );
  }

  String _format(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
      ],
    );
  }
}

class _ChartLegendVertical extends StatelessWidget {
  final List<ChartDataPoint> items;
  const _ChartLegendVertical({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: _parseColor(i.color), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(i.label, style: const TextStyle(fontSize: 12))),
            Text('${i.value.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
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

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Analytics Error', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
