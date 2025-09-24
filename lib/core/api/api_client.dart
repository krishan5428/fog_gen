import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://pc27.in/apps/Securico/app_services/",
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {'Usr': '', 'Usr_type': 'USER'},
    ),
  );
}
