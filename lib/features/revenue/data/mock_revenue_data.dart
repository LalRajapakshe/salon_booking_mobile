import '../models/employee_revenue.dart';
import '../models/revenue_model.dart';
import '../models/transaction_model.dart';

class MockRevenueData {
  /// ===============================
  /// Revenue Summary
  /// ===============================

  static const RevenueModel summary = RevenueModel(
    todayRevenue: 84500,
    weeklyRevenue: 468000,
    monthlyRevenue: 1865000,
    yearlyRevenue: 22380000,
  );

  /// ===============================
  /// Revenue Trend (Last 7 Days)
  /// ===============================

  static const List<double> weeklyRevenueTrend = [
    52000,
    61000,
    58500,
    74000,
    69500,
    81200,
    84500,
  ];

  /// ===============================
  /// Revenue by Service
  /// ===============================

  static const Map<String, double> serviceRevenue = {
    'Hair Cut': 185000,
    'Hair Coloring': 420000,
    'Facial': 265000,
    'Spa': 315000,
    'Nail Care': 198000,
    'Bridal': 482000,
  };

  /// ===============================
  /// Payment Breakdown
  /// ===============================

static const Map<String, double> paymentMethods = {
  'Cash': 420000,
  'Card': 985000,
  'Online': 460000,
};

  /// ===============================
  /// Top Employees
  /// ===============================

  static const List<EmployeeRevenue> topEmployees = [
    EmployeeRevenue(
      name: 'Sarah',
      role: 'Senior Stylist',
      revenue: 482000,
      appointments: 86,
      growth: 18.4,
      avatar: 'S',
    ),
    EmployeeRevenue(
      name: 'Emily',
      role: 'Hair Artist',
      revenue: 438500,
      appointments: 79,
      growth: 15.8,
      avatar: 'E',
    ),
    EmployeeRevenue(
      name: 'Jessica',
      role: 'Beautician',
      revenue: 392000,
      appointments: 72,
      growth: 12.6,
      avatar: 'J',
    ),
    EmployeeRevenue(
      name: 'Michael',
      role: 'Spa Therapist',
      revenue: 365000,
      appointments: 68,
      growth: 10.3,
      avatar: 'M',
    ),
  ];

  /// ===============================
  /// Recent Transactions
  /// ===============================

  static final List<TransactionModel> recentTransactions = [
    TransactionModel(
      invoiceNo: 'INV-1001',
      customerName: 'Emma Watson',
      service: 'Hair Coloring',
      employee: 'Sarah',
      amount: 18500,
      paymentMethod: 'Card',
      date: DateTime.now(),
    ),
    TransactionModel(
      invoiceNo: 'INV-1002',
      customerName: 'Olivia Brown',
      service: 'Spa',
      employee: 'Michael',
      amount: 15000,
      paymentMethod: 'Cash',
      date: DateTime.now(),
    ),
    TransactionModel(
      invoiceNo: 'INV-1003',
      customerName: 'Sophia Wilson',
      service: 'Facial',
      employee: 'Jessica',
      amount: 9800,
      paymentMethod: 'Online',
      date: DateTime.now(),
    ),
    TransactionModel(
      invoiceNo: 'INV-1004',
      customerName: 'Isabella Taylor',
      service: 'Hair Cut',
      employee: 'Emily',
      amount: 6500,
      paymentMethod: 'Card',
      date: DateTime.now(),
    ),
    TransactionModel(
      invoiceNo: 'INV-1005',
      customerName: 'Charlotte Davis',
      service: 'Bridal Package',
      employee: 'Sarah',
      amount: 45000,
      paymentMethod: 'Online',
      date: DateTime.now(),
    ),
  ];

  /// ===============================
  /// AI Insights
  /// ===============================

  static const List<String> aiInsights = [
    'Revenue increased by 18% compared to last month.',
    'Hair Coloring is the highest revenue-generating service.',
    'Sarah generated the highest employee revenue this month.',
    'Weekend bookings contribute nearly 40% of total revenue.',
    'Digital payments account for over 70% of transactions.',
  ];
}