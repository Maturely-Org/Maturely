import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/deposit.dart';
import '../providers/deposit_providers.dart';
import '../providers/lineage_providers.dart';
import '../../../../core/utils/notification_service.dart';

class ReinvestSeed {
  final String previousDepositId;
  final String holderName;
  final String bankName;
  final String accountNumber;
  final double amountDeposited;
  final double? dueAmount;
  final DateTime dateDeposited;
  final DateTime dueDate;

  const ReinvestSeed({
    required this.previousDepositId,
    required this.holderName,
    required this.bankName,
    required this.accountNumber,
    required this.amountDeposited,
    this.dueAmount,
    required this.dateDeposited,
    required this.dueDate,
  });

  factory ReinvestSeed.fromDeposit(Deposit deposit) {
    final now = DateTime.now();
    final defaultDue = now.add(const Duration(days: 365));
    return ReinvestSeed(
      previousDepositId: deposit.id,
      holderName: deposit.holdersDisplay,
      bankName: deposit.bankName,
      accountNumber: deposit.accountNumber,
      amountDeposited: deposit.dueAmount,
      dueAmount: deposit.dueAmount,
      dateDeposited: now,
      dueDate: defaultDue,
    );
  }
}

class DepositFormPage extends ConsumerStatefulWidget {
  final String? depositId;
  final ReinvestSeed? reinvestSeed;

  const DepositFormPage({super.key, this.depositId, this.reinvestSeed});

  @override
  ConsumerState<DepositFormPage> createState() => _DepositFormPageState();
}

