// ignore_for_file: use_build_context_synchronously
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:toastification/toastification.dart';

import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:fog_gen_new/features/mqtt/repository/fourg_repository.dart';
import 'package:fog_gen_new/features/mqtt/repository/audio_repository.dart';
import 'package:fog_gen_new/features/mqtt/models/voice_model.dart';
import 'package:fog_gen_new/presentation/dialog/progress.dart';
import 'package:fog_gen_new/constants/app_colors.dart';
import 'package:fog_gen_new/presentation/widgets/app_bar.dart';

class FourGMqttAudioSettingsScreen extends StatefulWidget {
  final PanelData panelData;
  final FourGRepository fourGRepository;

  const FourGMqttAudioSettingsScreen({
    super.key,
    required this.panelData,
    required this.fourGRepository,
  });

  @override
  State<FourGMqttAudioSettingsScreen> createState() =>
      _FourGMqttAudioSettingsScreenState();
}

class _FourGMqttAudioSettingsScreenState
    extends State<FourGMqttAudioSettingsScreen> {
  final _logger = Logger();
  final AudioRepository _audioRepo = AudioRepository.instance;
  AudioPlayer? _audioPlayer;

  List<VoiceModel> _audioItems = [];
  List<String> _deviceStatuses = List.filled(30, "0");
  final Set<int> _selectedIndices = {};
  String? _selectedFilePath;

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDownloading = false;

  int? _playingIndex;
  StreamSubscription? _mqttSubscription;
  Timer? _pollingTimer;
  Timer? _downloadAckTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed && mounted) {
        setState(() {
          _playingIndex = null;
        });
      }
    });

    _mqttSubscription = widget
        .fourGRepository
        .mqttService
        .mqttRepository
        .messageStream
        .listen(_onMqttMessage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _downloadAckTimer?.cancel();
    _mqttSubscription?.cancel();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _showToast(
    String message, {
    ToastificationType type = ToastificationType.info,
  }) {
    if (!mounted) return;
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.fillColored,
      alignment: Alignment.bottomCenter,
      title: Text(
        type == ToastificationType.success ? 'Success' : 'Notification',
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
        ),
      ),
      description: Text(
        message,
        style: const TextStyle(fontFamily: 'Montserrat'),
      ),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final dbList = await _audioRepo.getAllAudio();
      final imei = widget.panelData.panelImei;

      // Filter local items by IMEI to make it multi-panel safe
      final currentPanelList = dbList.where((e) => e.imei == imei).toList();

      if (currentPanelList.isEmpty || currentPanelList.length < 30) {
        // Not initialized (or a stale/partial set): replace this panel's
        // slots atomically in one write instead of 30 sequential ones,
        // which also clears out any stale/duplicate rows from a previous run.
        final freshItems = List.generate(30, (i) {
          final voiceNoStr = "AUDIO_${(i + 1).toString().padLeft(2, '0')}.amr";
          return VoiceModel(
            imei: imei,
            voiceNo: voiceNoStr,
            voiceSize: "0",
            isActive: 0,
            isDevice: 0,
            path: "",
            sizeBool: "0",
          );
        });
        await _audioRepo.replaceAudioForImei(imei, freshItems);
      }

      // Don't publish the un-enriched placeholder list here: it would flip
      // `_audioItems.isEmpty` to false and hide the loading spinner before
      // sizes/status are known, showing "No local file" for everything.
      // _fetchVoicesHttp() below is the single point that sets _audioItems.
      await _fetchVoicesHttp();
      _publishStatusRequest();
    } catch (e) {
      _logger.e("Error initializing audio data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMqttMessage(String payload) {
    if (!mounted || payload.isEmpty) return;
    final splitData = payload.split('\$');
    if (splitData.length < 5) return;

    final imei = widget.panelData.panelImei;
    if (!splitData[0].startsWith("ST*") || splitData[0].substring(3) != imei) {
      return;
    }

    if (splitData[2] == '00') {
      if (_isDownloading) {
        setState(() {
          _isDownloading = false;
        });
        _showToast(
          "Download rejected by device.",
          type: ToastificationType.error,
        );
      }
      return;
    }

    if (splitData[4] != "009") return;

    // 03 = Read Response
    if (splitData[2] == "03" && splitData[3] == "01") {
      final statusPart = splitData[5].split('*')[0];
      final audioMask = statusPart.split("");
      final List<String> validHexes = audioMask
          .where((c) => c.isNotEmpty)
          .toList();

      if (validHexes.length >= 30) {
        _syncLocalItemsWithHexData(validHexes.sublist(0, 30));
      }
    }

    // 04 = Write Response
    if (splitData[2] == "04") {
      _downloadAckTimer?.cancel();
      // Response status type 04 is Processing
      if (splitData[3] == "04" || splitData[3] == "01") {
        _showToast(
          "Download Processing Started",
          type: ToastificationType.info,
        );
        _pollingTimer?.cancel();
        _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _publishStatusRequest();
        });
      }
    }
  }

  Future<void> _publishStatusRequest() async {
    try {
      // Response, if any, is applied via _onMqttMessage on the shared
      // stream — this return value only tells us whether it timed out.
      final response = await widget.fourGRepository.readAudioStatus(
        imei: widget.panelData.panelImei,
        passcode: widget.panelData.pass,
      );
      if (response == null) {
        _showToast(
          "Read Timeout: Could not read audio status from device.",
          type: ToastificationType.error,
        );
      }
    } catch (e) {
      _logger.w("Failed to publish read request: $e");
      _showToast(
        "Failed to read audio status from device.",
        type: ToastificationType.error,
      );
    }
  }

  void _syncLocalItemsWithHexData(List<String> hexData) async {
    final List<VoiceModel> updatedItems = [];
    final List<MapEntry<int, VoiceModel>> updates = [];

    for (int i = 0; i < _audioItems.length && i < 30; i++) {
      final current = _audioItems[i];
      final newStatus = int.parse(hexData[i]);
      final updated = current.copyWith(isActive: newStatus);

      if (current.id != null) {
        updates.add(MapEntry(current.id!, updated));
      }
      updatedItems.add(updated);
    }

    // Single read-modify-write for all 30 slots instead of one file
    // rewrite per slot.
    if (updates.isNotEmpty) {
      await _audioRepo.updateMany(updates);
    }

    if (mounted) {
      setState(() {
        _audioItems = updatedItems;
        _deviceStatuses = hexData;
      });

      // If we are currently downloading, check if active download/in-queue tasks exist
      final activeWork = hexData.contains("2") || hexData.contains("3");
      if (!activeWork && _isDownloading) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
        setState(() {
          _isDownloading = false;
        });
        _showToast(
          "Downloads Completed Successfully!",
          type: ToastificationType.success,
        );
        _initializeData();
      }
    }
  }

  Future<void> _fetchVoicesHttp() async {
    final dio = Dio();
    final imei = widget.panelData.panelImei;
    try {
      final response = await dio.get(
        "http://devicecloudlink.com:6001/api/docFile/macId/$imei/GetFiles",
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        final dbList = await _audioRepo.getAllAudio();
        final currentPanelList = dbList.where((e) => e.imei == imei).toList();
        final List<MapEntry<int, VoiceModel>> updates = [];
        final List<VoiceModel> newRows = [];

        for (final element in data) {
          // Isolate each cloud entry: one malformed/unexpected record (e.g.
          // not a map, or missing fields) must not abort matching for the
          // rest of the list, which would leave every later slot unsynced.
          try {
            if (element is! Map) continue;
            final voiceNo = element["filename"]?.toString();
            if (voiceNo == null || voiceNo.isEmpty) continue;

            final match = currentPanelList
                .where((e) => e.voiceNo == voiceNo)
                .toList();

            if (match.isNotEmpty) {
              final existing = match.first;
              if (existing.id != null) {
                updates.add(
                  MapEntry(
                    existing.id!,
                    existing.copyWith(
                      voiceSize: (element["filesize"] ?? "0").toString(),
                      isDevice: 1,
                    ),
                  ),
                );
              }
            } else {
              // Cloud knows about a file that doesn't match any of the 30
              // seeded slots (e.g. uploaded under a name outside the normal
              // convention) — surface it instead of silently dropping it.
              newRows.add(
                VoiceModel(
                  imei: imei,
                  voiceNo: voiceNo,
                  voiceSize: (element["filesize"] ?? "0").toString(),
                  isActive: 0,
                  isDevice: 1,
                  path: "",
                  sizeBool: "0",
                ),
              );
            }
          } catch (e) {
            _logger.w("Skipping malformed cloud file entry: $element - $e");
          }
        }

        // Single read-modify-write for all matched slots instead of one
        // file rewrite per slot.
        if (updates.isNotEmpty) {
          await _audioRepo.updateMany(updates);
        }
        for (final row in newRows) {
          await _audioRepo.addAudio(row);
        }
      }
    } catch (e) {
      _logger.e("Dio error fetching voices list from HTTP cloud: $e");
    } finally {
      final dbList = await _audioRepo.getAllAudio();
      if (mounted) {
        setState(() {
          _audioItems = dbList.where((e) => e.imei == imei).toList();
        });
      }
    }
  }

  Future<void> _playAudio(int index, String path) async {
    if (_playingIndex == index) {
      await _audioPlayer?.stop();
      setState(() => _playingIndex = null);
      return;
    }

    setState(() {
      _playingIndex = index;
    });

    try {
      String localFilePath = path;
      bool isRemote = path.startsWith("http");

      // Verify local file exists, else fallback to downloading from cloud
      if (!isRemote) {
        final localFile = File(path);
        if (!await localFile.exists()) {
          isRemote = true;
          // Construct fallback remote URL
          path =
              "http://devicecloudlink.com:6001/uploads/${widget.panelData.panelImei}/${_audioItems[index].voiceNo}";
        }
      }

      // Handle remote file downloading to local cache first
      if (isRemote) {
        ProgressDialog.show(context, message: "Caching cloud audio...");
        final dio = Dio();
        final docDir = await getApplicationDocumentsDirectory();
        final imei = widget.panelData.panelImei;
        final localDir = "${docDir.path}/fourgcom/$imei";
        await Directory(localDir).create(recursive: true);

        final filename = path.split('/').last;
        final targetPath = "$localDir/$filename";

        bool downloadSuccess = false;
        final candidateUrls = [
          path,
          "http://devicecloudlink.com:6001/uploads/$imei/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/uploads/macId/$imei/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/uploads/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/api/docFile/macId/$imei/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/api/docFile/macId/$imei/file/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/api/docFile/macId/$imei/download/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/api/docFile/download/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/api/docFile/file/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/api/uploads/$imei/${_audioItems[index].voiceNo}",
          "http://devicecloudlink.com:6001/api/uploads/${_audioItems[index].voiceNo}",
        ];

        for (final url in candidateUrls.toSet()) {
          try {
            _logger.d("Attempting cloud download: $url");
            await dio.download(url, targetPath);
            localFilePath = targetPath;
            downloadSuccess = true;

            // Save cached local path to JSON repository
            final item = _audioItems[index];
            if (item.id != null) {
              await _audioRepo.updateAudio(
                item.id!,
                item.copyWith(path: targetPath),
                imei,
              );
            }
            _logger.d("Cached cloud audio successfully to: $targetPath");
            break;
          } catch (e) {
            _logger.w("Failed download from: $url - Error: $e");
          }
        }

        ProgressDialog.dismiss(context);
        if (!downloadSuccess) {
          throw Exception("Failed to cache remote audio file.");
        }
      }

      await _audioPlayer!.stop();
      _logger.d("Playing audio: $localFilePath");
      await _audioPlayer!.play(DeviceFileSource(localFilePath));
    } catch (e) {
      if (mounted) ProgressDialog.dismiss(context);
      _showToast("Playback error: $e", type: ToastificationType.error);
      setState(() => _playingIndex = null);
    }
  }

  Future<void> _pickAudioFile(int index) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['amr', 'mp3', 'wav', 'm4a'],
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        setState(() {
          _selectedFilePath = result.files.first.path!;
        });
      }
    } catch (e) {
      _showToast("File selection failed: $e", type: ToastificationType.error);
    }
  }

  Future<void> _confirmAudioSelection(int index) async {
    if (_selectedFilePath == null || _selectedFilePath!.isEmpty) return;

    final targetItem = _audioItems[index];
    final String targetVoiceNo = targetItem.voiceNo;

    setState(() => _isLoading = true);
    ProgressDialog.show(context, message: "Saving local audio...");

    try {
      final sourceFile = File(_selectedFilePath!);
      if (await sourceFile.exists()) {
        final dir = await getApplicationDocumentsDirectory();
        final imei = widget.panelData.panelImei;
        final localDir = "${dir.path}/fourgcom/$imei";
        await Directory(localDir).create(recursive: true);

        final destPath = "$localDir/$targetVoiceNo";
        await sourceFile.copy(destPath);
        final copiedFile = File(destPath);

        final updated = targetItem.copyWith(
          voiceSize: copiedFile.lengthSync().toString(),
          path: destPath,
          sizeBool: "1",
        );

        if (targetItem.id != null) {
          await _audioRepo.updateAudio(targetItem.id!, updated, imei);
        }

        _showToast(
          "Audio slot updated locally.",
          type: ToastificationType.success,
        );
        setState(() {
          _selectedFilePath = null;
        });
      }
    } catch (e) {
      _showToast(
        "Failed to save audio file: $e",
        type: ToastificationType.error,
      );
    } finally {
      ProgressDialog.dismiss(context);
      _initializeData();
    }
  }

  Future<void> _startUploads() async {
    if (_selectedIndices.isEmpty) {
      _showToast(
        "Select audio files to upload first.",
        type: ToastificationType.warning,
      );
      return;
    }

    setState(() => _isUploading = true);
    ProgressDialog.show(
      context,
      message: "Uploading selected files to server...",
    );

    final dio = Dio();
    final imei = widget.panelData.panelImei;
    int successCount = 0;

    try {
      for (final index in _selectedIndices) {
        if (index >= _audioItems.length) continue;
        final target = _audioItems[index];

        if (target.path.isNotEmpty) {
          final file = File(target.path);
          if (await file.exists()) {
            final formData = FormData.fromMap({
              'file': await MultipartFile.fromFile(
                file.path,
                filename: file.path.split("/").last,
              ),
            });

            final response = await dio.post(
              "http://devicecloudlink.com:6001/api/docFile/macId/$imei",
              data: formData,
            );

            if (response.statusCode == 200 && target.id != null) {
              successCount++;
              await _audioRepo.updateAudio(
                target.id!,
                target.copyWith(isDevice: 1),
                imei,
              );
            }
          }
        }
      }

      _showToast(
        "Uploaded $successCount files successfully.",
        type: ToastificationType.success,
      );
      setState(() {
        _selectedIndices.clear();
      });
      await _fetchVoicesHttp();
    } catch (e) {
      _showToast("Cloud upload failed: $e", type: ToastificationType.error);
    } finally {
      ProgressDialog.dismiss(context);
      setState(() => _isUploading = false);
    }
  }

  Future<void> _startDownloads() async {
    if (_selectedIndices.isEmpty) {
      _showToast(
        "Select audio files to download to device.",
        type: ToastificationType.warning,
      );
      return;
    }

    setState(() => _isDownloading = true);
    ProgressDialog.show(context, message: "Initiating device downloads...");

    final downloadMaskList = List<String>.filled(30, "0");
    for (final index in _selectedIndices) {
      if (index >= _audioItems.length) continue;
      final target = _audioItems[index];
      final voiceNo = target.voiceNo;

      if (voiceNo.contains("_")) {
        final slotIndex =
            int.tryParse(voiceNo.split("_")[1].split(".")[0]) ?? 0;
        if (slotIndex >= 1 && slotIndex <= 30) {
          downloadMaskList[slotIndex - 1] = "1";
        }
      }
    }

    final downloadMask = downloadMaskList.join("");

    try {
      final response = await widget.fourGRepository.writeAudioDownload(
        imei: widget.panelData.panelImei,
        passcode: widget.panelData.pass,
        downloadMask: downloadMask,
      );

      if (response != null) {
        _showToast(
          "Download command accepted.",
          type: ToastificationType.success,
        );
        setState(() {
          _selectedIndices.clear();
        });

        // Set safety timer
        _downloadAckTimer?.cancel();
        _downloadAckTimer = Timer(const Duration(seconds: 15), () {
          if (mounted && _isDownloading) {
            setState(() {
              _isDownloading = false;
            });
            _showToast(
              "Device did not respond in time.",
              type: ToastificationType.error,
            );
          }
        });
      } else {
        setState(() => _isDownloading = false);
        _showToast(
          "Device timed out or rejected request.",
          type: ToastificationType.error,
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      _showToast("MQTT write error: $e", type: ToastificationType.error);
    } finally {
      ProgressDialog.dismiss(context);
    }
  }

  void _showAddAudioSheet(int index, VoiceModel item) {
    final voiceNo = item.voiceNo;
    final slotNo = voiceNo.contains("_")
        ? voiceNo.split("_")[1].split(".")[0]
        : "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isPreviewPlaying = _playingIndex == -1;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Add Audio File",
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Audio No. $slotNo",
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    await _pickAudioFile(index);
                    setSheetState(() {});
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedFilePath != null
                            ? AppColors.colorPrimary
                            : const Color(0xFFE5E7EB),
                        width: _selectedFilePath != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedFilePath != null
                              ? Icons.audio_file_rounded
                              : Icons.folder_open_rounded,
                          color: _selectedFilePath != null
                              ? AppColors.colorPrimary
                              : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedFilePath != null
                                ? _selectedFilePath!.split("/").last
                                : "Browse audio file",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: _selectedFilePath != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedFilePath != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedFilePath != null)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedFilePath != null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPreviewPlaying
                            ? Colors.red
                            : AppColors.colorPrimary,
                        side: BorderSide(
                          color: isPreviewPlaying
                              ? Colors.red
                              : AppColors.colorPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (isPreviewPlaying) {
                          await _audioPlayer?.stop();
                          setState(() {
                            _playingIndex = null;
                          });
                        } else {
                          await _playAudio(-1, _selectedFilePath!);
                        }
                        setSheetState(() {});
                      },
                      icon: Icon(
                        isPreviewPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      label: Text(
                        isPreviewPlaying ? "Stop Preview" : "Preview Audio",
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFilePath != null
                          ? AppColors.colorPrimary
                          : const Color(0xFFE5E7EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _selectedFilePath != null
                        ? () {
                            _audioPlayer?.stop();
                            _confirmAudioSelection(index);
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      "Confirm",
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: _selectedFilePath != null
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getFileSizeDisplay(String sizeBytesStr) {
    final bytes = int.tryParse(sizeBytesStr) ?? 0;
    if (bytes == 0) return "No local file";
    return "${(bytes / 1024).toStringAsFixed(1)} KB";
  }

  Widget _getStatusPill(VoiceModel item, String? statusCode) {
    if (item.isDevice == 1 && item.isActive == 0) {
      return _buildPill(
        "Uploaded",
        const Color(0xFFDCFCE7),
        const Color(0xFF16A34A),
      );
    }
    // A download/queue/failed status is only meaningful once the cloud has
    // a known copy of the file (voiceSize != "0") — a slot can't genuinely
    // be mid-download to the panel if it was never uploaded from here.
    final hasKnownSize = item.voiceSize != "0";
    if (item.isActive != 0 && hasKnownSize && statusCode != null) {
      switch (statusCode) {
        case "1":
          return _buildPill(
            "Downloaded",
            const Color(0xFFDCFCE7),
            const Color(0xFF16A34A),
          );
        case "2":
          return _buildPill(
            "Downloading",
            const Color(0xFFFEF9C3),
            const Color(0xFFCA8A04),
          );
        case "3":
          return _buildPill(
            "In Queue",
            const Color(0xFFFEF9C3),
            const Color(0xFFCA8A04),
          );
        case "9":
          return _buildPill(
            "Failed",
            const Color(0xFFFEE2E2),
            const Color(0xFFDC2626),
          );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildPill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isLoading || _isUploading || _isDownloading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          pageName: "Audio List",
          isFilter: false,
          isDash: false,
          onBack: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _audioItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: _audioItems.length,
                    itemBuilder: (context, index) {
                      final item = _audioItems[index];
                      final statusCode = index < _deviceStatuses.length
                          ? _deviceStatuses[index]
                          : null;
                      final hasFile =
                          item.voiceSize != "0" ||
                          item.path.isNotEmpty ||
                          item.isDevice == 1 ||
                          statusCode == "1";
                      final isSelected = _selectedIndices.contains(index);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: isBusy
                              ? null
                              : () => _showAddAudioSheet(index, item),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: isBusy || !hasFile
                                        ? null
                                        : (val) {
                                            setState(() {
                                              if (val == true) {
                                                if (_selectedIndices.length >=
                                                    5) {
                                                  _showToast(
                                                    "Select up to 5 files maximum.",
                                                    type: ToastificationType
                                                        .warning,
                                                  );
                                                  return;
                                                }
                                                _selectedIndices.add(index);
                                              } else {
                                                _selectedIndices.remove(index);
                                              }
                                            });
                                          },
                                    activeColor: AppColors.colorPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECEFF1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.audiotrack_rounded,
                                    color: hasFile
                                        ? AppColors.colorPrimary
                                        : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.voiceNo,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getFileSizeDisplay(item.voiceSize),
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: hasFile
                                              ? Colors.grey.shade600
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _getStatusPill(item, statusCode),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.colorPrimary,
                          side: const BorderSide(color: AppColors.colorPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isBusy ? null : _startUploads,
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text(
                          "Upload to Cloud",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.colorPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isBusy ? null : _startDownloads,
                        icon: const Icon(Icons.downloading_rounded, size: 18),
                        label: const Text(
                          "Download to Device",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
