import '../../../core/network/api_client.dart';
import '../../../core/network/json_reader.dart';
import '../domain/analytics.dart';

final class AnalyticsDto {
  AnalyticsDto(Object? json) : _json = JsonReader(json);
  final JsonReader _json;
  AnalyticsSnapshot toDomain() {
    final pool = _json.object('talent_pool');
    final funnel = _json.object('funnel');
    return AnalyticsSnapshot(
      candidates: pool.integer('candidates_open'),
      verified: pool.integer('candidates_verified'),
      views: funnel.integer('candidates_viewed'),
      sent: funnel.integer('offers_sent'),
      opened: funnel.integer('offers_opened'),
      accepted: funnel.integer('offers_accepted'),
      averageResponseHours: _json.optionalDecimal('average_response_hours'),
    );
  }
}

final class RemoteAnalyticsRepository implements AnalyticsRepository {
  const RemoteAnalyticsRepository(this.api);
  final ApiClient api;
  @override
  Future<AnalyticsSnapshot> overview() async =>
      AnalyticsDto(await api.request('GET', 'analytics/overview')).toDomain();
}
