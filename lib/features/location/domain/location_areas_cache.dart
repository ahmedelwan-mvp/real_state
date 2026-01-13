import 'dart:async';

import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/location/domain/repositories/location_repository.dart';
import 'package:real_state/features/models/entities/location_area.dart';

/// Simple in-memory cache for location areas and their names.
class LocationAreasCache {
  LocationAreasCache(this._repo, this._areas);

  final LocationRepository _repo;
  final LocationAreasRepository _areas;

  Map<String, LocationArea>? _areasById;
  List<LocationArea>? _list;
  Future<void>? _inflight;

  Future<void> _load({bool force = false}) async {
    if (!force && _areasById != null && _list != null) return;
    if (_inflight != null) return _inflight;
    final completer = Completer<void>();
    _inflight = completer.future;
    try {
      final items = await _repo.fetchAll();
      _list = List<LocationArea>.from(items)
        ..sort((a, b) => a.name.compareTo(b.name));
      _areasById = {for (final l in _list!) l.id: l};
      completer.complete();
    } catch (e) {
      completer.complete();
      rethrow;
    } finally {
      _inflight = null;
    }
  }

  Future<List<LocationArea>> getAll({bool force = false}) async {
    await _load(force: force);
    return List<LocationArea>.from(_list ?? const []);
  }

  Future<Map<String, LocationArea>> namesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    await _load();
    final missing = ids
        .where((id) => !(_areasById?.containsKey(id) ?? false))
        .toList();
    if (missing.isNotEmpty) {
      final fetched = await _areas.fetchNamesByIds(missing);
      _areasById = {...?_areasById, ...fetched};
    }
    return {
      for (final id in ids)
        if (_areasById?[id] != null) id: _areasById![id]!,
    };
  }

  void invalidate() {
    _areasById = null;
    _list = null;
  }

  void setFromList(List<LocationArea> items) {
    _list = List<LocationArea>.from(items)
      ..sort((a, b) => a.name.compareTo(b.name));
    _areasById = {for (final l in _list!) l.id: l};
  }
}
