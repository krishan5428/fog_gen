import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/data/pojo/complaint_data.dart';
import '../../../core/repo/complaint_repo.dart';

part 'complaint_state.dart';

class ComplaintCubit extends Cubit<ComplaintState> {
  final ComplaintRepo complaintRepo;
  ComplaintCubit(this.complaintRepo) : super(ComplaintInitial());

  void addComplaint(
    String remark,
    String subject,
    String userId,
    String siteName,
    String? image1Path,
    String? image2Path,
    String? image3Path,
  ) async {
    emit(ComplaintLoading());
    try {
      final response = await complaintRepo.addComplaint(
        remark: remark,
        subject: subject,
        userId: userId,
        siteName: siteName,
        image1Path: image1Path,
        image2Path: image2Path,
        image3Path: image3Path,
      );

      print(
        'Add Complaint response : status=${response.status}, msg =${response.message}',
      );

      if (response.status) {
        emit(AddComplaintSuccess(message: response.message));
      } else {
        emit(
          AddComplaintFailure(
            message:
                response.message.isNotEmpty
                    ? response.message
                    : "Add Complaint failed",
          ),
        );
      }
    } catch (e) {
      emit(AddComplaintFailure(message: e.toString()));
    }
  }

  void getComplaintList({required String userId}) async {
    emit(ComplaintLoading());
    try {
      print('Get Complaint request : userId=$userId');
      final response = await complaintRepo.getComplaintHistory(userId: userId);

      print(
        'Get Complaint response : status=${response.status}, msg =${response.message}, complaints = ${response.complaints}',
      );
      if (response.status) {
        emit(GetComplaintListSuccess(complaintList: response.complaints));
      } else {
        emit(
          GetComplaintListFailure(
            message:
                response.message.isNotEmpty
                    ? response.message
                    : "Failed while retrieving complaints",
          ),
        );
      }
    } catch (e) {
      emit(GetComplaintListFailure(message: "Something went wrong"));
    }
  }
}
