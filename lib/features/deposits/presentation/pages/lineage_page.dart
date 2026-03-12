import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/lineage_providers.dart';
import '../providers/deposit_providers.dart';
import '../../domain/entities/deposit_chain.dart';
import '../../domain/entities/deposit.dart';

class LineagePage extends ConsumerWidget {
  const LineagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chainsAsync = ref.watch(chainsWithDepositsProvider);
    final orphanedDepositsAsync = ref.watch(orphanedDepositsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(chainsWithDepositsProvider);
          ref.invalidate(orphanedDepositsProvider);
          ref.invalidate(depositsListProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Deposit Lineage', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
              pinned: true,
              stretch: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, ref),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Active Chains', Icons.account_tree, Colors.green),
                  ],
                ),
              ),
            ),
              chainsAsync.when(
                data: (chains) => chains.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyChainsWidget(context))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildChainCard(context, chains[index]),
                            childCount: chains.length,
                          ),
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, st) => SliverToBoxAdapter(child: _ErrorWidget(error: e.toString())),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Matured Deposits', Icons.schedule, Colors.orange),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              orphanedDepositsAsync.when(
                data: (deposits) => deposits.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyMaturedWidget(context))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: _buildMaturedContent(context, deposits),
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) => SliverToBoxAdapter(child: _ErrorWidget(error: e.toString())),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, MaterialColor color) {
    return Row(
      children: [
        Icon(icon, color: color[700], size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color[700],
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildMaturedContent(BuildContext context, List<Deposit> deposits) {
    final maturedDeposits = deposits.where((d) => d.isMatured).toList();
    final requiringAction =
        maturedDeposits.where((d) => d.requiresAction).toList();
    final processed =
        maturedDeposits.where((d) => d.isPartOfLineage).toList();

    return Column(
      children: [
        if (requiringAction.isNotEmpty) ...[
          _buildActionRequiredSection(context, requiringAction),
          const SizedBox(height: 16),
        ],
        if (processed.isNotEmpty) ...[
          _buildProcessedSection(context, processed),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[700]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_tree,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit Lineage',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your deposit chains and reinvestments',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          // Debug button
          IconButton(
            onPressed: () => _testChainCreation(context, ref),
            icon: const Icon(
              Icons.bug_report,
              color: Colors.white,
            ),
            tooltip: 'Test Chain Creation',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChainsWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_tree,
              size: 48,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Deposit Chains',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first chain by reinvesting a matured deposit',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainCard(BuildContext context, DepositChain chain) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewChainDetails(context, chain),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_tree,
                      color: Colors.green[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chain.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '${chain.depositIds.length} deposits • ₹${chain.totalAmount.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildChainTimeline(context, chain),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChainTimeline(BuildContext context, DepositChain chain) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: chain.depositIds.length,
        itemBuilder: (context, index) {
          final depositId = chain.depositIds[index];
          final isLast = index == chain.depositIds.length - 1;
          final isFirst = index == 0;

          return Row(
            children: [
              _buildTimelineNode(
                  context, depositId, isFirst, isLast, index + 1),
              if (!isLast) _buildTimelineConnection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineNode(BuildContext context, String depositId,
      bool isFirst, bool isLast, int stepNumber) {
    Color nodeColor;
    IconData nodeIcon;
    String nodeLabel;

    if (isFirst) {
      nodeColor = Colors.blue;
      nodeIcon = Icons.account_balance;
      nodeLabel = 'Original';
    } else if (isLast) {
      nodeColor = Colors.green;
      nodeIcon = Icons.repeat;
      nodeLabel = 'Latest';
    } else {
      nodeColor = Colors.orange;
      nodeIcon = Icons.trending_up;
      nodeLabel = 'Step $stepNumber';
    }

    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: nodeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: nodeColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              nodeIcon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nodeLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: nodeColor,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Step $stepNumber',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnection() {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(top: 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[400]!],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildActionRequiredSection(
      BuildContext context, List<Deposit> requiringAction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Action Required (${requiringAction.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requiringAction.length,
          itemBuilder: (context, index) {
            return _buildMaturedDepositCard(context, requiringAction[index]);
          },
        ),
      ],
    );
  }

  Widget _buildProcessedSection(BuildContext context, List<Deposit> processed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Processed (${processed.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: processed.length,
          itemBuilder: (context, index) {
            return _buildProcessedDepositCard(context, processed[index]);
          },
        ),
      ],
    );
  }

  Widget _buildMaturedDepositCard(BuildContext context, Deposit deposit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _processMaturedDeposit(context, deposit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${deposit.bankName} - ${deposit.srNo}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${deposit.holdersDisplay} • ₹${deposit.dueAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ACTION REQUIRED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessedDepositCard(BuildContext context, Deposit deposit) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (deposit.isReinvested) {
      statusColor = Colors.green;
      statusIcon = Icons.repeat;
      statusText = 'REINVESTED';
    } else if (deposit.isWithdrawn) {
      statusColor = Colors.orange;
      statusIcon = Icons.account_balance_wallet;
      statusText = 'WITHDRAWN';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.check_circle;
      statusText = 'CLOSED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
            final isNarrow = w < 520;

            final leading = Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
            );

            final body = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${deposit.bankName} - ${deposit.srNo}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${deposit.holdersDisplay} • ₹${deposit.dueAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (deposit.notes != null && deposit.notes!.isNotEmpty)
                  Text(
                    'Note: ${deposit.notes}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            );

            final statusChip = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );

            final viewChain = TextButton.icon(
              onPressed: () => _openChainForDeposit(context, deposit),
              icon: const Icon(Icons.account_tree),
              label: const Text('View Chain'),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(child: body),
                      const SizedBox(width: 8),
                      statusChip,
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: viewChain,
                  ),
                ],
              );
            }

            return Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(child: body),
                const SizedBox(width: 8),
                statusChip,
                const SizedBox(width: 8),
                viewChain,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openChainForDeposit(
      BuildContext context, Deposit deposit) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    try {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      final container = ProviderScope.containerOf(context);
      final repo = container.read(lineageRepositoryProvider);
      final chain = await repo.getDepositChain(deposit.id);
      if (context.mounted) Navigator.of(context).pop();
      if (chain != null) {
        if (context.mounted) context.push('/chain/${chain.id}');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No chain found for this deposit')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Widget _buildEmptyMaturedWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule,
              size: 48,
              color: Colors.orange[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Matured Deposits',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All matured deposits have been processed',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  void _viewChainDetails(BuildContext context, DepositChain chain) {
    context.push('/chain/${chain.id}');
  }

  void _processMaturedDeposit(BuildContext context, Deposit deposit) {
    context.push('/deposit/matured/${deposit.id}');
  }

  Future<void> _testChainCreation(BuildContext context, WidgetRef ref) async {
    try {
      if (kDebugMode) debugPrint('Testing chain creation...');
      final lineageRepo = ref.read(lineageRepositoryProvider);

      // Create a test chain
      final chain = await lineageRepo.createChain(
        name: 'Test Chain ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Test chain created for debugging',
      );

      if (kDebugMode) {
        debugPrint('Test chain created: ${chain.name} (${chain.id})');
      }

      // Refresh the providers
      ref.invalidate(chainsWithDepositsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test chain created: ${chain.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error testing chain creation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            'Error Loading Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red[600],
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Re-run providers
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
