import '../responses/add_fire_no.dart';
import '../responses/delete_fire_response.dart';
import '../responses/fire_list_response.dart';
import '../responses/update_fire_no_response.dart';

abstract class FireRepo {
  Future<AddFireNo> addFireNo1(String userId, String fireNo1);

  Future<FireResponse> getFireNumbers(String userId);

  Future<UpdateFireNoResponse> updateFireNo(
    String userId,
    String fireId,
    String number,
    int count,
  );

  Future<DeleteFireResponse> deleteFireWRTFireId(String userId, String fireId);
}
