import 'package:meta/meta.dart';

import '../../domain/entities/category.dart';

@immutable
class CategoryDto {
  final String id;
  final String name;
  final String? icon;

  const CategoryDto({required this.id, required this.name, this.icon});

  factory CategoryDto.fromMap(String id, Map<String, dynamic> map) {
    return CategoryDto(
      id: id,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String?,
    );
  }

  Category toDomain() {
    return Category(id: id, name: name, icon: icon);
  }
}
