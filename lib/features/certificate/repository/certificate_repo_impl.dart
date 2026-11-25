import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:fog_gen_new/core/api/api_client.dart';
import 'package:fog_gen_new/core/api/web_url_constants.dart';
import 'package:fog_gen_new/features/certificate/repository/certificate_repo.dart';
import 'package:fog_gen_new/features/certificate/responses/get_certificate_response.dart';
import 'package:fog_gen_new/core/logging/app_logger.dart';

class CertificateRepoImpl implements CertificateRepo {
  final Dio _dio = ApiClient.dio;

  @override
  Future<GetCertificateResponse> fetchCertificates() async {
    try {
      final response = await _dio.post(WebUrlConstants.mqttCertificatesUrl);
      AppLogger.d("Get Certificate Response status: ${response.statusCode}");
      final data = response.data;
      final json = data is String ? jsonDecode(data) : data;
      return GetCertificateResponse.fromJson(json);
    } on DioException catch (e) {
      AppLogger.d(
        "❌ DioException in fetchCertificates: ${e.message}, ${e.response?.data}",
      );
      return GetCertificateResponse(status: false, msg: _handleDioError(e));
    } catch (e) {
      AppLogger.d("❌ Unexpected error in fetchCertificates: $e");
      return GetCertificateResponse(
        status: false,
        msg: "Unexpected error while fetching certificates.",
      );
    }
  }

  String _handleDioError(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map && responseData['msg'] != null) {
      return responseData['msg'].toString();
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Connection timed out. Please check your internet.";
      case DioExceptionType.badResponse:
        return "Server error: ${e.response?.statusCode}. Please try again later.";
      case DioExceptionType.connectionError:
        return "Server not reachable or no internet. Please check your network.";
      case DioExceptionType.cancel:
        return "Request was cancelled.";
      case DioExceptionType.unknown:
      default:
        return "An unexpected error occurred. Please try again.";
    }
  }
}
