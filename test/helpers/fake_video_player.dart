import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Video platform for tests: every player "initialises" at once with a
/// 10 s, 100x100 video and stays at position 0 (so the splash never
/// auto-navigates).
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int _nextId = 0;
  final Map<int, StreamController<VideoEvent>> _events = {};

  @override
  Future<void> init() async {}

  Future<int> _newPlayer() async {
    final id = _nextId++;
    final c = StreamController<VideoEvent>();
    _events[id] = c;
    c.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        size: const Size(100, 100),
        duration: const Duration(seconds: 10),
      ),
    );
    return id;
  }

  @override
  Future<int?> create(DataSource dataSource) => _newPlayer();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) => _newPlayer();

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async => _events.remove(playerId)?.close();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.shrink();

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}
