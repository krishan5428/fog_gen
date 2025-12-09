import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../core/data/pojo/panel_data.dart';
import '../../../core/repo/panel_repo.dart';

part 'panel_state.dart';

class PanelCubit extends Cubit<PanelState> {
  final PanelRepo panelRepo;

  PanelCubit(this.panelRepo) : super(PanelInitial());

  void getPanel({required String userId}) async {
    print('▶️ getPanel() called for userId: $userId');
    emit(PanelLoading());
    try {
      print('📡 Calling panelRepo.getPanels...');
      final response = await panelRepo.getPanels(userId);
      print('✅ Response received: ${response.toString()}');

      if (response.status) {
        print('✅ Panels fetched successfully');
        emit(GetPanelsSuccess(panelsData: response.panelsData));
      } else {
        print('⚠️ API responded with failure: ${response.msg}');
        emit(GetPanelsFailure(message: response.msg));
      }
    } catch (e) {
      print('❌ Exception in getPanel(): $e');
      emit(GetPanelsFailure(message: e.toString()));
    }
  }

  void deletePanel({required String userId, required int panelId}) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.deletePanel(userId, panelId);

      if (response.status) {
        emit(DeletePanelsSuccess(msg: 'Panel Deleted Successfully'));
      } else {
        emit(DeletePanelsFailure(message: 'Error while deleting panel'));
      }
    } catch (e) {
      emit(DeletePanelsFailure(message: e.toString()));
      print('Delete Panel error response catch : ${e.toString()}');
    }
  }

  void updateAdminCode({
    required String userId,
    required int panelId,
    required int adminCode,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updateAdminCode(
        userId,
        panelId,
        adminCode,
      );

      if (response.status) {
        // emit(UpdatePanelsSuccess(msg: response.msg));
      } else {
        emit(UpdatePanelsFailure(message: 'Error while updating Admin Code'));
      }
    } catch (e) {
      emit(UpdatePanelsFailure(message: e.toString()));
      print('updateAdminCode error response catch : ${e.toString()}');
    }
  }

  void updatePanelData({
    required String userId,
    required int panelId,
    required String key,
    required String value,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updatePanelData(
        userId,
        panelId,
        key,
        value,
      );
      if (response.status && response.panelData != null) {
        emit(
          UpdatePanelsSuccess(
            msg: response.msg,
            panelData: response.panelData!,
          ),
        );
      } else {
        emit(UpdatePanelsFailure(message: response.msg));
      }
    } catch (e) {
      emit(UpdatePanelsFailure(message: e.toString()));
      print('updatePanelData error response catch : ${e.toString()}');
    }
  }

  void updatePanelDataList({
    required String userId,
    required int panelId,
    required List<String> keys,
    required List<dynamic> values,
  }) async {
    emit(PanelLoading());

    try {
      final response = await panelRepo.updatePanelDataInList(
        userId,
        panelId,
        keys,
        values,
      );

      if (response.status && response.panelData != null) {
        emit(
          UpdatePanelsSuccess(
            msg: response.msg,
            panelData: response.panelData!,
          ),
        );
      } else {
        emit(UpdatePanelsFailure(message: response.msg));
      }
    } catch (e, stackTrace) {
      debugPrint('❌ updatePanelDataList error: $e');
      debugPrint(stackTrace.toString());
      emit(UpdatePanelsFailure(message: e.toString()));
    }
  }

  void updateSiteName({
    required String userId,
    required int panelId,
    required String siteName,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updateSiteName(
        userId,
        panelId,
        siteName,
      );

      if (response.status) {
        // emit(UpdatePanelsSuccess(msg: response.msg));
      } else {
        emit(UpdatePanelsFailure(message: 'Error while updating Site Name'));
      }
    } catch (e) {
      emit(UpdatePanelsFailure(message: e.toString()));
      print('updateSiteName error response catch : ${e.toString()}');
    }
  }

  void updatePanelSimNumber({
    required String userId,
    required int panelId,
    required String panelSimNumber,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updatePanelSimNumber(
        userId,
        panelId,
        panelSimNumber,
      );

      if (response.status) {
        // emit(UpdatePanelsSuccess(msg: response.msg));
      } else {
        emit(
          UpdatePanelsFailure(message: 'Error while updating Panel Sim Number'),
        );
      }
    } catch (e) {
      emit(UpdatePanelsFailure(message: e.toString()));
      print('updatePanelSimNumber error response catch : ${e.toString()}');
    }
  }

  void updateAddress({
    required String userId,
    required int panelId,
    required String address,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updateAddress(userId, panelId, address);

      if (response.status) {
        // emit(UpdatePanelsSuccess(msg: response.msg));
      } else {
        emit(UpdatePanelsFailure(message: 'Error while updating Address'));
      }
    } catch (e) {
      emit(UpdatePanelsFailure(message: e.toString()));
      print('updateAddress error response catch : ${e.toString()}');
    }
  }

  void updateAdminMobileNumber({
    required String userId,
    required int panelId,
    required String adminMobileNumber,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updateAdminMobileNumber(
        userId,
        panelId,
        adminMobileNumber,
      );

      if (response.status) {
        // emit(UpdatePanelsSuccess(msg: response.msg));
      } else {
        emit(UpdatePanelsFailure(message: 'Error while updating Address'));
      }
    } catch (e) {
      emit(UpdatePanelsFailure(message: e.toString()));
      print('updateAdminMobileNumber error response catch : ${e.toString()}');
    }
  }

  void updateSolitareMobileNumber({
    required String userId,
    required int panelId,
    required String mobileNumber,
    required String index,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.updateSolitareMobileNumber(
        userId,
        panelId,
        index,
        mobileNumber,
      );

      debugPrint('updateSolitareMobileNumber status: ${response.status}');

      if (response.status) {
        // emit(UpdatePanelsSuccess(msg: response.msg));
      } else {
        emit(
          UpdatePanelsFailure(message: 'Error while updating Mobile Number'),
        );
      }
    } catch (e) {
      emit(UpdatePanelsFailure(message: e.toString()));
      debugPrint('updateSolitareMobileNumber error: $e');
    }
  }

  void addPanel({
    required String userId,
    required String panelType,
    required String panelName,
    required String site,
    required String panelSimNumber,
    required String adminCode,
    required String adminMobileNumber,
    required String mobileNumberSubId,
    required String mobileNumber1,
    required String mobileNumber2,
    required String mobileNumber3,
    required String mobileNumber4,
    required String mobileNumber5,
    required String mobileNumber6,
    required String mobileNumber7,
    required String mobileNumber8,
    required String mobileNumber9,
    required String mobileNumber10,
    required String address,
    required String cOn,
    required bool is_ip_gsm_panel,
    required bool is_ip_panel,
    required String ip_address,
    required String port_no,
    required String static_ip_address,
    required String static_port_no,
    required String password,
  }) async {
    emit(PanelLoading());
    try {
      final response = await panelRepo.addPanel(
        userId: userId,
        panelType: panelType,
        panelName: panelName,
        site: site,
        panelSimNumber: panelSimNumber,
        adminCode: adminCode,
        adminMobileNumber: adminMobileNumber,
        mobileNumberSubId: mobileNumberSubId,
        mobileNumber1: mobileNumber1,
        mobileNumber2: mobileNumber2,
        mobileNumber3: mobileNumber3,
        mobileNumber4: mobileNumber4,
        mobileNumber5: mobileNumber5,
        mobileNumber6: mobileNumber6,
        mobileNumber7: mobileNumber7,
        mobileNumber8: mobileNumber8,
        mobileNumber9: mobileNumber9,
        mobileNumber10: mobileNumber10,
        address: address,
        cOn: cOn,
        ip_address: ip_address,
        port_no: port_no,
        static_ip_address: static_ip_address,
        static_port_no: static_port_no,
        password: password,
        is_ip_panel: is_ip_panel,
        is_ip_gsm_panel: is_ip_gsm_panel,
      );

      if (response.status) {
        emit(AddPanelSuccess(message: response.msg));
        print(
          'Add Panel response : status=${response.status}, msg=${response.msg}',
        );
      } else {
        emit(
          AddPanelFailure(
            message:
                response.msg.isNotEmpty ? response.msg : "Add Panel failed",
          ),
        );
        print(
          'Add Panel FAILED: status=${response.status}, msg=${response.msg}',
        );
      }
    } catch (e) {
      emit(AddPanelFailure(message: e.toString()));
      print('Add Panel error response catch : ${e.toString()}');
    }
  }
}
