import 'package:dio/dio.dart';
import 'package:fog_gen_new/core/api/web_url_constants.dart';
class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: WebUrlConstants.baseUrl,
      connectTimeout: WebUrlConstants.connectTimeout,
      receiveTimeout: WebUrlConstants.receiveTimeout,
      sendTimeout: WebUrlConstants.sendTimeout,
      headers: {'Usr': '', 'Usr_type': 'USER'},
    ),
  );
}
