import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/deposit_providers.dart';

class DepositSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef ref;

  DepositSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search by Sr No, Bank Name, or Holder'));
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final depositsAsync = ref.watch(depositsListProvider);

    return depositsAsync.when(
      data: (items) {
        final results = items.where((d) {
          final q = query.toLowerCase();
          return d.srNo.toLowerCase().contains(q) ||
              d.bankName.toLowerCase().contains(q) ||
              d.holdersDisplay.toLowerCase().contains(q) ||
              d.accountNumber.toLowerCase().contains(q) ||
              d.fdrNo.toLowerCase().contains(q);
        }).toList();

        if (results.isEmpty) {
          return const Center(child: Text('No matches found'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final d = results[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: d.isMatured ? Colors.blue : Colors.green,
                child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
              ),
              title: Text('${d.srNo} • ${d.bankName}'),
              subtitle: Text(d.holdersDisplay),
              trailing: Text('₹${d.amountDeposited.toStringAsFixed(0)}'),
              onTap: () {
                close(context, d.id);
                if (d.requiresAction) {
                  context.push('/deposit/matured/${d.id}');
                } else {
                  context.push('/deposit/${d.id}');
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
