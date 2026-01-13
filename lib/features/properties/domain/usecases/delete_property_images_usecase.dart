import 'package:real_state/features/properties/domain/services/property_upload_service.dart';

class DeletePropertyImagesUseCase {
  DeletePropertyImagesUseCase(this._uploadService);

  final PropertyUploadService _uploadService;

  Future<void> call({required List<String> removedUrls}) {
    return _uploadService.deleteRemovedRemoteImages(removedUrls: removedUrls);
  }
}
