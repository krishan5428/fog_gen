import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/data/pojo/fire_list.dart';
import '../../../core/repo/fire_repo.dart';

part 'fire_state.dart';

class FireCubit extends Cubit<FireState> {
  final FireRepo fireRepo;

  FireCubit(this.fireRepo) : super(FireInitial());

  void getFireNumbers({required String userId}) async {
    emit(FireLoading());
    try {
      final response = await fireRepo.getFireNumbers(userId);

      if (response.status) {
        emit(GetFireSuccess(fireData: response.fireNumbers));
      } else {
        emit(GetFireFailure(message: 'No Data Found'));
      }
    } catch (e) {
      emit(GetFireFailure(message: e.toString()));
    }
  }

  void addFire1({required String userId, required String fireNo1}) async {
    print('🔥 addFire1 called with fireNo1: $fireNo1');
    emit(FireLoading());
    try {
      final response = await fireRepo.addFireNo1(userId, fireNo1);

      emit(AddFireSuccess(message: response.msg));
    } catch (e) {
      print('🔥 Exception in addFire1: $e');
      emit(AddFireFailure(message: e.toString()));
    }
  }

  void updateFireNo({
    required String userId,
    required String fireId,
    required String number,
    required int count,
  }) async {
    emit(FireLoading());
    try {
      final response = await fireRepo.updateFireNo(
        userId,
        fireId,
        number,
        count,
      );

      emit(UpdateFireSuccess(msg: response.message));
    } catch (e) {
      emit(UpdateFireFailure(message: e.toString()));
    }
  }

  void deleteFireWRTFireId({
    required String userId,
    required String fireId,
  }) async {
    emit(FireLoading());
    try {
      final response = await fireRepo.deleteFireWRTFireId(userId, fireId);

      if (response.status) {
        emit(DeleteFireSuccess(msg: response.msg));
      } else {
        emit(DeleteFireFailure(message: 'Error while deleting Fire Numbers'));
      }
    } catch (e) {
      emit(DeleteFireFailure(message: e.toString()));
    }
  }
}
