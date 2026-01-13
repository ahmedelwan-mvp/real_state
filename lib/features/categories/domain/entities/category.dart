import 'package:equatable/equatable.dart';

/// Simple domain representation of a category for future features.
class Category extends Equatable {
  final String id;
  final String name;
  final String? icon;

  const Category({required this.id, required this.name, this.icon});

  @override
  List<Object?> get props => [id, name, icon];
}
