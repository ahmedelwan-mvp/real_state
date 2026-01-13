import '../../../../core/constants/user_role.dart';
import '../entities/managed_user.dart';

/// Domain contract for looking up users without importing data sources.
abstract class UsersLookupRepository {
  Future<List<ManagedUser>> fetchUsers({UserRole? role});
  Future<ManagedUser> getById(String id);
}
