import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/data/pojo/vendor_data.dart';
import '../../../core/repo/vendor_repo.dart';

part 'vendor_state.dart';

class VendorCubit extends Cubit<VendorState> {
  final VendorRepo vendorRepo;

  VendorCubit(this.vendorRepo) : super(VendorInitial());

  void getVendor({required String userId}) async {
    emit(VendorLoading());
    try {
      final response = await vendorRepo.getVendor(userId);

      if (response.status) {
        emit(GetVendorSuccess(vendorData: response.vendorData));
      } else {
        emit(GetVendorFailure(message: 'No Data Found'));
      }
    } catch (e) {
      emit(GetVendorFailure(message: e.toString()));
    }
  }

  void addVendor({
    required String userId,
    required String vendorName,
    required String vendorEmail,
    required String vendorMobile,
    required String vendorAddress,
    required String createdAt,
  }) async {
    emit(VendorLoading());
    try {
      final response = await vendorRepo.addVendor(
        userId,
        vendorName,
        vendorEmail,
        vendorMobile,
        vendorAddress,
        createdAt,
      );

      if (response.status) {
        emit(AddVendorSuccess(message: response.msg));
      } else {
        emit(AddVendorFailure(message: response.msg));
      }
    } catch (e) {
      emit(AddVendorFailure(message: e.toString()));
    }
  }

  void deleteVendor({required String mobile}) async {
    emit(VendorLoading());
    try {
      final response = await vendorRepo.deleteVendor(mobile);

      if (response.status) {
        emit(DeleteVendorSuccess(message: response.msg));
      } else {
        emit(DeleteVendorFailure(message: response.msg));
      }
    } catch (e) {
      emit(DeleteVendorFailure(message: e.toString()));
    }
  }
}
