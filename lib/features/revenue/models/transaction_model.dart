class TransactionModel {
  final String invoiceNo;
  final String customerName;
  final String service;
  final String employee;
  final double amount;
  final String paymentMethod;
  final DateTime date;

  const TransactionModel({
    required this.invoiceNo,
    required this.customerName,
    required this.service,
    required this.employee,
    required this.amount,
    required this.paymentMethod,
    required this.date,
  });
}