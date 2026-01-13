import 'package:bloc/bloc.dart';
import '../../../core/repo/user_repo.dart';
import 'forgot_pass_state.dart';

class ForgetPswdCubit extends Cubit<ForgetPswdState> {
  final UserRepo repository;

  ForgetPswdCubit({required this.repository}) : super(ForgetPswdStateInitial());

  Future<void> forgetPassword({required String mobile}) async {
    if (mobile.isEmpty) {
      emit(const ForgetPswdStateError(error: 'Mobile cannot be empty'));
      return;
    }

    emit(ForgetPswdStateLoading());

    try {
      final response = await repository.forgotPass(mobile);

      if (response.status) {
        emit(ForgetPswdStateSuccess(msg: response.msg));
      } else {
        emit(ForgetPswdStateError(error: response.msg));
      }
    } catch (e) {
      emit(
        const ForgetPswdStateError(
          error: 'Something went wrong. Please try again.',
        ),
      );
    }
  }
}
