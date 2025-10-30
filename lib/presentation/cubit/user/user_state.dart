part of 'user_cubit.dart';

abstract class UserState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoginSuccess extends UserState {
  final UserData user;

  UserLoginSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class UserLoginFailure extends UserState {
  final String message;

  UserLoginFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserSignUpSuccess extends UserState {
  final String message;
  UserSignUpSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserSignUpFailure extends UserState {
  final String message;

  UserSignUpFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserForgotPassSuccess extends UserState {
  final String message;

  UserForgotPassSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserForgotPassFailure extends UserState {
  final String message;

  UserForgotPassFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserUpdateSuccess extends UserState {
  final String message;

  UserUpdateSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserUpdateFailure extends UserState {
  final String message;

  UserUpdateFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserDeleteSuccess extends UserState {
  final String message;

  UserDeleteSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserDeleteFailure extends UserState {
  final String message;

  UserDeleteFailure({required this.message});

  @override
  List<Object?> get props => ['Something went error!'];
}
