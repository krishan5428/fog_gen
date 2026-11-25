import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/responses/socket_repository.dart';
import 'package:fog_gen_new/core/utils/application_class.dart';

/// A local stand-in for the SR1 panel on 127.0.0.1.
class FakePanel {
  FakePanel._(this._server, this.reply);
  final ServerSocket _server;
  final String? reply; // null → accept but never answer
  final List<String> received = [];

  static Future<FakePanel> start({String? reply}) async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final p = FakePanel._(s, reply);
    s.listen((c) {
      c.done.catchError((_) => c);
      c.listen((data) {
        p.received.add(utf8.decode(data));
        if (p.reply != null) c.write(p.reply);
      }, onError: (_) {});
    });
    return p;
  }

  int get port => _server.port;
  Future<void> close() => _server.close();
}

/// A port with nothing listening on it (connection refused).
Future<int> closedPort() async {
  final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = s.port;
  await s.close();
  return port;
}

void main() {
  final app = Application();
  final panels = <FakePanel>[];

  Future<FakePanel> panel({String? reply}) async {
    final p = await FakePanel.start(reply: reply);
    panels.add(p);
    return p;
  }

  setUp(() {
    app
      ..mPassword = '1234'
      ..mIPAddress = null
      ..mPortNumber = null
      ..mStaticIPAddress = null
      ..mStaticPortNumber = null;
  });

  tearDown(() async {
    for (final p in panels) {
      await p.close();
    }
    panels.clear();
  });

  test('sends the packet to the local IP and returns the reply', () async {
    final p = await panel(reply: 'S*1234#R#007#0*E');
    app
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = p.port;

    final r = await SocketRepository().sendPacketSR1('S*1234#R#007#001*E');

    expect(r, 'S*1234#R#007#0*E');
    expect(p.received, ['S*1234#R#007#001*E']);
  });

  test('tries the static IP first', () async {
    final stat = await panel(reply: 'STATIC');
    final local = await panel(reply: 'LOCAL');
    app
      ..mStaticIPAddress = '127.0.0.1'
      ..mStaticPortNumber = stat.port
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = local.port;

    expect(await SocketRepository().sendPacketSR1('S*1234#R#000#1*E'), 'STATIC');
    expect(local.received, isEmpty);
  });

  test('static IP refused → falls back to the local IP', () async {
    final local = await panel(reply: 'LOCAL');
    app
      ..mStaticIPAddress = '127.0.0.1'
      ..mStaticPortNumber = await closedPort()
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = local.port;

    expect(await SocketRepository().sendPacketSR1('S*1234#R#000#1*E'), 'LOCAL');
  });

  test('static IP connects but never answers → falls back to the local IP',
      () async {
    final silent = await panel();
    final local = await panel(reply: 'LOCAL');
    app
      ..mStaticIPAddress = '127.0.0.1'
      ..mStaticPortNumber = silent.port
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = local.port;

    expect(await SocketRepository().sendPacketSR1('S*1234#R#000#1*E'), 'LOCAL');
    expect(local.received, hasLength(1));
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('no reachable target → error, queue keeps working after it', () async {
    app
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = await closedPort();
    final repo = SocketRepository();

    await expectLater(
      repo.sendPacketSR1('S*1234#R#000#1*E'),
      throwsA(isA<Exception>()),
    );

    final p = await panel(reply: 'OK');
    app.mPortNumber = p.port;
    expect(await repo.sendPacketSR1('S*1234#R#000#1*E'), 'OK');
  });

  test('requests are sent one at a time, in order', () async {
    final p = await panel(reply: 'OK');
    app
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = p.port;
    final repo = SocketRepository();

    final results = await Future.wait([
      repo.sendPacketSR1('S*1234#R#001*E'),
      repo.sendPacketSR1('S*1234#R#002*E'),
      repo.sendPacketSR1('S*1234#R#003*E'),
    ]);

    expect(results, ['OK', 'OK', 'OK']);
    expect(p.received, ['S*1234#R#001*E', 'S*1234#R#002*E', 'S*1234#R#003*E']);
  });

  test('a priority packet jumps ahead of queued normal packets', () async {
    final p = await panel(reply: 'OK');
    app
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = p.port;
    final repo = SocketRepository();

    final f = [
      repo.sendPacketSR1('S*1234#R#001*E'), // starts at once
      repo.sendPacketSR1('S*1234#R#002*E'),
      repo.sendPacketSR1('S*1234#W#009*E', isPriority: true),
    ];
    await Future.wait(f);

    expect(p.received, [
      'S*1234#R#001*E',
      'S*1234#W#009*E',
      'S*1234#R#002*E',
    ]);
  });

  test('stopAllActivity cancels queued requests and refuses new ones',
      () async {
    final p = await panel();
    app
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = p.port;
    final repo = SocketRepository();

    final first = repo.sendPacketSR1('S*1234#R#001*E');
    final queued = repo.sendPacketSR1('S*1234#R#002*E');
    first.catchError((_) => '');
    repo.stopAllActivity();

    await expectLater(queued, throwsA(contains('cancelled')));
    await expectLater(
      repo.sendPacketSR1('S*1234#R#003*E'),
      throwsA(isA<Exception>()),
    );
    expect(repo.queueSize, 0);
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('disconnect packet goes out directly', () async {
    final p = await panel();
    app
      ..mIPAddress = '127.0.0.1'
      ..mPortNumber = p.port;

    await SocketRepository().sendDisconnectPacket();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(p.received, ['S*1234#W#013*E']);
  });
}
