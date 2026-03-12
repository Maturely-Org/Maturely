import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/deposit.dart';
import '../providers/deposit_providers.dart';
import 'deposit_form_page.dart';
import 'matured_deposit_page.dart';

class DepositDetailsPage extends ConsumerStatefulWidget {
  final String depositId;

  const DepositDetailsPage({super.key, required this.depositId});

  @override
  ConsumerState<DepositDetailsPage> createState() => _DepositDetailsPageState();
}

class _DepositDetailsPageState extends ConsumerState<DepositDetailsPage> {
  Deposit? _deposit;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(depositRepositoryProvider);
      final d = await repo.getDepositById(widget.depositId);
      if (!mounted) return;
      setState(() {
        _deposit = d;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        appBar: AppBar(title: const Text('Deposit Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Failed to load deposit',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = _deposit;
    if (d == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deposit Details')),
        body: const Center(child: Text('Deposit not found')),
      );
    }

    final statusText = d.isMatured ? 'MATURED' : d.status.name.toUpperCase();
    final statusColor = d.isMatured
        ? Colors.blue
        : (d.status == DepositStatus.active ? Colors.green : Colors.grey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _safePush(
                context,
                '/deposit/edit/${d.id}',
                DepositFormPage(depositId: d.id),
              );
            },
            tooltip: 'Edit',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: statusColor,
                          child: const Icon(Icons.account_balance,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${d.srNo} • ${d.bankName}',
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                d.holdersDisplay,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[700]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusText,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow(context, 'Account Number', d.accountNumber),
                    _infoRow(context, 'FDR Number', d.fdrNo),
                    _infoRow(
                        context,
                        'Amount Deposited',
                        '₹${d.amountDeposited.toStringAsFixed(2)}'),
                    _infoRow(context, 'Due Amount',
                        '₹${d.dueAmount.toStringAsFixed(2)}'),
                    _infoRow(context, 'Date Deposited', _formatDate(d.dateDeposited)),
                    _infoRow(context, 'Due Date', _formatDate(d.dueDate)),
                    if (d.notes != null && d.notes!.trim().isNotEmpty)
                      _infoRow(context, 'Notes', d.notes!.trim()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 400.0;
                final isNarrow = w < 460;

                final actions = <Widget>[
                  ElevatedButton.icon(
                    onPressed: () => context.push('/deposit/edit/${d.id}'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  if (d.requiresAction)
                    OutlinedButton.icon(
                      onPressed: () => _safePush(
                        context,
                        '/deposit/matured/${d.id}',
                        MaturedDepositPage(depositId: d.id),
                      ),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Process matured'),
                    ),
                ];

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final a in actions) ...[
                        a,
                        const SizedBox(height: 8),
                      ]
                    ]..removeLast(),
                  );
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: actions,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _safePush(BuildContext context, String location, Widget fallbackPage) {
    try {
      context.push(location);
    } catch (_) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => fallbackPage),
      );
    }
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}
