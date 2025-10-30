import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/pojo/user_data.dart';
import '../../../core/repo/user_repo.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepo userRepo;

  UserCubit(this.userRepo) : super(UserInitial());

  void login(String mobile, String pass) async {
    emit(UserLoading());
    try {
      final response = await userRepo.login(mobile, pass);
      if (kDebugMode) {
        print("Login response: status=${response.status}, msg=${response.msg}");
      }

      if (response.status && response.data != null) {
        emit(UserLoginSuccess(user: response.data!));
      } else {
        emit(
          UserLoginFailure(
            message: response.msg.isNotEmpty ? response.msg : "Login failed",
          ),
        );
      }
    } catch (e) {
      emit(UserLoginFailure(message: e.toString()));
    }
  }

  void signUp({
    required String name,
    required String email,
    required String mobile,
    required String password,
    required String devInfo,
    required String deviceId,
  }) async {
    emit(UserLoading());
    try {
      final response = await userRepo.signUp(
        name,
        email,
        mobile,
        password,
        devInfo,
        deviceId,
      );
      if (kDebugMode) {
        print(
          'Signup response : status=${response.status}, msg =${response.msg}',
        );
      }

      if (response.status) {
        emit(UserSignUpSuccess(message: response.msg));
      } else {
        emit(
          UserSignUpFailure(
            message: response.msg.isNotEmpty ? response.msg : "Signup failed",
          ),
        );
      }
    } catch (e) {
      emit(UserSignUpFailure(message: e.toString()));
    }
  }

  void forgotPass({required String mobile}) async {
    emit(UserLoading());
    try {
      final response = await userRepo.forgotPass(mobile);

      if (response.status) {
        emit(UserForgotPassSuccess(message: response.msg));
      } else {
        emit(UserForgotPassFailure(message: response.msg));
      }
    } catch (e) {
      emit(UserForgotPassFailure(message: e.toString()));
    }
  }

  void updateUser({
    required String userId,
    required String value,
    required String key,
  }) async {
    print('waiting for updateUser response');
    emit(UserLoading());
    try {
      final response = await userRepo.updateValue(userId, value, key);

      emit(UserUpdateSuccess(message: response.msg));
    } catch (e) {
      emit(UserUpdateFailure(message: e.toString()));
    }
  }

  void deleteUser({required String mobile, required String password}) async {
    emit(UserLoading());
    try {
      final response = await userRepo.deleteUser(mobile, password);

      emit(UserDeleteSuccess(message: response.msg));
    } catch (e) {
      emit(UserDeleteFailure(message: e.toString()));
    }
  }
}
