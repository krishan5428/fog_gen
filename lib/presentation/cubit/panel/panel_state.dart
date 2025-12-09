part of 'panel_cubit.dart';

abstract class PanelState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PanelInitial extends PanelState {}

class PanelLoading extends PanelState {}

class AddPanelSuccess extends PanelState {
  final String message;
  AddPanelSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AddPanelFailure extends PanelState {
  final String message;
  AddPanelFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class GetPanelsSuccess extends PanelState {
  final List<PanelData> panelsData;
  GetPanelsSuccess({required this.panelsData});

  @override
  List<Object?> get props => [panelsData];
}

class GetPanelsFailure extends PanelState {
  final String message;
  GetPanelsFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class DeletePanelsSuccess extends PanelState {
  final String msg;
  DeletePanelsSuccess({required this.msg});

  @override
  List<Object?> get props => [msg];
}

class DeletePanelsFailure extends PanelState {
  final String message;
  DeletePanelsFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class UpdatePanelsSuccess extends PanelState {
  final String msg;
  final PanelData panelData;
  UpdatePanelsSuccess({required this.msg, required this.panelData});

  @override
  List<Object?> get props => [msg];
}

class UpdatePanelsFailure extends PanelState {
  final String message;
  UpdatePanelsFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
