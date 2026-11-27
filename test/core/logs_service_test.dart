import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/api/api_client.dart';
import 'package:fog_gen_new/core/repo/logs_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers every request locally; nothing reaches the real server.
class FakeAdapter implements HttpClientAdapter {
  Object? body; // JSON-encodable reply, or null → network error
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    if (body == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<List<Map<String, dynamic>>> fetch() => LogsService().fetchLogs(
  pnlId: '12',
  usrId: '3',
  ipAdd: '1.2.3.4',
  port: '5000',
  rcvrNo: '000000',
  accNo: '999999',
  lineNo: '000000',
  mac: 'mac',
  ver: 'V1',
);

void main() {
  late FakeAdapter adapter;
  late HttpClientAdapter original;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    original = ApiClient.dio.httpClientAdapter;
    adapter = FakeAdapter();
    ApiClient.dio.httpClientAdapter = adapter;
  });
  tearDown(() => ApiClient.dio.httpClientAdapter = original);

  test(
    'success returns the logs, sends user headers and caches them',
    () async {
      adapter.body = {
        'status': true,
        'logs': [
          {'event': 'Fire', 'time': 't1'},
        ],
      };
      final logs = await fetch();
      expect(logs.single['event'], 'Fire');
      expect(adapter.last!.headers['Usr'], '3');
      expect(adapter.last!.path, endsWith('fetch_logs.php'));

      adapter.body = null; // offline now
      expect((await fetch()).single['event'], 'Fire');
    },
  );

  test('status false → empty list, cache untouched', () async {
    adapter.body = {'status': false, 'msg': 'none'};
    expect(await fetch(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('logs_cache_12'), isNull);
  });

  test('offline with no cache → empty list, no throw', () async {
    adapter.body = null;
    expect(await fetch(), isEmpty);
  });
}
