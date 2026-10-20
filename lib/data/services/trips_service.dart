import '../../core/config/api_config.dart';
import '../../core/services/logger_service.dart';
import '../models/models.dart';
import 'api_client.dart';

class TripsService {
  TripsService._();

  static Future<List<Trip>> getTrips({
    String status = 'upcoming',
  }) async {
    try {
      LoggerService.info('Fetching trips with status: $status');

      final response = await ApiClient.instance.get(
        ApiConfig.hostTrips,
        queryParameters: {'status': status},
      );

      final raw = response['data'];
      List items = [];
      if (raw is Map && raw['items'] is List) {
        items = raw['items'];
      } else if (raw is List) {
        items = raw;
      }

      final trips = items
          .map((json) => Trip.fromJson(json as Map<String, dynamic>))
          .toList();

      LoggerService.info('Fetched ${trips.length} trips');
      return trips;
    } catch (e) {
      LoggerService.error('Failed to fetch trips', error: e);
      return [];
    }
  }

  static Future<List<Trip>> getUpcomingTrips() async {
    return getTrips(status: 'upcoming');
  }

  static Future<List<Trip>> getActiveTrips() async {
    return getTrips(status: 'active');
  }

  static Future<List<Trip>> getCompletedTrips() async {
    return getTrips(status: 'completed');
  }
}
