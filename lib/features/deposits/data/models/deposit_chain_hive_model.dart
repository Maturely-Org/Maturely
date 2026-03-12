import 'package:hive/hive.dart';

part 'deposit_chain_hive_model.g.dart';

@HiveType(typeId: 4)
class DepositChainHiveModel {
  static const int typeId = 4;
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime updatedAt;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final List<String> depositIds;

  @HiveField(6)
  final int totalDeposits;

  @HiveField(7)
  final double totalAmount;

  @HiveField(8)
  final double currentValue;

  @HiveField(9)
  final int status; // ChainStatus enum as int

  DepositChainHiveModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    required this.depositIds,
    required this.totalDeposits,
    required this.totalAmount,
    required this.currentValue,
    required this.status,
  });

  DepositChainHiveModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    List<String>? depositIds,
    int? totalDeposits,
    double? totalAmount,
    double? currentValue,
    int? status,
  }) {
    return DepositChainHiveModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      depositIds: depositIds ?? this.depositIds,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalAmount: totalAmount ?? this.totalAmount,
      currentValue: currentValue ?? this.currentValue,
      status: status ?? this.status,
    );
  }

  factory DepositChainHiveModel.fromDomain(
    String id,
    String name,
    DateTime createdAt,
    DateTime updatedAt,
    String? description,
    List<String> depositIds,
    int totalDeposits,
    double totalAmount,
    double currentValue,
    int status,
  ) {
    return DepositChainHiveModel(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
      description: description,
      depositIds: depositIds,
      totalDeposits: totalDeposits,
      totalAmount: totalAmount,
      currentValue: currentValue,
      status: status,
    );
  }
}

@HiveType(typeId: 5)
class ChainLinkHiveModel {
  static const int typeId = 5;
  @HiveField(0)
  final String parentDepositId;

  @HiveField(1)
  final String childDepositId;

  @HiveField(2)
  final DateTime linkedAt;

  @HiveField(3)
  final double reinvestedAmount;

  @HiveField(4)
  final String? notes;

  ChainLinkHiveModel({
    required this.parentDepositId,
    required this.childDepositId,
    required this.linkedAt,
    required this.reinvestedAmount,
    this.notes,
  });

  factory ChainLinkHiveModel.fromDomain(
    String parentDepositId,
    String childDepositId,
    DateTime linkedAt,
    double reinvestedAmount,
    String? notes,
  ) {
    return ChainLinkHiveModel(
      parentDepositId: parentDepositId,
      childDepositId: childDepositId,
      linkedAt: linkedAt,
      reinvestedAmount: reinvestedAmount,
      notes: notes,
    );
  }
}
