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
      totalSales: (json['total_sales'] as num).toDouble(),
      totalOrders: json['total_orders'],
    );
  }
}

class DailyReport {
  final int day;
  final double totalSales;
  final int totalOrders;

  DailyReport({
    required this.day,
    required this.totalSales,
    required this.totalOrders,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      day: json['day'],
      totalSales: (json['total_sales'] as num).toDouble(),
      totalOrders: json['total_orders'],
    );
  }
}