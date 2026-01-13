import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class GetCategoriesUseCase {
  final CategoriesRepository _repository;

  const GetCategoriesUseCase(this._repository);

  Future<List<Category>> call() {
    return _repository.fetchCategories();
  }
}
