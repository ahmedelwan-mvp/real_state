import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

enum PropertyFilterValidationError {
  priceRange('price_error_range'),
  negativePrice('price_error_range');

  final String messageKey;

  const PropertyFilterValidationError(this.messageKey);
}

/// Immutable value object that owns filter validation and equality.
@immutable
class PropertyFilter extends Equatable {
  final String? locationAreaId;
  final double? minPrice;
  final double? maxPrice;
  final int? rooms;
  final bool? hasPool;
  final String? createdBy;
  final List<String> categoryIds;

  const PropertyFilter({
    this.locationAreaId,
    this.minPrice,
    this.maxPrice,
    this.rooms,
    this.hasPool,
    this.createdBy,
    List<String>? categoryIds,
  }) : categoryIds = categoryIds ?? const [];

  static const PropertyFilter empty = PropertyFilter();

  bool get isEmpty =>
      locationAreaId == null &&
      minPrice == null &&
      maxPrice == null &&
      rooms == null &&
      hasPool == null &&
      createdBy == null &&
      categoryIds.isEmpty;

  bool get isValid => validationError == null;

  PropertyFilterValidationError? get validationError {
    if ((minPrice != null && minPrice! < 0) ||
        (maxPrice != null && maxPrice! < 0)) {
      return PropertyFilterValidationError.negativePrice;
    }
    if (minPrice != null && maxPrice != null && minPrice! > maxPrice!) {
      return PropertyFilterValidationError.priceRange;
    }
    return null;
  }

  PropertyFilter copyWith({
    String? locationAreaId,
    double? minPrice,
    double? maxPrice,
    int? rooms,
    bool? hasPool,
    String? createdBy,
    List<String>? categoryIds,
    bool clearLocationAreaId = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearRooms = false,
    bool clearHasPool = false,
    bool clearCreatedBy = false,
    bool clearCategoryIds = false,
  }) {
    return PropertyFilter(
      locationAreaId: clearLocationAreaId
          ? null
          : (locationAreaId ?? this.locationAreaId),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      rooms: clearRooms ? null : (rooms ?? this.rooms),
      hasPool: clearHasPool ? null : (hasPool ?? this.hasPool),
      createdBy: clearCreatedBy ? null : (createdBy ?? this.createdBy),
      categoryIds: clearCategoryIds
          ? const []
          : (categoryIds ?? this.categoryIds),
    );
  }

  @override
  List<Object?> get props => [
    locationAreaId,
    minPrice,
    maxPrice,
    rooms,
    hasPool,
    createdBy,
    categoryIds,
  ];
}
