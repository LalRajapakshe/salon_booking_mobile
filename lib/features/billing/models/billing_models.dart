class TaxSetting {
  const TaxSetting({
    required this.branchId,
    required this.configured,
    required this.name,
    required this.ratePercent,
  });

  final int branchId;
  final bool configured;
  final String name;
  final double ratePercent;

  factory TaxSetting.fromJson(Map<String, dynamic> json) {
    return TaxSetting(
      branchId: _int(json['branchId']),
      configured: json['configured'] == true,
      name: json['name']?.toString() ?? 'Tax',
      ratePercent: _money(json['ratePercent']),
    );
  }
}

class RetailProduct {
  const RetailProduct({
    required this.id,
    required this.branchId,
    required this.code,
    required this.name,
    required this.sellingPrice,
    required this.isActive,
    this.description,
  });

  final int id;
  final int branchId;
  final String code;
  final String name;
  final double sellingPrice;
  final bool isActive;
  final String? description;

  factory RetailProduct.fromJson(Map<String, dynamic> json) {
    return RetailProduct(
      id: _int(json['retailProductId']),
      branchId: _int(json['branchId']),
      code: json['productCode']?.toString() ?? '',
      name: json['productName']?.toString() ?? '',
      sellingPrice: _money(json['sellingPrice']),
      isActive: json['isActive'] == true,
      description: json['description']?.toString(),
    );
  }
}

class EligibleServiceLine {
  const EligibleServiceLine({
    required this.appointmentServiceId,
    required this.appointmentId,
    required this.serviceName,
    required this.unitPrice,
  });

  final int appointmentServiceId;
  final int appointmentId;
  final String serviceName;
  final double unitPrice;

  factory EligibleServiceLine.fromJson(Map<String, dynamic> json) {
    return EligibleServiceLine(
      appointmentServiceId: _int(json['appointmentServiceId']),
      appointmentId: _int(json['appointmentId']),
      serviceName: json['serviceName']?.toString() ?? 'Service',
      unitPrice: _money(json['unitPrice']),
    );
  }
}

class BillLine {
  const BillLine({
    required this.id,
    required this.lineType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxAmount,
    required this.lineTotal,
    this.taxRatePercent = 0,
    this.retailProductId,
  });

  final int id;
  final String lineType;
  final String description;
  final int quantity;
  final double unitPrice;
  final double taxAmount;
  final double lineTotal;
  final double taxRatePercent;
  final int? retailProductId;

  factory BillLine.fromJson(Map<String, dynamic> json) {
    return BillLine(
      id: _int(json['billLineId']),
      lineType: json['lineType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      quantity: _int(json['quantity']),
      unitPrice: _money(json['unitPrice']),
      taxAmount: _money(json['taxAmount']),
      taxRatePercent: _money(json['taxRatePercent']),
      lineTotal: _money(json['lineTotal']),
      retailProductId: json['retailProductId'] == null ? null : _int(json['retailProductId']),
    );
  }
}

class BillPaymentRecord {
  const BillPaymentRecord({
    required this.id,
    required this.kind,
    required this.method,
    required this.amount,
    required this.recordedAt,
  });

  final int id;
  final String kind;
  final String method;
  final double amount;
  final DateTime recordedAt;

  factory BillPaymentRecord.fromJson(Map<String, dynamic> json) {
    return BillPaymentRecord(
      id: _int(json['billPaymentId']),
      kind: json['kind']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      amount: _money(json['amount']),
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SalonBill {
  const SalonBill({
    required this.id,
    required this.branchId,
    required this.customerId,
    required this.status,
    required this.paymentStatus,
    required this.billDate,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.netCollected,
    required this.outstanding,
    required this.rowVersion,
    required this.lines,
    required this.payments,
    this.customerName,
    this.appointmentId,
    this.billNumber,
    this.notes,
    this.voidReason,
  });

  final int id;
  final int branchId;
  final int customerId;
  final String? customerName;
  final int? appointmentId;
  final String? billNumber;
  final String status;
  final String paymentStatus;
  final DateTime billDate;
  final double subtotal;
  final double taxAmount;
  final double total;
  final double netCollected;
  final double outstanding;
  final String? notes;
  final String? voidReason;
  final String rowVersion;
  final List<BillLine> lines;
  final List<BillPaymentRecord> payments;

  bool get isDraft => status == 'Draft';
  bool get isFinalized => status == 'Finalized';
  bool get isVoid => status == 'Void';

  String get receiptText {
    final buffer = StringBuffer()
      ..writeln(billNumber ?? 'Draft bill')
      ..writeln(customerName ?? 'Customer $customerId')
      ..writeln(status);
    for (final line in lines) {
      buffer.writeln('${line.description} x${line.quantity}  ${line.lineTotal.toStringAsFixed(2)}');
    }
    buffer
      ..writeln('Subtotal ${subtotal.toStringAsFixed(2)}')
      ..writeln('Tax ${taxAmount.toStringAsFixed(2)}')
      ..writeln('Total ${total.toStringAsFixed(2)}')
      ..writeln('Collected ${netCollected.toStringAsFixed(2)}')
      ..writeln('Outstanding ${outstanding.toStringAsFixed(2)}');
    return buffer.toString();
  }

  factory SalonBill.fromJson(Map<String, dynamic> json) {
    return SalonBill(
      id: _int(json['billId']),
      branchId: _int(json['branchId']),
      customerId: _int(json['customerId']),
      customerName: json['customerName']?.toString(),
      appointmentId: json['appointmentId'] == null ? null : _int(json['appointmentId']),
      billNumber: json['billNumber']?.toString(),
      status: json['status']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      billDate: DateTime.tryParse(json['billDate']?.toString() ?? '') ?? DateTime.now(),
      subtotal: _money(json['subtotal']),
      taxAmount: _money(json['taxAmount']),
      total: _money(json['total']),
      netCollected: _money(json['netCollected']),
      outstanding: _money(json['outstanding']),
      notes: json['notes']?.toString(),
      voidReason: json['voidReason']?.toString(),
      rowVersion: json['rowVersion']?.toString() ?? '',
      lines: (json['lines'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BillLine.fromJson)
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(BillPaymentRecord.fromJson)
          .toList(),
    );
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _money(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
