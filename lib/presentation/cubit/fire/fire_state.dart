part of 'fire_cubit.dart';

abstract class FireState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FireInitial extends FireState {}

class FireLoading extends FireState {}

class AddFireSuccess extends FireState {
  final String message;

  AddFireSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AddFireFailure extends FireState {
  final String message;

  AddFireFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class GetFireSuccess extends FireState {
  final List<FireNumber> fireData;

  GetFireSuccess({required this.fireData});

  @override
  List<Object?> get props => [fireData];
}

class GetFireFailure extends FireState {
  final String message;

  GetFireFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class UpdateFireSuccess extends FireState {
  final String msg;

  UpdateFireSuccess({required this.msg});

  @override
  List<Object?> get props => [msg];
}

class UpdateFireFailure extends FireState {
  final String message;

  UpdateFireFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class DeleteFireSuccess extends FireState {
  final String msg;

  DeleteFireSuccess({required this.msg});

  @override
  List<Object?> get props => [msg];
}

class DeleteFireFailure extends FireState {
  final String message;

  DeleteFireFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
