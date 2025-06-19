import 'package:sayurku/models/report_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MonthlyReport>> getMonthlyReports(int year) async {
    final response = await _client.rpc(
      'get_monthly_reports',
      params: {'year': year},
    );
    return (response as List)
        .map((json) => MonthlyReport.fromJson(json))
        .toList();
  }
}
