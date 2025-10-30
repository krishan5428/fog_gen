part of 'vendor_cubit.dart';

abstract class VendorState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VendorInitial extends VendorState {}

class VendorLoading extends VendorState {}

class AddVendorSuccess extends VendorState {
  final String message;

  AddVendorSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AddVendorFailure extends VendorState {
  final String message;

  AddVendorFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class GetVendorSuccess extends VendorState {
  final List<VendorData> vendorData;

  GetVendorSuccess({required this.vendorData});

  @override
  List<Object?> get props => [vendorData];
}

class GetVendorFailure extends VendorState {
  final String message;

  GetVendorFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class DeleteVendorSuccess extends VendorState {
  final String message;

  DeleteVendorSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class DeleteVendorFailure extends VendorState {
  final String message;

  DeleteVendorFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
