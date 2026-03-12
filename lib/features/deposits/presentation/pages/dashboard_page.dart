import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/deposit.dart';
import '../providers/deposit_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const _DepositsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/deposit/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Deposit'),
        elevation: 4,
      ),
    );
  }
}

class _DepositsList extends ConsumerStatefulWidget {
  const _DepositsList();

  @override
  ConsumerState<_DepositsList> createState() => _DepositsListState();
}

class _DepositsListState extends ConsumerState<_DepositsList> {
  bool _showUpcomingOnly = false;

  @override
  Widget build(BuildContext context) {
    final asyncDeposits = ref.watch(depositsListProvider);
    final maskEnabled = ref.watch(settingsProvider).maskSensitiveData;

    return asyncDeposits.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No deposits yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[400])),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.push('/deposit/new'),
                  child: const Text('Add your first deposit'),
                ),
              ],
            ),
          );
        }

        final filteredItems = _showUpcomingOnly
            ? items.where((d) => d.isDueSoon(3) && d.status == DepositStatus.active).toList()
            : items;

        final activeDeposits = items.where((d) => d.status == DepositStatus.active && !d.isMatured).toList();
        final upcomingCount = activeDeposits.where((d) => d.isDueSoon(3)).length;
        final maturedCount = items.where((d) => d.isMatured && d.status == DepositStatus.active).length;
        final totalValue = items.fold<double>(0, (sum, d) => sum + d.amountDeposited);

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue[800],
              flexibleSpace: FlexibleSpaceBar(
                title: Text('My Portfolio', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[900]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text('Total Investment', style: TextStyle(color: Colors.white70, fontSize: 14)),
                         const SizedBox(height: 4),
                         Text(
                           maskEnabled ? '₹ ••••••••' : '₹${totalValue.toStringAsFixed(0)}',
                           style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                         ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: _SummaryBox(title: 'Active', count: activeDeposits.length, color: Colors.green, icon: Icons.check_circle_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryBox(title: 'Due Soon', count: upcomingCount, color: Colors.orange, icon: Icons.timer_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryBox(title: 'Matured', count: maturedCount, color: Colors.red, icon: Icons.notification_important_rounded)),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT DEPOSITS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
                    Row(
                      children: [
                        const Text('Upcoming', style: TextStyle(fontSize: 12)),
                        Switch.adaptive(
                          value: _showUpcomingOnly,
                          onChanged: (v) => setState(() => _showUpcomingOnly = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final d = filteredItems[index];
                    return _DepositListItem(deposit: d, maskEnabled: maskEnabled);
                  },
                  childCount: filteredItems.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
      error: (e, st) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryBox({required this.title, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _DepositListItem extends ConsumerWidget {
  final Deposit deposit;
  final bool maskEnabled;

  const _DepositListItem({required this.deposit, required this.maskEnabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = deposit.isMatured ? Colors.red : (deposit.isDueSoon(3) ? Colors.orange : Colors.green);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (deposit.requiresAction) {
                context.push('/deposit/matured/${deposit.id}');
              } else {
                context.push('/deposit/${deposit.id}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      deposit.isMatured ? Icons.error_outline_rounded : (deposit.isDueSoon(3) ? Icons.warning_amber_rounded : Icons.account_balance_rounded),
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deposit.bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${deposit.holdersDisplay} • ${maskEnabled ? '••••' : deposit.srNo}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        maskEnabled ? '₹ ••••' : '₹${deposit.amountDeposited.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Due: ${deposit.dueDate.day}/${deposit.dueDate.month}/${deposit.dueDate.year}',
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
