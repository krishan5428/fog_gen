import 'package:fire_nex/data/database/app_database.dart';
import 'package:fire_nex/data/repositories/complaint_repo.dart';

class ComplaintViewModel {
  final ComplaintRepository _complaintRepository;

  ComplaintViewModel(this._complaintRepository);

  Future<void> insertComplaint(ComplaintTableCompanion companion) {
    return _complaintRepository.insertComplaint(companion);
  }

  Future<List<ComplaintTableData>> getComplaintByUserId(String userId) {
    return _complaintRepository.getComplaintsByUserId(userId);
  }
}
