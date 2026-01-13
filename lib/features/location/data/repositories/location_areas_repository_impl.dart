import '../../../models/entities/location_area.dart';
import '../../domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';

class LocationAreasRepositoryImpl implements LocationAreasRepository {
  LocationAreasRepositoryImpl(this._remote);

  final LocationAreaRemoteDataSource _remote;

  @override
  Future<Map<String, LocationArea>> fetchAll() {
    return _remote.fetchAll();
  }

  @override
  Future<Map<String, LocationArea>> fetchNamesByIds(List<String> ids) {
    return _remote.fetchNamesByIds(ids);
  }
}
