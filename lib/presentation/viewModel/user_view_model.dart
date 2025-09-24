import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/data/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';

class UserViewModel {
  final UserRepository _userRepository;

  UserViewModel(this._userRepository);

  Future<bool> insertUser(
    String name,
    String email,
    String mobile,
    String password,
  ) async {
    try {
      await _userRepository.insertUser(name, email, mobile, password);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Insert failed: $e');
      }
      return false;
    }
  }

  Future<UserData?> getUserByMobileAndPassword(String mobile, String password) {
    return _userRepository.getUserByMobileAndPassword(mobile, password);
  }

  Future<UserData?> getUserByUserId(int userId) {
    return _userRepository.getUserByUserId(userId);
  }

  Future<void> updateUserName(int userId, String newName) {
    return _userRepository.updateUserName(userId, newName);
  }

  Future<void> updateUserMobile(int userId, String newMobile) {
    return _userRepository.updateUserMobile(userId, newMobile);
  }

  Future<void> updateUserPassword(int userId, String newPassword) {
    return _userRepository.updateUserPassword(userId, newPassword);
  }

  Future<void> updateUserEmail(int userId, String newEmail) {
    return _userRepository.updateUserEmail(userId, newEmail);
  }

  Future<void> deleteUser(int userId) async {
    await _userRepository.deleteUser(userId);
  }
}
