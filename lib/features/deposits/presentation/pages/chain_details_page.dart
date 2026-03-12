import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/deposit_chain.dart';
import '../../domain/entities/deposit.dart';
import '../providers/lineage_providers.dart';
import '../providers/deposit_providers.dart';
import 'deposit_form_page.dart';

class ChainDetailsPage extends ConsumerStatefulWidget {
  final String chainId;

  const ChainDetailsPage({
    super.key,
    required this.chainId,
  });

  @override
  ConsumerState<ChainDetailsPage> createState() => _ChainDetailsPageState();
}

class _ChainDetailsPageState extends ConsumerState<ChainDetailsPage> {
  DepositChain? _chain;
  List<Deposit> _deposits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChainData();
  }

  Future<void> _loadChainData() async {
    try {
      final lineageRepo = ref.read(lineageRepositoryProvider);

      final chain = await lineageRepo.getChain(widget.chainId);
      List<Deposit> deposits = [];
      if (chain != null && chain.depositIds.isNotEmpty) {
        deposits = await lineageRepo.getDepositLineage(chain.depositIds.first);
      }

      if (mounted) {
        setState(() {
          _chain = chain;
          _deposits = deposits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chain == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(
          child: Text('Chain not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_chain!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditChainDialog(),
            tooltip: 'Edit Chain',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Chain'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteChainDialog();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChainData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chain Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    _chain!.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _chain!.name,
                                        style: Theme.of(context).textTheme.titleLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_chain!.description != null)
                                        Text(
                                          _chain!.description!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_chain!.status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _chain!.status.name.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(_chain!.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Total Deposits',
                                    _chain!.totalDeposits.toString(),
                                    Icons.account_balance,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'Current Value',
                                    '₹${_chain!.currentValue.toStringAsFixed(0)}',
                                    Icons.attach_money,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Deposits Section Header
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w =
                            constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
                        final isNarrow = w < 520;

                        final title = Text(
                          'Deposits in Chain (${_deposits.length})',
                          style: Theme.of(context).textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        );

                        final actions = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showAddDepositDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Deposit'),
                            ),
                            if (_deposits.isNotEmpty)
                              TextButton.icon(
                                onPressed: _reinvestLatest,
                                icon: const Icon(Icons.trending_up),
                                label: const Text('Reinvest latest'),
                              ),
                          ],
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: actions,
                              ),
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: title),
                            const SizedBox(width: 12),
                            actions,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            if (_deposits.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Deposits in Chain',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add deposits to this chain to track their lineage',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final deposit = _deposits[index];
                      return _DepositCard(
                        deposit: deposit,
                        onTap: () => _navigateToDeposit(deposit),
                        onRemove: () => _showRemoveDepositDialog(deposit),
                      );
                    },
                    childCount: _deposits.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ChainStatus status) {
    switch (status) {
      case ChainStatus.active:
        return Colors.green;
      case ChainStatus.closed:
        return Colors.red;
      case ChainStatus.archived:
        return Colors.grey;
    }
  }

  void _reinvestLatest() {
    if (_deposits.isEmpty) return;
    final latest = _deposits.last;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DepositFormPage(
          reinvestSeed: ReinvestSeed.fromDeposit(latest),
        ),
      ),
    );
  }

  void _showEditChainDialog() {
    final nameController = TextEditingController(text: _chain!.name);
    final descriptionController =
        TextEditingController(text: _chain!.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Chain'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Chain Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedChain = _chain!.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                );
                ref.read(chainOperationsProvider.notifier).updateChain(updatedChain).then((_) {
                  _loadChainData();
                  if (context.mounted) Navigator.of(context).pop();
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChainDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chain'),
        content: Text(
          'Are you sure you want to delete the chain "${_chain!.name}"? This will not delete the deposits, but will remove the chain structure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chainOperationsProvider.notifier).deleteChain(widget.chainId).then((_) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // pop dialog
                  context.pop(); // pop page using go_router
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddDepositDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Deposit to Chain'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (context, ref, child) {
              final orphansAsync = ref.watch(orphanedDepositsProvider);
              return orphansAsync.when(
                data: (deposits) {
                  if (deposits.isEmpty) return const Text('No available deposits to add.');
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: deposits.length,
                    itemBuilder: (context, index) {
                      final deposit = deposits[index];
                      return ListTile(
                        title: Text('${deposit.bankName} - ${deposit.srNo}'),
                        subtitle: Text('₹${deposit.amountDeposited.toStringAsFixed(0)}'),
                        onTap: () async {
                          await ref.read(chainOperationsProvider.notifier).addDepositToChain(widget.chainId, deposit.id);
                          final depositRepo = ref.read(depositRepositoryProvider);
                          final d = await depositRepo.getDepositById(deposit.id);
                          if (d != null) {
                            await depositRepo.updateDeposit(d.copyWith(chainId: widget.chainId));
                          }
                          _loadChainData();
                          ref.invalidate(orphanedDepositsProvider);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToDeposit(Deposit deposit) {
    if (deposit.isMatured) {
      context.push('/deposit/matured/${deposit.id}');
    } else {
      context.push('/deposit/edit/${deposit.id}');
    }
  }

  void _showRemoveDepositDialog(Deposit deposit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Chain'),
        content: Text(
          'Are you sure you want to remove deposit ${deposit.srNo} from this chain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chainOperationsProvider.notifier)
                 .removeDepositFromChain(widget.chainId, deposit.id)
                 .then((_) async {
                   final depositRepo = ref.read(depositRepositoryProvider);
                   final d = await depositRepo.getDepositById(deposit.id);
                   if (d != null) {
                     await depositRepo.updateDeposit(d.copyWith(chainId: null));
                   }
                   _loadChainData();
                   ref.invalidate(orphanedDepositsProvider);
                   if (context.mounted) Navigator.of(context).pop();
                 });
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _DepositCard extends StatelessWidget {
  final Deposit deposit;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _DepositCard({
    required this.deposit,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: deposit.isMatured
              ? Colors.blue
              : (deposit.isDueSoon(3) ? Colors.orange : Colors.green),
          child: Icon(
            deposit.isMatured
                ? Icons.check_circle
                : (deposit.isDueSoon(3)
                    ? Icons.schedule
                    : Icons.account_balance),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text('${deposit.srNo} • ${deposit.bankName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${deposit.holdersDisplay} • ₹${deposit.dueAmount.toStringAsFixed(0)}'),
            Text(
              'Due: ${deposit.dueDate.day.toString().padLeft(2, '0')}-'
              '${deposit.dueDate.month.toString().padLeft(2, '0')}-${deposit.dueDate.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deposit.isMatured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ACTION REQUIRED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from Chain'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
