import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/deposit.dart';
import '../../domain/entities/deposit_chain.dart';
import '../../domain/repositories/lineage_repository.dart';
import '../models/deposit_hive_model.dart';
import '../models/deposit_chain_hive_model.dart';
import '../../../../core/utils/hive_bootstrap.dart';

class HiveLineageRepository implements LineageRepository {
  final Uuid _uuid = const Uuid();

  Box<DepositChainHiveModel> get _chainsBox {
    return Hive.box<DepositChainHiveModel>(HiveBootstrap.chainsBoxName);
  }

  Box<DepositHiveModel> get _depositsBox {
    return Hive.box<DepositHiveModel>(HiveBootstrap.depositsBoxName);
  }

  @override
  Future<DepositChain> createChain({
    required String name,
    String? description,
  }) async {
    final chainId = _uuid.v4();
    final now = DateTime.now();

    final chain = DepositChainHiveModel(
      id: chainId,
      name: name,
      createdAt: now,
      updatedAt: now,
      description: description,
      depositIds: [],
      totalDeposits: 0,
      totalAmount: 0.0,
      currentValue: 0.0,
      status: ChainStatus.active.index,
    );

    await _chainsBox.put(chainId, chain);
    return _toDomainChain(chain);
  }

  @override
  Future<List<DepositChain>> getAllChains() async {
    return _chainsBox.values.map(_toDomainChain).toList();
  }

  @override
  Future<DepositChain?> getChain(String chainId) async {
    final chain = _chainsBox.get(chainId);
    return chain != null ? _toDomainChain(chain) : null;
  }

  @override
  Future<DepositChain> updateChain(DepositChain chain) async {
    final hiveChain = _toHiveChain(chain);
    await _chainsBox.put(chain.id, hiveChain);
    return chain;
  }

  @override
  Future<void> deleteChain(String chainId) async {
    // Clear chainId from all deposits first
    final chain = _chainsBox.get(chainId);
    if (chain != null) {
      for (final depositId in chain.depositIds) {
        final d = _depositsBox.get(depositId);
        if (d != null) {
          await _depositsBox.put(depositId, d.copyWith(chainId: null));
        }
      }
    }
    await _chainsBox.delete(chainId);
  }

  @override
  Future<ChainLink> linkDeposits({
    required String parentDepositId,
    required String childDepositId,
    required double reinvestedAmount,
    String? notes,
  }) async {
    // We use the Deposit object fields as the source of truth now
    final parent = _depositsBox.get(parentDepositId);
    final child = _depositsBox.get(childDepositId);

    if (parent != null && child != null) {
      final updatedParent = parent.copyWith(
        nextDepositId: childDepositId,
        closureType: 'reinvested', // Domain value
        status: 'closed',
      );
      final updatedChild = child.copyWith(
        previousDepositId: parentDepositId,
        chainId: parent.chainId ?? parent.id, // Inheritance
      );
      await _depositsBox.put(parentDepositId, updatedParent);
      await _depositsBox.put(childDepositId, updatedChild);
      
      if (updatedChild.chainId != null) {
        await _updateChainStatistics(updatedChild.chainId!);
      }
    }

    return ChainLink(
      parentDepositId: parentDepositId,
      childDepositId: childDepositId,
      linkedAt: DateTime.now(),
      reinvestedAmount: reinvestedAmount,
      notes: notes,
    );
  }

  @override
  Future<void> unlinkDeposits(String parentDepositId, String childDepositId) async {
    final parent = _depositsBox.get(parentDepositId);
    final child = _depositsBox.get(childDepositId);

    if (parent != null) {
      await _depositsBox.put(parentDepositId, parent.copyWith(nextDepositId: null));
    }
    if (child != null) {
      await _depositsBox.put(childDepositId, child.copyWith(previousDepositId: null));
    }
  }

