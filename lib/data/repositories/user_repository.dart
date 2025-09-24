import 'package:drift/drift.dart';
import 'package:fire_nex/data/database/app_database.dart';

class UserRepository {
  final AppDatabase _db;

  UserRepository(this._db);

  // create
  Future<int> insertUser(
    String name,
    String email,
    String mobileNumber,
    String password,
  ) {
    final user = UserCompanion(
      name: Value(name),
      email: Value(email),
      mobileNumber: Value(mobileNumber),
      password: Value(password),
    );
    return _db.userDao.insertUser(user);
  }

  // get
  Future<UserData?> getUserByMobileAndPassword(String mobile, String password) {
    return _db.userDao.getUserByMobileAndPassword(mobile, password);
  }

  Future<UserData?> getUserByUserId(int userId) {
    return _db.userDao.getUserById(userId);
  }

  // update
  Future<void> updateUserName(int userId, String newName) {
    return _db.userDao.updateUserName(userId, newName);
  }

  Future<void> updateUserMobile(int userId, String newMobile) {
    return _db.userDao.updateUserMobile(userId, newMobile);
  }

  Future<void> updateUserPassword(int userId, String newPassword) {
    return _db.userDao.updateUserPassword(userId, newPassword);
  }

  Future<void> updateUserEmail(int userId, String newEmail) {
    return _db.userDao.updateUserEmail(userId, newEmail);
  }

  Future<void> deleteUser(int userId) async {
    await _db.userDao.deleteUser(userId);
  }
}
