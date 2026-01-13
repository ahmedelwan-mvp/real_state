import 'package:real_state/features/categories/domain/entities/property_filter.dart';

/// Shared controller to manage property filters across list pages.
class PropertyFilterController {
  PropertyFilter _filter;

  PropertyFilterController({PropertyFilter? initial})
    : _filter = initial ?? const PropertyFilter();

  PropertyFilter get filter => _filter;

  bool get hasActiveFilters => !_filter.isEmpty;

  void apply(PropertyFilter filter) {
    _filter = filter;
  }

  void clear() {
    _filter = const PropertyFilter();
  }
}
