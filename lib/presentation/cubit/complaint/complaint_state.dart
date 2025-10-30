part of 'complaint_cubit.dart';

abstract class ComplaintState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ComplaintInitial extends ComplaintState {}

class ComplaintLoading extends ComplaintState {}

class AddComplaintSuccess extends ComplaintState {
  final String message;

  AddComplaintSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AddComplaintFailure extends ComplaintState {
  final String message;

  AddComplaintFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class GetComplaintListSuccess extends ComplaintState {
  final List<ComplaintData> complaintList;

  GetComplaintListSuccess({required this.complaintList});

  @override
  List<Object?> get props => [complaintList];
}

class GetComplaintListFailure extends ComplaintState {
  final String message;

  GetComplaintListFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
