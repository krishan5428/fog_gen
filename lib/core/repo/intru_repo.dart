import '../responses/add_intru_no.dart';
import '../responses/delete_intru_response.dart';
import '../responses/intru_list_response.dart';
import '../responses/update_no_response.dart';

abstract class IntruRepo {
  Future<AddIntruNo> addIntruNo1(String userId, String intruNo1);

  Future<IntrusionResponse> getIntrusionNumbers(String userId);

  Future<UpdateNoResponse> updateIntruNo(
    String userId,
    String intruId,
    String number,
    int count,
  );

  Future<DeleteIntruResponse> deleteIntruWRTIntruId(
    String userId,
    String intruId,
  );
}
