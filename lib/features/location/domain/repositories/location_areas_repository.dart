import '../../../models/entities/location_area.dart';

/// Domain contract for resolving location area names without leaking datasources.
abstract class LocationAreasRepository {
  Future<Map<String, LocationArea>> fetchNamesByIds(List<String> ids);
  Future<Map<String, LocationArea>> fetchAll();
}
