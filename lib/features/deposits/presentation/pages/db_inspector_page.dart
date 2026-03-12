import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/utils/hive_bootstrap.dart';
import '../../data/models/deposit_hive_model.dart';
import '../../data/models/deposit_chain_hive_model.dart';
import '../providers/deposit_providers.dart';
import '../providers/lineage_providers.dart';

class DbInspectorPage extends ConsumerStatefulWidget {
  const DbInspectorPage({super.key});

  @override
  ConsumerState<DbInspectorPage> createState() => _DbInspectorPageState();
}

class _DbInspectorPageState extends ConsumerState<DbInspectorPage> {
  Box<DepositHiveModel>? _box;
  List<DepositHiveModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      _box = Hive.box<DepositHiveModel>(HiveBootstrap.depositsBoxName);
      _items = _box!.values.toList();
      setState(() {});
    } catch (e) {
       debugPrint('Error loading DB: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Database Inspector'),
            backgroundColor: Colors.blueGrey[900],
            foregroundColor: Colors.white,
            actions: [
              IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
              _buildClearButton(),
            ],
          ),
          
          if (_items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No records found')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _items[index];
                    return _InspectorItem(item: item);
                  },
                  childCount: _items.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return IconButton(
      icon: const Icon(Icons.delete_forever),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Purge Database?'),
            content: const Text('This will delete all deposits and lineage data permanently.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Nuke Everything'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final chainsBox = Hive.box<DepositChainHiveModel>(HiveBootstrap.chainsBoxName);
          final linksBox = Hive.box<ChainLinkHiveModel>(HiveBootstrap.linksBoxName);
          
          await Future.wait([
            _box!.clear(),
            chainsBox.clear(),
            linksBox.clear(),
          ]);

          ref.invalidate(depositsListProvider);
          ref.invalidate(chainsWithDepositsProvider);
          ref.invalidate(orphanedDepositsProvider);
          _loadData();
        }
      },
    );
  }
}

class _InspectorItem extends StatelessWidget {
  final DepositHiveModel item;
  const _InspectorItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        subtitle: Text('${item.bankName} • ₹${item.amountDeposited}', style: TextStyle(color: Colors.grey[600])),
        title: Text('${item.srNo} • ${item.holders.join(", ")}', style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KvRow('ID', item.id),
                _KvRow('Status', item.status),
                _KvRow('Closure', item.closureType ?? 'None'),
                _KvRow('Prev ID', item.previousDepositId ?? 'None'),
                _KvRow('Next ID', item.nextDepositId ?? 'None'),
                _KvRow('Chain ID', item.chainId ?? 'None'),
                _KvRow('Created', item.createdAt.toIso8601String()),
                _KvRow('Updated', item.updatedAt.toIso8601String()),
                if (item.notes != null) _KvRow('Notes', item.notes!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  final String k;
  final String v;
  const _KvRow(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
          Expanded(child: Text(v, style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
        ],
      ),
    );
  }
}
