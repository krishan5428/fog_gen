import 'package:flutter_bloc/flutter_bloc.dart';

class SiteCubit extends Cubit<List<String>> {
  SiteCubit() : super([]);

  void setSites(List<String> sites) => emit(sites);
}
