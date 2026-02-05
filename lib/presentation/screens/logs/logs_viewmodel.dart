import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fog_gen_new/core/data/pojo/panel_data.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../core/repo/logs_service.dart';
import 'auto_open_dialog.dart';
import 'log_entry.dart';

enum LogsState { loading, success, empty, error }

final _log = Logger(printer: PrettyPrinter(methodCount: 2));

class LogsViewModel extends ChangeNotifier {
  final LogsService _logsService;
  final PanelData _panelData;

  LogsViewModel({
    required LogsService logsService,
    required PanelData panelData,
  })  : _logsService = logsService,
        _panelData = panelData {
    fetchLogs();
  }

  LogsState _state = LogsState.loading;
  LogsState get state => _state;

  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => _logs;

  Future<void> fetchLogs() async {
    _state = LogsState.loading;
    notifyListeners();
    try {
      final rawList = await _logsService.fetchLogs(
        pnlId: _panelData.pnlId.toString(),
        usrId: _panelData.usrId.toString(),
        // Ensure these fields exist in your PanelData model
        ipAdd: _panelData.ipAdd ?? "",
        port: _panelData.portNo ?? "",
        rcvrNo: _panelData.pnlRcvrNo ?? "",
        accNo: _panelData.pnlAccNo ?? "",
        lineNo: _panelData.pnlLineNo ?? "",
        mac: _panelData.pnlMac ?? "",
        ver: _panelData.pnlVer ?? "",
      );

      if (rawList.isEmpty) {
        _state = LogsState.empty;
      } else {
        _logs
          ..clear()
          ..addAll(rawList.map((e) => LogEntry.fromJson(e)));
        _state = LogsState.success;
      }
    } catch (e) {
      _state = LogsState.error;
    }
    notifyListeners();
  }

  Future<void> exportPdf(BuildContext context) async {
    if (_logs.isEmpty) {
      _log.i("No logs available to export. Exiting.");
      return;
    }

    // 1. CHECK PERMISSIONS (Android only)
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 29) {
        _log.i("Android <= 29 detected, requesting storage permission...");
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          if (context.mounted) _showToast(context, "Permission required.");
          _log.w("Storage permission denied. Cannot export.");
          return;
        }
        _log.i("Storage permission granted.");
      } else {
        _log.i(
            "Android >= 30 detected, no explicit storage permission required.");
      }
    }

    try {
      // 2. GENERATE PDF
      _log.i("Generating PDF document...");
      final doc = pw.Document();
      final font = await PdfGoogleFonts.montserratRegular();
      final fontBold = await PdfGoogleFonts.montserratBold();
      final timeFormatter = DateFormat("hh:mm:ss a");
      final dateFormatter = DateFormat("MMM dd, yyyy");

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          build: (pw.Context context) => [
            pw.Header(level: 0, child: pw.Text("Panel Logs")),
            pw.Table.fromTextArray(
              headers: ['Alert Name', 'Time', 'Date'],
              data: _logs
                  .map((log) => [
                        log.message,
                        timeFormatter.format(log.timestamp),
                        dateFormatter.format(log.timestamp)
                      ])
                  .toList(),
            ),
          ],
        ),
      );

      final pdfBytes = await doc.save();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = "logs_$timestamp.pdf";
      _log.i("PDF generated, filename: $fileName");

      // 3. SAVE
      String? publicPath;

      if (Platform.isAndroid) {
        _log.i("Saving on Android...");
        final root = Directory('/storage/emulated/0/Documents');
        final exportDir = Directory('${root.path}/fogshield/logs');
        _log.i("Android export directory: ${exportDir.path}");

        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
          _log.i("Created Android directory: ${exportDir.path}");
        }

        final exportFile = File("${exportDir.path}/$fileName");
        await exportFile.writeAsBytes(pdfBytes);
        publicPath = exportFile.path;

        _log.i("PDF saved on Android at: $publicPath");
      }

      if (Platform.isIOS) {
        _log.i("Saving on iOS...");
        final appDocDir = await getApplicationDocumentsDirectory();
        _log.i("Base iOS app documents directory: ${appDocDir.path}");

        final exportDir = Directory('${appDocDir.path}/fogshield/logs');
        _log.i("iOS export path: ${exportDir.path}");

        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
          _log.i("Created iOS directory: ${exportDir.path}");
        } else {
          _log.i("iOS directory already exists.");
        }

        final exportFile = File("${exportDir.path}/$fileName");
        await exportFile.writeAsBytes(pdfBytes);
        publicPath = exportFile.path;

        _log.i("PDF saved on iOS at: $publicPath");
        _log.i(
            "User can find it in Files > On My iPhone > <App Name> > fogshield/logs");
      }

      if (context.mounted) {
        _showToast(context, "Saved to: $publicPath");
      }

      // 4. COUNTDOWN / AUTO-OPEN DIALOG
      if (!context.mounted) return;
      _log.i("Showing countdown dialog for auto-open...");
      final bool shouldOpen = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AutoOpenDialog(),
          ) ??
          false;
      _log.i("Dialog result -> shouldOpen: $shouldOpen");

      // 5. OPEN FILE
      if (shouldOpen) {
        _log.i("Preparing temp file to open...");
        final tempDir = await getTemporaryDirectory();
        final tempFile = File("${tempDir.path}/$fileName");
        await tempFile.writeAsBytes(pdfBytes);

        _log.i("Opening file from temp: ${tempFile.path}");
        final result = await OpenFilex.open(tempFile.path);

        if (result.type != ResultType.done) {
          _log.w("Viewer could not open file: ${result.type}");
          if (!context.mounted) return;
          _showToast(context, "Could not open viewer: ${result.type}");
        } else {
          _log.i("File opened successfully.");
        }
      } else {
        _log.i("User cancelled opening. Export complete.");
      }
    } catch (e) {
      _log.e("PDF Export Error: $e");
      if (context.mounted) _showToast(context, "Error: $e");
    }
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }
}
