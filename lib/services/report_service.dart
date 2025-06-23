import 'package:sayurku/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MonthlyReport>> getMonthlyReports(int year) async {
    final response = await _client.rpc(
      'get_monthly_reports',
      params: {'p_year': year},
    );
    return (response as List)
        .map((json) => MonthlyReport.fromJson(json))
        .toList();
  }

  Future<List<DailyReport>> getDailyReports(int year, int month) async {
    final response = await _client.rpc(
      'get_daily_reports',
      params: {'p_year': year, 'p_month': month},
    );
    return (response as List)
        .map((json) => DailyReport.fromJson(json))
        .toList();
  }
}