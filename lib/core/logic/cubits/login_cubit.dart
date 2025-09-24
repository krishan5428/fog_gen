import 'package:bloc/bloc.dart';
import 'package:fire_nex/core/logic/state/user/user_state.dart';
import 'package:fire_nex/core/repo/user_repo.dart';
import 'package:fire_nex/core/responses/user_response.dart';

class LoginCubit extends Cubit<LoginState> {
  final UserRepo repo;

  LoginCubit(this.repo) : super(LoginInitial());

  void login(String mobile, String pass) async {
    emit(LoginLoading());
    try {
      final LoginResponse response = await repo.loginUser(mobile, pass);
      if (response.status) {
        emit(LoginSuccess(response.message));
      } else {
        emit(LoginFailure(response.message));
      }
    } catch (e) {
      emit(LoginFailure('Something went wrong'));
    }
  }
}
