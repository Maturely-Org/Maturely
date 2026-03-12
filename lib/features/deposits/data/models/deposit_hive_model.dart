import 'package:hive/hive.dart';

part 'deposit_hive_model.g.dart';

@HiveType(typeId: 1)
class AttachmentHiveModel extends HiveObject {
  static const int typeId = 1;

  @HiveField(0)
  String id;

  @HiveField(1)
  String storagePath;

  @HiveField(2)
  String kind; // 'receipt' | 'diary_page'

  @HiveField(3)
  String? ocrVersion;

  @HiveField(4)
  Map<String, dynamic>? fieldsExtracted;

  AttachmentHiveModel({
    required this.id,
    required this.storagePath,
    required this.kind,
    this.ocrVersion,
    this.fieldsExtracted,
  });
}

@HiveType(typeId: 2)
class DepositHiveModel extends HiveObject {
  static const int typeId = 2;

  @HiveField(0)
  String id;

  @HiveField(1)
  String srNo;

  @HiveField(2)
  List<String> holders;

  @HiveField(3)
  String bankName;

  @HiveField(4)
  String accountNumber;

  @HiveField(5)
  String fdrNo;

  @HiveField(6)
  double amountDeposited;

  @HiveField(7)
  double dueAmount;

  @HiveField(8)
  DateTime dateDeposited;

  @HiveField(9)
  DateTime dueDate;

  @HiveField(10)
  String status; // active | matured | closed

  @HiveField(11)
  String? closureType; // reinvested | withdrawn | unknown

  @HiveField(12)
  String? previousDepositId;

  @HiveField(13)
  String? nextDepositId;

  @HiveField(14)
  String? chainId;

  @HiveField(15)
  DateTime createdAt;

  @HiveField(16)
  DateTime updatedAt;

  @HiveField(17)
  String? notes;

  @HiveField(18)
  List<AttachmentHiveModel> attachments;

  DepositHiveModel({
    required this.id,
    required this.srNo,
    required this.holders,
    required this.bankName,
    required this.accountNumber,
    required this.fdrNo,
    required this.amountDeposited,
    required this.dueAmount,
    required this.dateDeposited,
    required this.dueDate,
    required this.status,
    this.closureType,
    this.previousDepositId,
    this.nextDepositId,
    this.chainId,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    required this.attachments,
  });

  DepositHiveModel copyWith({
    String? id,
    String? srNo,
    List<String>? holders,
    String? bankName,
    String? accountNumber,
    String? fdrNo,
    double? amountDeposited,
    double? dueAmount,
    DateTime? dateDeposited,
    DateTime? dueDate,
    String? status,
    String? closureType,
    String? previousDepositId,
    String? nextDepositId,
    String? chainId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    List<AttachmentHiveModel>? attachments,
  }) {
    return DepositHiveModel(
      id: id ?? this.id,
      srNo: srNo ?? this.srNo,
      holders: holders ?? this.holders,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      fdrNo: fdrNo ?? this.fdrNo,
      amountDeposited: amountDeposited ?? this.amountDeposited,
      dueAmount: dueAmount ?? this.dueAmount,
      dateDeposited: dateDeposited ?? this.dateDeposited,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      closureType: closureType ?? this.closureType,
      previousDepositId: previousDepositId ?? this.previousDepositId,
      nextDepositId: nextDepositId ?? this.nextDepositId,
      chainId: chainId ?? this.chainId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
    );
  }
}
