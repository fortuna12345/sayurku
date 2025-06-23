import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sayurku/models/report_model.dart';
import 'package:sayurku/services/report_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  // State untuk dua jenis laporan
  List<MonthlyReport> _monthlyReports = [];
  List<DailyReport> _dailyReports = [];

  bool _isLoading = true;
  DateTime _selectedYear = DateTime.now();
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _monthlyReports = [];
      _dailyReports = [];
    });
    try {
      if (_selectedMonth == null) {
        _monthlyReports = await _reportService.getMonthlyReports(_selectedYear.year);
      } else {
        _dailyReports = await _reportService.getDailyReports(_selectedYear.year, _selectedMonth!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat laporan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printReport() async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    final reportTitle = 'Laporan Penjualan ${
      _selectedMonth != null ? DateFormat('MMMM', 'id_ID').format(DateTime(0, _selectedMonth!)) : ''
    } ${_selectedYear.year}';
    
    final bool isDailyView = _selectedMonth != null;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(child: pw.Text(reportTitle, style: pw.TextStyle(font: boldFont, fontSize: 20))),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: isDailyView ? ['Tanggal', 'Total Penjualan', 'Jumlah Pesanan'] : ['Bulan', 'Total Penjualan', 'Jumlah Pesanan'],
              data: isDailyView
                  ? _dailyReports.map((report) => [
                      '${report.day} ${DateFormat('MMM', 'id_ID').format(DateTime(0, _selectedMonth!))}',
                      'Rp ${NumberFormat.decimalPattern('id_ID').format(report.totalSales)}',
                      report.totalOrders.toString(),
                    ]).toList()
                  : _monthlyReports.map((report) => [
                      DateFormat('MMMM', 'id_ID').format(DateTime(report.year, report.month)),
                      'Rp ${NumberFormat.decimalPattern('id_ID').format(report.totalSales)}',
                      report.totalOrders.toString(),
                    ]).toList(),
              headerStyle: pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(font: font),
              border: pw.TableBorder.all(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDailyView = _selectedMonth != null;
    final bool hasData = isDailyView ? _dailyReports.isNotEmpty : _monthlyReports.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Cetak Laporan',
            onPressed: _isLoading || !hasData ? null : _printReport,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: InputChip(
                    avatar: const Icon(Icons.calendar_today),
                    label: Text(_selectedYear.year.toString()),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedYear,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null && picked.year != _selectedYear.year) {
                        setState(() => _selectedYear = picked);
                        _loadReports();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedMonth,
                    hint: const Text('Semua Bulan'),
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    onChanged: (value) {
                      setState(() => _selectedMonth = value);
                      _loadReports();
                    },
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Bulan')),
                      ...List.generate(12, (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(DateFormat('MMMM', 'id_ID').format(DateTime(0, index + 1))),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasData
                    ? const Center(child: Text('Tidak ada data untuk periode yang dipilih.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: isDailyView ? _buildDailyReportView() : _buildMonthlyReportView(),
                      ),
          ),
        ],
      ),
    );
  }

  // Widget untuk tampilan laporan bulanan
  Widget _buildMonthlyReportView() {
    // Formatter untuk menyingkat angka penjualan (misal: 1jt, 500rb)
    final currencyFormatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grafik Penjualan Tahun ${_selectedYear.year}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              // 1. MEMPERBAIKI TAMPILAN BATANG & MENAMBAHKAN TOOLTIP
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = DateFormat('MMMM', 'id_ID').format(DateTime(0, group.x.toInt()));
                    final sales = rod.toY;
                    return BarTooltipItem(
                      '$month\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(sales),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: _monthlyReports
                  .where((report) => report.totalSales > 0) // Hanya tampilkan bar jika ada penjualan
                  .map((report) => BarChartGroupData(
                        x: report.month,
                        barRods: [
                          BarChartRodData(
                            toY: report.totalSales,
                            width: 22, // Batang lebih lebar untuk tampilan bulanan
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ))
                  .toList(),
              // 2. MEMPERBAIKI LABEL SUMBU X DAN Y
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                // Konfigurasi Sumbu Y (Kiri)
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          currencyFormatter.format(value), // Format angka menjadi ringkas
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                // Konfigurasi Sumbu X (Bawah)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1, // Tampilkan label untuk setiap bulan
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MMM', 'id_ID').format(DateTime(0, value.toInt())),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => const FlLine(color: Colors.black12, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Bulan')),
              DataColumn(label: Text('Penjualan'), numeric: true),
              DataColumn(label: Text('Pesanan'), numeric: true),
            ],
            rows: _monthlyReports.map((report) => DataRow(cells: [
              DataCell(Text(DateFormat('MMMM', 'id_ID').format(DateTime(report.year, report.month)))),
              DataCell(Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(report.totalSales))),
              DataCell(Text(report.totalOrders.toString())),
            ])).toList(),
          ),
        ),
      ],
    );
  }

  // Widget untuk tampilan laporan harian
  Widget _buildDailyReportView() {
    // Formatter untuk menyingkat angka (misal: 1jt, 500rb)
    final currencyFormatter = NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grafik Penjualan ${DateFormat('MMMM', 'id_ID').format(DateTime(0, _selectedMonth!))} ${_selectedYear.year}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              // 1. MEMPERBAIKI TAMPILAN BATANG & MENAMBAHKAN TOOLTIP
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = group.x.toInt();
                    final sales = rod.toY;
                    return BarTooltipItem(
                      'Tgl $day\n',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0)
                              .format(sales),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: _dailyReports
                  .where((report) => report.totalSales > 0) // Hanya tampilkan bar jika ada penjualan
                  .map((report) => BarChartGroupData(
                        x: report.day,
                        barRods: [
                          BarChartRodData(
                            toY: report.totalSales,
                            width: 12, // Membuat batang sedikit lebih lebar
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ))
                  .toList(),
              // 2. MEMPERBAIKI LABEL SUMBU X DAN Y
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                // Konfigurasi Sumbu Y (Kiri)
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50, // Ruang untuk label
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          currencyFormatter.format(value), // Format angka menjadi ringkas
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                // Konfigurasi Sumbu X (Bawah)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5, // Tampilkan label setiap 5 hari (0, 5, 10, ...)
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: Colors.black12, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Penjualan'), numeric: true),
              DataColumn(label: Text('Pesanan'), numeric: true),
            ],
            rows: _dailyReports
                .map((report) => DataRow(cells: [
                      DataCell(Text(report.day.toString())),
                      DataCell(Text(NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0)
                          .format(report.totalSales))),
                      DataCell(Text(report.totalOrders.toString())),
                    ]))
                .toList(),
          ),
        ),
      ],
    );
  }

}