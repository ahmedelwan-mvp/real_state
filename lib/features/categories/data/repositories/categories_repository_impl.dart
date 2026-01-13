import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../models/category_dto.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl();

  @override
  Future<List<Category>> fetchCategories() async {
    final dtos = _mockCategories;
    return dtos.map((dto) => dto.toDomain()).toList();
  }
}

const _mockCategories = <CategoryDto>[];
