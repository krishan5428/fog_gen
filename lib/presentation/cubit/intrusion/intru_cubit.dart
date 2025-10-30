import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/data/pojo/intru_list.dart';
import '../../../core/repo/intru_repo.dart';

part 'intru_state.dart';

class IntruCubit extends Cubit<IntruState> {
  final IntruRepo intruRepo;

  IntruCubit(this.intruRepo) : super(IntruInitial());

  void getIntru({required String userId}) async {
    emit(IntruLoading());
    try {
      final response = await intruRepo.getIntrusionNumbers(userId);

      if (response.status) {
        emit(GetIntruSuccess(intruData: response.intrusionNumbers));
      } else {
        emit(GetIntruFailure(message: 'No Data Found'));
      }
    } catch (e) {
      emit(GetIntruFailure(message: e.toString()));
    }
  }

  void addIntru1({required String userId, required String intruNo1}) async {
    emit(IntruLoading());
    try {
      final response = await intruRepo.addIntruNo1(userId, intruNo1);

      if (response.status) {
        emit(AddIntruSuccess(message: response.msg));
      } else {
        emit(AddIntruFailure(message: 'Error while adding Intrusion Number'));
      }
    } catch (e) {
      emit(AddIntruFailure(message: e.toString()));
    }
  }

  void updateIntruNo({
    required String userId,
    required String intruId,
    required String number,
    required int count,
  }) async {
    emit(IntruLoading());
    try {
      final response = await intruRepo.updateIntruNo(
        userId,
        intruId,
        number,
        count,
      );

      if (response.status) {
        emit(UpdateIntruSuccess(msg: response.msg));
        print('[IntruCubit] updateIntruNo response: ${response.msg}');
      } else {
        emit(
          UpdateIntruFailure(message: 'Error while updating Intrusion Number'),
        );
      }
    } catch (e) {
      emit(UpdateIntruFailure(message: e.toString()));
    }
  }

  void deleteIntruWRTIntruId({
    required String userId,
    required String intruId,
  }) async {
    emit(IntruLoading());
    try {
      final response = await intruRepo.deleteIntruWRTIntruId(userId, intruId);

      if (response.status) {
        emit(DeleteIntruSuccess(msg: response.msg));
      } else {
        emit(
          DeleteIntruFailure(message: 'Error while deleting Intrusion Numbers'),
        );
      }
    } catch (e) {
      emit(DeleteIntruFailure(message: e.toString()));
    }
  }
}
