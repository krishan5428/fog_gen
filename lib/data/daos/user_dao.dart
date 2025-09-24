import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

import '../tables/user_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [User])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  // Insert user
  Future<int> insertUser(UserCompanion userCompanion) =>
      into(user).insert(userCompanion);

  // Get user by mobile and password
  Future<UserData?> getUserByMobileAndPassword(String mobile, String password) {
    return (select(user)
          ..where(
            (u) => u.mobileNumber.equals(mobile) & u.password.equals(password),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  // Get user by ID
  Future<UserData?> getUserById(int userId) {
    return (select(user)
          ..where((u) => u.id.equals(userId))
          ..limit(1))
        .getSingleOrNull();
  }

  // Get user by mobile only
  Future<UserData?> getUserByMobile(String mobile) {
    return (select(user)
          ..where((u) => u.mobileNumber.equals(mobile))
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------- UPDATE METHODS ----------
  Future<void> updateUserName(int userId, String newName) {
    return (update(user)..where(
      (u) => u.id.equals(userId),
    )).write(UserCompanion(name: Value(newName)));
  }

  Future<void> updateUserMobile(int userId, String newMobile) {
    return (update(user)..where(
      (u) => u.id.equals(userId),
    )).write(UserCompanion(mobileNumber: Value(newMobile)));
  }

  Future<void> updateUserPassword(int userId, String newPassword) {
    return (update(user)..where(
      (u) => u.id.equals(userId),
    )).write(UserCompanion(password: Value(newPassword)));
  }

  Future<void> updateUserEmail(int userId, String newEmail) {
    return (update(user)..where(
      (u) => u.id.equals(userId),
    )).write(UserCompanion(email: Value(newEmail)));
  }

  Future<int> deleteUser(int userId) {
    return (delete(user)..where((u) => u.id.equals(userId))).go();
  }
}
