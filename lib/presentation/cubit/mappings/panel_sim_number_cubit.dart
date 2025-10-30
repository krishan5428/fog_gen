import 'package:flutter_bloc/flutter_bloc.dart';

class PanelSimNumberCubit extends Cubit<List<String>> {
  PanelSimNumberCubit() : super([]);

  void setPanelSimNumbers(List<String> numbers) => emit(numbers);
}
