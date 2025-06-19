class MonthlyReport {
  final int month;
  final int year;
  final double totalSales;
  final int totalOrders;

  MonthlyReport({
    required this.month,
    required this.year,
    required this.totalSales,
    required this.totalOrders,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      month: json['month'],
      year: json['year'],
      totalSales: json['total_sales'].toDouble(),
      totalOrders: json['total_orders'],
    );
  }
}
