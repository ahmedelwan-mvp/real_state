import 'package:image_picker/image_picker.dart';

import '../../../models/entities/location_area.dart';

/// Domain contract for managing location areas without touching data sources.
abstract class LocationRepository {
  Future<List<LocationArea>> fetchAll();

  Future<String> create({
    required String nameAr,
    required String nameEn,
    required XFile imageFile,
  });

  Future<void> update({
    required String id,
    required String nameAr,
    required String nameEn,
    XFile? imageFile,
    String? previousImageUrl,
  });

  Future<bool> canDelete(String id);

  Future<void> delete(String id);
}
