import '../../../../core/network/dio_client.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_stats_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DioClient _dioClient;

  DashboardRepositoryImpl(this._dioClient);

  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dioClient.dio.get('/api/dashboard/stats');
      return DashboardStatsModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      // Return empty stats on error
      return DashboardStats.empty();
    }
  }
}
