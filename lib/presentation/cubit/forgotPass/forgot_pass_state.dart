import 'package:equatable/equatable.dart';

abstract class ForgetPswdState extends Equatable {
  const ForgetPswdState();
}

class ForgetPswdStateInitial extends ForgetPswdState {
  @override
  List<Object?> get props => [];
}

class ForgetPswdStateLoading extends ForgetPswdState {
  @override
  List<Object?> get props => [];
}

class ForgetPswdStateError extends ForgetPswdState {
  final String error;
  const ForgetPswdStateError({required this.error});

  @override
  List<Object?> get props => [error];
}

class ForgetPswdStateSuccess extends ForgetPswdState {
  final String msg;
  const ForgetPswdStateSuccess({required this.msg});

  @override
  List<Object?> get props => [msg];
}
