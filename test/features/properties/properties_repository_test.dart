import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';

void main() {
  group('PropertiesRepository.requiresPriceOrder', () {
    test('returns true when minPrice present', () {
      final f = PropertyFilter(minPrice: 10.0);
      expect(PropertiesRepository.requiresPriceOrder(f), isTrue);
    });

    test('returns true when maxPrice present', () {
      final f = PropertyFilter(maxPrice: 100.0);
      expect(PropertiesRepository.requiresPriceOrder(f), isTrue);
    });

    test('returns false when no price filters', () {
      final f = PropertyFilter();
      expect(PropertiesRepository.requiresPriceOrder(f), isFalse);
    });
  });
}
