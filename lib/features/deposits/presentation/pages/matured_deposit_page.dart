import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/deposit.dart';
import '../providers/deposit_providers.dart';
import '../providers/lineage_providers.dart';
import 'deposit_form_page.dart';

class MaturedDepositPage extends ConsumerStatefulWidget {
  final String depositId;

  const MaturedDepositPage({
    super.key,
    required this.depositId,
  });

  @override
  ConsumerState<MaturedDepositPage> createState() => _MaturedDepositPageState();
}

class _MaturedDepositPageState extends ConsumerState<MaturedDepositPage> {
  Deposit? _deposit;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeposit();
  }

  Future<void> _loadDeposit() async {
    try {
      final repo = ref.read(depositRepositoryProvider);
      final deposit = await repo.getDepositById(widget.depositId);
      if (mounted) {
        setState(() {
          _deposit = deposit;
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

    if (_deposit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(
          child: Text('Deposit not found'),
        ),
      );
    }

    // Check if deposit has already been processed
    if (!_deposit!.requiresAction) {
      return _buildProcessedView();
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Matured Deposit'),
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DepositFormPage(depositId: _deposit!.id),
                    ),
                  );
                },
                tooltip: 'Edit Deposit',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Information Section
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  
                  Text(
                    'What would you like to do?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The maturity amount is ready. Choose an action to close this deposit.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  _buildActionCard(
                    title: 'Reinvest Matured Amount',
                    subtitle: 'Create a new deposit and link it to this one',
                    icon: Icons.repeat_rounded,
                    color: Colors.green,
                    onTap: _showReinvestDialog,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    title: 'Mark as Withdrawn',
                    subtitle: 'Funds have been credited to savings account',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.blue,
                    onTap: _showWithdrawDialog,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    title: 'Other Closure',
                    subtitle: 'Close for any other reason',
                    icon: Icons.close_rounded,
                    color: Colors.grey,
                    onTap: _showOtherDialog,
                  ),

                  if (_deposit!.isPartOfChain) ...[
                    const SizedBox(height: 32),
                    _buildLineageSummary(),
                  ],
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedView() {
    final statusColor = _deposit!.closureType == ClosureType.reinvested
        ? Colors.green
        : (_deposit!.closureType == ClosureType.withdrawn ? Colors.blue : Colors.grey);
    
    final icon = _deposit!.closureType == ClosureType.reinvested
        ? Icons.repeat
        : (_deposit!.closureType == ClosureType.withdrawn ? Icons.account_balance_wallet : Icons.check_circle);

    return Scaffold(
      appBar: AppBar(title: const Text('Processed Deposit')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: statusColor),
            ),
            const SizedBox(height: 24),
            Text(
              _deposit!.closureType == ClosureType.reinvested
                  ? 'Reinvested'
                  : (_deposit!.closureType == ClosureType.withdrawn ? 'Withdrawn' : 'Closed'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'This deposit was processed on\n${_formatDate(_deposit!.updatedAt)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _deposit!.bankName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sr No: ${_deposit!.srNo}',
                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MATURED',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(),
            ),
            _buildInfoRow('Holders', _deposit!.holdersDisplay),
            _buildInfoRow('Account info', '${_deposit!.accountNumber} / ${_deposit!.fdrNo}'),
            _buildInfoRow('Amount Deposited', '₹${_deposit!.amountDeposited.toStringAsFixed(2)}'),
            _buildInfoRow('Maturity Amount', '₹${_deposit!.dueAmount.toStringAsFixed(2)}', isBold: true),
            _buildInfoRow('Maturity Date', _formatDate(_deposit!.dueDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blueGrey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLineageSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 20),
              const SizedBox(width: 8),
              Text('Chain Lineage', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This deposit is part of a series. Actions here will affect the chain statistics.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  void _showReinvestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reinvest Amount'),
        content: const Text('This will create a new deposit form pre-filled with the maturity amount. This deposit will be marked as "Reinvested".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleReinvest();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: const Text('Are you sure the funds have been withdrawn and confirmed? This will close the deposit.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleWithdraw();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showOtherDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Deposit'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(hintText: 'Reason for closure (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleOther(noteController.text.trim());
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleReinvest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DepositFormPage(
          reinvestSeed: ReinvestSeed.fromDeposit(_deposit!),
        ),
      ),
    );
  }

  Future<void> _handleWithdraw() async {
    try {
      final updatedDeposit = _deposit!.close(ClosureType.withdrawn);
      final repo = ref.read(depositRepositoryProvider);
      await repo.updateDeposit(updatedDeposit);

      ref.invalidate(depositsListProvider);
      ref.invalidate(chainsWithDepositsProvider);
      ref.invalidate(orphanedDepositsProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleOther(String notes) async {
    try {
      final updatedDeposit = _deposit!.close(ClosureType.unknown, notes: notes);
      final repo = ref.read(depositRepositoryProvider);
      await repo.updateDeposit(updatedDeposit);

      ref.invalidate(depositsListProvider);
      ref.invalidate(chainsWithDepositsProvider);
      ref.invalidate(orphanedDepositsProvider);

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
