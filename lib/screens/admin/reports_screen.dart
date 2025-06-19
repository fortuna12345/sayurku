import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sayurku/models/report_model.dart';
import 'package:sayurku/services/report_service.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  List<MonthlyReport> _reports = [];
  bool _isLoading = true;
  DateTime _selectedYear = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      _reports = await _reportService.getMonthlyReports(_selectedYear.year);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectYear(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedYear,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Year',
    );
    if (picked != null && picked != _selectedYear) {
      setState(() {
        _selectedYear = picked;
        _loadReports();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectYear(context),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Report ${_selectedYear.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Colors.blueAccent,
                              getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                final month = DateFormat('MMM').format(
                                  DateTime(0, _reports[group.x.toInt()].month),
                                );
                                return BarTooltipItem(
                                  '$month\n',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Rp ${rod.toY.toStringAsFixed(0)}',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= _reports.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    DateFormat('MMM').format(
                                      DateTime(0, _reports[index].month),
                                    ),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                                reservedSize: 32,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups:
                              _reports.asMap().entries.map((entry) {
                                final index = entry.key;
                                final report = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: report.totalSales,
                                      width: 16,
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.blue,
                                    ),
                                  ],
                                );
                              }).toList(),
                          gridData: FlGridData(show: true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Monthly Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Month')),
                        DataColumn(label: Text('Total Sales'), numeric: true),
                        DataColumn(label: Text('Orders'), numeric: true),
                      ],
                      rows:
                          _reports.map((report) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    DateFormat('MMMM').format(
                                      DateTime(report.year, report.month),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    'Rp ${report.totalSales.toStringAsFixed(0)}',
                                  ),
                                ),
                                DataCell(Text(report.totalOrders.toString())),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
    );
  }
}
