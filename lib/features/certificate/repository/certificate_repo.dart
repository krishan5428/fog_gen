import 'package:fog_gen_new/features/certificate/responses/get_certificate_response.dart';

abstract class CertificateRepo {
  Future<GetCertificateResponse> fetchCertificates();
}