  @override
  Future<List<ChainLink>> getDepositLinks(String depositId) async {
    // Return mock links derived from sequence fields
    final links = <ChainLink>[];
    final d = _depositsBox.get(depositId);
    if (d == null) return links;

    if (d.previousDepositId != null) {
      links.add(ChainLink(
        parentDepositId: d.previousDepositId!,
        childDepositId: depositId,
        linkedAt: d.createdAt,
        reinvestedAmount: d.amountDeposited,
      ));
    }
    if (d.nextDepositId != null) {
      final child = _depositsBox.get(d.nextDepositId!);
      if (child != null) {
        links.add(ChainLink(
          parentDepositId: depositId,
          childDepositId: d.nextDepositId!,
          linkedAt: child.createdAt,
          reinvestedAmount: child.amountDeposited,
        ));
      }
    }
    return links;
  }

  @override
  Future<DepositChain?> getDepositChain(String depositId) async {
    final deposit = _depositsBox.get(depositId);
    if (deposit != null && deposit.chainId != null) {
      final chain = _chainsBox.get(deposit.chainId);
      if (chain != null) return _toDomainChain(chain);
    }
    return null;
  }

  @override
  Future<List<Deposit>> getDepositLineage(String depositId) async {
    final lineage = <Deposit>[];
    final visited = <String>{};
    
    // Find the head of the chain
    String? currentId = depositId;
    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);
      final d = _depositsBox.get(currentId);
      if (d == null || d.previousDepositId == null) break;
      currentId = d.previousDepositId;
    }
    
    // Follow the chain down
    visited.clear();
    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);
      final d = _depositsBox.get(currentId);
      if (d == null) break;
      lineage.add(_toDomainDeposit(d));
      currentId = d.nextDepositId;
    }
    
    return lineage;
  }

  @override
  Future<Map<String, dynamic>> getChainStatistics(String chainId) async {
    final chain = _chainsBox.get(chainId);
    if (chain == null) return {};

    final deposits = chain.depositIds
        .map((id) => _depositsBox.get(id))
        .where((deposit) => deposit != null)
        .cast<DepositHiveModel>()
        .toList();

    final totalAmount = deposits.fold(0.0, (sum, d) => sum + d.amountDeposited);
    final currentValue = deposits.fold(0.0, (sum, d) => sum + d.dueAmount);

    return {
      'totalDeposits': deposits.length,
      'totalAmount': totalAmount,
      'currentValue': currentValue,
      'activeDeposits': deposits.where((d) => d.status == 'active').length,
      'maturedDeposits': deposits.where((d) => d.status == 'matured').length,
    };
  }

  @override
  Future<List<DepositChain>> getChainsWithDeposits() async {
    return _chainsBox.values.map(_toDomainChain).toList();
  }

  @override
  Future<DepositChain> addDepositToChain(String chainId, String depositId) async {
    final chain = _chainsBox.get(chainId);
    final deposit = _depositsBox.get(depositId);
    if (chain == null || deposit == null) throw Exception('Not found');

    final ids = List<String>.from(chain.depositIds);
    if (!ids.contains(depositId)) ids.add(depositId);

    await _chainsBox.put(chainId, chain.copyWith(depositIds: ids));
    await _depositsBox.put(depositId, deposit.copyWith(chainId: chainId));
    await _updateChainStatistics(chainId);

    return _toDomainChain(_chainsBox.get(chainId)!);
  }

  @override
  Future<DepositChain> removeDepositFromChain(String chainId, String depositId) async {
    final chain = _chainsBox.get(chainId);
    if (chain == null) throw Exception('Chain not found');

    final ids = List<String>.from(chain.depositIds);
    ids.remove(depositId);

    await _chainsBox.put(chainId, chain.copyWith(depositIds: ids));
    final deposit = _depositsBox.get(depositId);
    if (deposit != null) {
      await _depositsBox.put(depositId, deposit.copyWith(chainId: null));
    }
    await _updateChainStatistics(chainId);

    return _toDomainChain(_chainsBox.get(chainId)!);
  }

  @override
  Future<List<Deposit>> getOrphanedDeposits() async {
    return _depositsBox.values
        .where((d) => d.chainId == null)
        .map(_toDomainDeposit)
        .toList();
  }

  @override
  Future<DepositChain> mergeChains(String sourceId, String targetId) async {
    final s = _chainsBox.get(sourceId);
    final t = _chainsBox.get(targetId);
    if (s == null || t == null) throw Exception('Not found');

    final mergedIds = (List<String>.from(t.depositIds)..addAll(s.depositIds)).toSet().toList();
    
    for (final id in s.depositIds) {
      final d = _depositsBox.get(id);
      if (d != null) await _depositsBox.put(id, d.copyWith(chainId: targetId));
    }

    await _chainsBox.put(targetId, t.copyWith(depositIds: mergedIds));
    await _chainsBox.delete(sourceId);
    await _updateChainStatistics(targetId);

    return _toDomainChain(_chainsBox.get(targetId)!);
  }

  @override
  Future<List<DepositChain>> splitChain(String chainId, String splitAtId) async {
    final chain = _chainsBox.get(chainId);
    if (chain == null) throw Exception('Not found');

    final index = chain.depositIds.indexOf(splitAtId);
    if (index == -1) throw Exception('Id not in chain');

    final ids1 = chain.depositIds.sublist(0, index + 1);
    final ids2 = chain.depositIds.sublist(index + 1);

    final chain2Id = _uuid.v4();
    final chain2 = DepositChainHiveModel(
      id: chain2Id,
      name: '${chain.name} (Split)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      depositIds: ids2,
      totalDeposits: ids2.length,
      totalAmount: 0.0,
      currentValue: 0.0,
      status: ChainStatus.active.index,
    );

    await _chainsBox.put(chainId, chain.copyWith(depositIds: ids1));
    await _chainsBox.put(chain2Id, chain2);

    for (final id in ids2) {
      final d = _depositsBox.get(id);
      if (d != null) await _depositsBox.put(id, d.copyWith(chainId: chain2Id));
    }

    await _updateChainStatistics(chainId);
    await _updateChainStatistics(chain2Id);

    return [_toDomainChain(chain), _toDomainChain(chain2)];
  }

  Future<void> _updateChainStatistics(String chainId) async {
    final chain = _chainsBox.get(chainId);
    if (chain == null) return;

    final deposits = chain.depositIds
        .map((id) => _depositsBox.get(id))
        .where((d) => d != null)
        .cast<DepositHiveModel>();

    final total = deposits.fold(0.0, (s, d) => s + d.amountDeposited);
    final current = deposits.fold(0.0, (s, d) => s + d.dueAmount);

    await _chainsBox.put(chainId, chain.copyWith(
      totalDeposits: deposits.length,
      totalAmount: total,
      currentValue: current,
      updatedAt: DateTime.now(),
    ));
  }

  DepositChain _toDomainChain(DepositChainHiveModel h) => DepositChain(
        id: h.id,
        name: h.name,
        createdAt: h.createdAt,
        updatedAt: h.updatedAt,
        description: h.description,
        depositIds: List.from(h.depositIds),
        totalDeposits: h.totalDeposits,
        totalAmount: h.totalAmount,
        currentValue: h.currentValue,
        status: ChainStatus.values[h.status],
      );

  DepositChainHiveModel _toHiveChain(DepositChain d) => DepositChainHiveModel(
        id: d.id,
        name: d.name,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        description: d.description,
        depositIds: List.from(d.depositIds),
        totalDeposits: d.totalDeposits,
        totalAmount: d.totalAmount,
        currentValue: d.currentValue,
        status: d.status.index,
      );

  Deposit _toDomainDeposit(DepositHiveModel h) => Deposit(
        id: h.id,
        srNo: h.srNo,
        holders: h.holders,
        bankName: h.bankName,
        accountNumber: h.accountNumber,
        fdrNo: h.fdrNo,
        amountDeposited: h.amountDeposited,
        dueAmount: h.dueAmount,
        dateDeposited: h.dateDeposited,
        dueDate: h.dueDate,
        status: DepositStatus.values.firstWhere((e) => e.name == h.status, orElse: () => DepositStatus.active),
        closureType: h.closureType == null ? null : ClosureType.values.firstWhere((e) => e.name == h.closureType, orElse: () => ClosureType.unknown),
        previousDepositId: h.previousDepositId,
        nextDepositId: h.nextDepositId,
        chainId: h.chainId,
        createdAt: h.createdAt,
        updatedAt: h.updatedAt,
        notes: h.notes,
        attachments: h.attachments.map((a) => Attachment(id: a.id, storagePath: a.storagePath, kind: AttachmentKind.values.firstWhere((e) => e.name == a.kind, orElse: () => AttachmentKind.other))).toList(),
      );
}
