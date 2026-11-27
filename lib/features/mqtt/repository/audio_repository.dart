import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import '../models/voice_model.dart';

class AudioRepository {
  static final AudioRepository instance = AudioRepository._internal();
  AudioRepository._internal();

  final _logger = Logger();

  // Every public method below is a full read-modify-write over a single
  // shared JSON file. Without serializing them, two concurrent callers
  // (e.g. the HTTP size sync and an MQTT status sync) can each read a
  // stale snapshot and overwrite each other's changes on save.
  Future<void> _queue = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final previous = _queue;
    final completer = Completer<void>();
    _queue = completer.future;
    return previous.then((_) => action()).whenComplete(completer.complete);
  }

  Future<File> _getMetadataFile() async {
    final docDir = await getApplicationDocumentsDirectory();
    final localDir = Directory("${docDir.path}/fourgcom");
    if (!await localDir.exists()) {
      await localDir.create(recursive: true);
    }
    return File("${localDir.path}/audio_metadata.json");
  }

  Future<List<VoiceModel>> _readAllRaw() async {
    try {
      final file = await _getMetadataFile();
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => VoiceModel.fromJson(e)).toList();
    } catch (e) {
      _logger.e("Error reading audio metadata from file: $e");
      return [];
    }
  }

  Future<void> _writeAllRaw(List<VoiceModel> list) async {
    try {
      final file = await _getMetadataFile();
      final content = jsonEncode(list.map((e) => e.toJson()).toList());
      await file.writeAsString(content);
    } catch (e) {
      _logger.e("Error saving audio metadata to file: $e");
    }
  }

  int _nextId(List<VoiceModel> list) => list.isEmpty
      ? 1
      : list.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;

  Future<List<VoiceModel>> getAllAudio() => _synchronized(() => _readAllRaw());

  Future<void> saveAllAudio(List<VoiceModel> list) =>
      _synchronized(() => _writeAllRaw(list));

  Future<void> addAudio(VoiceModel model) => _synchronized(() async {
    final list = await _readAllRaw();
    final voiceWithId = model.copyWith(id: model.id ?? _nextId(list));
    list.add(voiceWithId);
    await _writeAllRaw(list);
  });

  Future<void> updateAudio(int id, VoiceModel model, String imei) =>
      _synchronized(() async {
        final list = await _readAllRaw();
        final index = list.indexWhere((e) => e.id == id);
        if (index != -1) {
          list[index] = model.copyWith(id: id);
        } else {
          list.add(model.copyWith(id: id));
        }
        await _writeAllRaw(list);
      });

  /// Applies many updates in a single read-modify-write pass instead of one
  /// file rewrite per item, so bulk syncs (30 audio slots) don't do O(n^2) I/O.
  Future<void> updateMany(List<MapEntry<int, VoiceModel>> updates) =>
      _synchronized(() async {
        if (updates.isEmpty) return;
        final list = await _readAllRaw();
        for (final entry in updates) {
          final index = list.indexWhere((e) => e.id == entry.key);
          if (index != -1) {
            list[index] = entry.value.copyWith(id: entry.key);
          } else {
            list.add(entry.value.copyWith(id: entry.key));
          }
        }
        await _writeAllRaw(list);
      });

  /// Atomically drops any existing rows for [imei] and inserts [models] in
  /// their place, in a single read-modify-write. Used for the initial 30-slot
  /// seed so stale/duplicate rows never accumulate across app launches.
  Future<void> replaceAudioForImei(String imei, List<VoiceModel> models) =>
      _synchronized(() async {
        final list = await _readAllRaw();
        list.removeWhere((e) => e.imei == imei);
        int nextId = _nextId(list);
        for (final m in models) {
          list.add(m.copyWith(id: m.id ?? nextId++));
        }
        await _writeAllRaw(list);
      });

  Future<void> deleteAllAudio() => _synchronized(() async {
    try {
      final file = await _getMetadataFile();
      if (await file.exists()) {
        await file.writeAsString("[]");
      }
    } catch (e) {
      _logger.e("Error deleting audio metadata file: $e");
    }
  });
}
