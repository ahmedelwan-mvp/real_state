import '../entities/property_filter.dart';

class PropertyFilterValidationResult {
  final PropertyFilter? filter;
  final PropertyFilterValidationError? error;

  const PropertyFilterValidationResult.success(this.filter) : error = null;

  const PropertyFilterValidationResult.failure(this.error) : filter = null;

  bool get isSuccess => filter != null;
}

class ApplyPropertyFilterUseCase {
  const ApplyPropertyFilterUseCase();

  PropertyFilterValidationResult call(PropertyFilter filter) {
    final error = filter.validationError;
    if (error != null) {
      return PropertyFilterValidationResult.failure(error);
    }
    return PropertyFilterValidationResult.success(filter);
  }
}
