part of 'intru_cubit.dart';

abstract class IntruState extends Equatable {
  @override
  List<Object?> get props => [];
}

class IntruInitial extends IntruState {}

class IntruLoading extends IntruState {}

class AddIntruSuccess extends IntruState {
  final String message;

  AddIntruSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AddIntruFailure extends IntruState {
  final String message;

  AddIntruFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class GetIntruSuccess extends IntruState {
  final List<IntrusionNumber> intruData;

  GetIntruSuccess({required this.intruData});

  @override
  List<Object?> get props => [intruData];
}

class GetIntruFailure extends IntruState {
  final String message;

  GetIntruFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class UpdateIntruSuccess extends IntruState {
  final String msg;

  UpdateIntruSuccess({required this.msg});

  @override
  List<Object?> get props => [msg];
}

class UpdateIntruFailure extends IntruState {
  final String message;

  UpdateIntruFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class DeleteIntruSuccess extends IntruState {
  final String msg;

  DeleteIntruSuccess({required this.msg});

  @override
  List<Object?> get props => [msg];
}

class DeleteIntruFailure extends IntruState {
  final String message;

  DeleteIntruFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