class _DepositFormPageState extends ConsumerState<DepositFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _srNoCtrl = TextEditingController();
  final List<TextEditingController> _holderCtrls = [TextEditingController()];
  final _bankCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _fdrCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dueAmountCtrl = TextEditingController();
  DateTime? _dateDeposited;
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _didPrefillFromQueryParams = false;

  @override
  void initState() {
    super.initState();
    if (widget.depositId != null) {
      _loadDeposit();
    } else {
      _getNextSrNo();
      if (widget.reinvestSeed != null) {
        _applyReinvestSeed();
      }
    }
  }

  Future<void> _getNextSrNo() async {
    try {
      final repo = ref.read(depositRepositoryProvider);
      final next = await repo.getNextSerialNumber();
      if (mounted && _srNoCtrl.text.isEmpty) {
        setState(() => _srNoCtrl.text = next);
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.depositId == null &&
        widget.reinvestSeed == null &&
        !_didPrefillFromQueryParams) {
      _loadFromQueryParams();
      _didPrefillFromQueryParams = true;
    }
  }

  void _applyReinvestSeed() {
    final seed = widget.reinvestSeed;
    if (seed == null) return;

    if (_holderCtrls.isNotEmpty && _holderCtrls[0].text.trim().isEmpty) {
      _holderCtrls[0].text = seed.holderName;
    }
    if (_bankCtrl.text.trim().isEmpty) {
      _bankCtrl.text = seed.bankName;
    }
    if (_accountCtrl.text.trim().isEmpty) {
      _accountCtrl.text = seed.accountNumber;
    }
    if (_amountCtrl.text.trim().isEmpty) {
      _amountCtrl.text = seed.amountDeposited.toStringAsFixed(2);
    }
    if (_dueAmountCtrl.text.trim().isEmpty && seed.dueAmount != null) {
      _dueAmountCtrl.text = seed.dueAmount!.toStringAsFixed(2);
    }
    _dateDeposited ??= seed.dateDeposited;
    _dueDate ??= seed.dueDate;
  }

  void _loadFromQueryParams() {
    try {
      final uri = GoRouterState.of(context).uri;
      if (uri.queryParameters.isNotEmpty) {
        if (_srNoCtrl.text.trim().isEmpty) {
          _srNoCtrl.text = uri.queryParameters['srNo'] ?? '';
        }
        if (_holderCtrls.isNotEmpty && _holderCtrls[0].text.trim().isEmpty) {
          _holderCtrls[0].text = uri.queryParameters['holderName'] ?? '';
        }
        if (_bankCtrl.text.trim().isEmpty) {
          _bankCtrl.text = uri.queryParameters['bankName'] ?? '';
        }
        if (_accountCtrl.text.trim().isEmpty) {
          _accountCtrl.text = uri.queryParameters['accountNumber'] ?? '';
        }
        if (_fdrCtrl.text.trim().isEmpty) {
          _fdrCtrl.text = uri.queryParameters['fdrNo'] ?? '';
        }
        if (_amountCtrl.text.trim().isEmpty) {
          _amountCtrl.text = uri.queryParameters['amountDeposited'] ?? '';
        }
        if (_dueAmountCtrl.text.trim().isEmpty) {
          _dueAmountCtrl.text = uri.queryParameters['dueAmount'] ?? '';
        }

        final dateDepositedMs =
            int.tryParse(uri.queryParameters['dateDeposited'] ?? '');
        if (dateDepositedMs != null && _dateDeposited == null) {
          _dateDeposited = DateTime.fromMillisecondsSinceEpoch(dateDepositedMs);
        }

        final dueDateMs = int.tryParse(uri.queryParameters['dueDate'] ?? '');
        if (dueDateMs != null && _dueDate == null) {
          _dueDate = DateTime.fromMillisecondsSinceEpoch(dueDateMs);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading query params: $e');
    }
  }

  void _addHolder() {
    if (_holderCtrls.length < 2) {
      setState(() {
        _holderCtrls.add(TextEditingController());
      });
    }
  }

  void _removeHolder(int index) {
    if (_holderCtrls.length > 1 && index < _holderCtrls.length) {
      setState(() {
        _holderCtrls[index].dispose();
        _holderCtrls.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _srNoCtrl.dispose();
    for (final ctrl in _holderCtrls) {
      ctrl.dispose();
    }
    _bankCtrl.dispose();
    _accountCtrl.dispose();
    _fdrCtrl.dispose();
    _amountCtrl.dispose();
    _dueAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDeposit() async {
    if (widget.depositId == null) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(depositRepositoryProvider);
      final deposit = await repo.getDepositById(widget.depositId!);
      if (deposit != null && mounted) {
        _srNoCtrl.text = deposit.srNo;
        _holderCtrls.clear();
        for (int i = 0; i < deposit.holders.length; i++) {
          _holderCtrls.add(TextEditingController(text: deposit.holders[i]));
        }
        if (_holderCtrls.isEmpty) {
          _holderCtrls.add(TextEditingController());
        }
        _bankCtrl.text = deposit.bankName;
        _accountCtrl.text = deposit.accountNumber;
        _fdrCtrl.text = deposit.fdrNo;
        _amountCtrl.text = deposit.amountDeposited.toString();
        _dueAmountCtrl.text = deposit.dueAmount.toString();
        _dateDeposited = deposit.dateDeposited;
        _dueDate = deposit.dueDate;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load deposit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deposit'),
        content: const Text('Are you sure you want to delete this deposit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final repo = ref.read(depositRepositoryProvider);
        await repo.deleteDeposit(widget.depositId!);
        ref.invalidate(depositsListProvider);
        ref.invalidate(chainsWithDepositsProvider);
        ref.invalidate(orphanedDepositsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deposit deleted successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateDeposited == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(depositRepositoryProvider);
      final lineageRepo = ref.read(lineageRepositoryProvider);

      String? previousDepositId = widget.reinvestSeed?.previousDepositId;
      try {
        final uri = GoRouterState.of(context).uri;
        previousDepositId ??= uri.queryParameters['previousDepositId'];
      } catch (_) {}

      final newId = widget.depositId ?? const Uuid().v4();
      final now = DateTime.now();

      final deposit = Deposit(
        id: newId,
        srNo: _srNoCtrl.text.trim(),
        holders: _holderCtrls
            .map((ctrl) => ctrl.text.trim())
            .where((h) => h.isNotEmpty)
            .toList(),
        bankName: _bankCtrl.text.trim(),
        accountNumber: _accountCtrl.text.trim(),
        fdrNo: _fdrCtrl.text.trim(),
        amountDeposited: double.parse(_amountCtrl.text.trim()),
        dueAmount: double.parse(_dueAmountCtrl.text.trim()),
        dateDeposited: _dateDeposited!,
        dueDate: _dueDate!,
        status: DepositStatus.active,
        previousDepositId: previousDepositId,
        createdAt: now,
        updatedAt: now,
        notes: null,
        attachments: const [],
      );

      final issues = deposit.validate();
      if (issues.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(issues.join('\n'))),
        );
        setState(() => _isLoading = false);
        return;
      }

      final saved = widget.depositId != null 
          ? await repo.updateDeposit(deposit)
          : await repo.createDeposit(deposit);

      await NotificationService.scheduleForDeposit(saved);

      if (previousDepositId != null && widget.depositId == null) {
        // Handle Reinvestment automatically via LineageRepository
        var chain = await lineageRepo.getDepositChain(previousDepositId);
        if (chain == null) {
          chain = await lineageRepo.createChain(
            name: '${saved.bankName} Chain',
            description: 'Automatic chain from reinvestment',
          );
          await lineageRepo.addDepositToChain(chain.id, previousDepositId);
        }
        
        await lineageRepo.addDepositToChain(chain.id, saved.id);
        await lineageRepo.linkDeposits(
          parentDepositId: previousDepositId,
          childDepositId: saved.id,
          reinvestedAmount: saved.amountDeposited,
          notes: 'Reinvestment from matured deposit',
        );
      }

      ref.invalidate(depositsListProvider);
      ref.invalidate(chainsWithDepositsProvider);
      ref.invalidate(orphanedDepositsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.depositId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Deposit' : 'New Deposit'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _delete,
              tooltip: 'Delete Deposit',
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                   _buildTextField(_srNoCtrl, 'Sr No', TextInputType.number),
                   const SizedBox(height: 12),
                   _buildHoldersSection(),
                   const SizedBox(height: 12),
                   _buildTextField(_bankCtrl, 'Bank Name / PPF'),
                   const SizedBox(height: 12),
                   _buildTextField(_accountCtrl, 'Account Number'),
                   const SizedBox(height: 12),
                   _buildTextField(_fdrCtrl, 'FDR No'),
                   const SizedBox(height: 12),
                   _buildTextField(_amountCtrl, 'Amount Deposited', TextInputType.number),
                   const SizedBox(height: 12),
                   _buildTextField(_dueAmountCtrl, 'Due Amount', TextInputType.number),
                   const SizedBox(height: 12),
                   _DatePickerTile(
                     label: 'Date Deposited',
                     date: _dateDeposited,
                     onPick: (d) => setState(() => _dateDeposited = d),
                   ),
                   const SizedBox(height: 12),
                   _DatePickerTile(
                     label: 'Due Date',
                     date: _dueDate,
                     onPick: (d) => setState(() => _dueDate = d),
                   ),
                   const SizedBox(height: 32),
                   ElevatedButton.icon(
                     onPressed: _save,
                     icon: const Icon(Icons.save),
                     label: Text(isEditing ? 'Update Deposit' : 'Save Deposit'),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       backgroundColor: Colors.green[700],
                       foregroundColor: Colors.white,
                     ),
                   ),
                   const SizedBox(height: 80),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, [TextInputType? type]) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: type,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildHoldersSection() {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Holders', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_holderCtrls.length < 2)
                  TextButton.icon(
                    onPressed: _addHolder,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
              ],
            ),
            ...List.generate(_holderCtrls.length, (i) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _holderCtrls[i],
                      decoration: InputDecoration(
                        labelText: i == 0 ? 'Primary' : 'Secondary',
                        isDense: true,
                      ),
                      validator: (v) => (i == 0 && (v == null || v.trim().isEmpty)) ? 'Required' : null,
                    ),
                  ),
                  if (_holderCtrls.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _removeHolder(i),
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  const _DatePickerTile({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final text = date == null ? 'Select Date' : '${date!.day}/${date!.month}/${date!.year}';
    return ListTile(
      title: Text(label),
      subtitle: Text(text),
      trailing: const Icon(Icons.calendar_today),
      tileColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d != null) onPick(d);
      },
    );
  }
}
