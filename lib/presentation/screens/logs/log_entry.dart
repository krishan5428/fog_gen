import 'package:intl/intl.dart';

class LogEntry {
  final String message;
  final DateTime timestamp;

  LogEntry({required this.message, required this.timestamp});

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final rawTime = json["event_time"] ?? "";
    DateTime parsedTime;

    try {
      parsedTime = DateFormat("dd-MM-yyyy HH:mm:ss").parse(rawTime);
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return LogEntry(
      message: json["event_name"] ?? "Unknown Event",
      timestamp: parsedTime,
    );
  }

  // ---------------------------------------------------------------------------
  // NEW: toJson Method
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      "event_name": message,
      "event_time": DateFormat("dd-MM-yyyy HH:mm:ss").format(timestamp),
    };
  }
}