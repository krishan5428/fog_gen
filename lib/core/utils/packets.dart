import 'application_class.dart';

class Packets {
  Packets._();

  static final _app = Application();

  static const String start = "S";
  static const String packetSplitChar = "*";
  static const String splitChar = "#";
  static const String end = "E";
  static const String read = "R";
  static const String write = "W";
  static const String disconnectionCode = "013";

  static String getPacket({
    required bool isReadPacket,
    required List<String> args,
  }) {
    final packetType = isReadPacket ? read : write;

    final packet = StringBuffer();
    for (var temp in args) {
      if (temp.isNotEmpty) {
        packet.write(temp);
        packet.write("#");
      }
    }

    String packetContent = packet.toString();
    if (packetContent.endsWith("#")) {
      packetContent = packetContent.substring(0, packetContent.length - 1);
    }

    return "$start$packetSplitChar${_app.mPassword}$splitChar$packetType$splitChar$packetContent$packetSplitChar$end";
  }

  static String connectPacket() {
    return "$start$packetSplitChar${_app.mPassword}$splitChar$read${splitChar}000${splitChar}1$packetSplitChar$end";
  }

  static String disconnectPacket() {
    return "$start$packetSplitChar${_app.mPassword}$splitChar$write$splitChar$disconnectionCode$packetSplitChar$end";
  }

  static String getPacketId(String packet) {
    try {
      final parts = packet.split('*');
      if (parts.length > 1) {
        final mainPart = parts[1];
        final mainParts = mainPart.split('#');
        if (mainParts.length > 2) {
          return mainParts[2];
        }
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  static List<String> splitPacket(String packet) {
    try {
      final parts = packet.split('*');
      if (parts.length > 1) {
        final mainPart = parts[1];
        return mainPart.split('#').sublist(1);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static List<String> splitOutputPacket(String packet) {
    return splitPacket(packet);
  }
}
