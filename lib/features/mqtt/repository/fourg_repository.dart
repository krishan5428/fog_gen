import '../models/input_settings.dart';
import '../services/fourg_mqtt_parser.dart';
import '../services/fourg_mqtt_service.dart';

class FourGRepository {
  final FourGMqttService mqttService;

  FourGRepository(this.mqttService);

  Future<bool> connectPanel({required String imei, required String passcode}) {
    return mqttService.connectAndHandshake(imei: imei, passcode: passcode);
  }

  void sendSilentConnectPing({required String imei, required String passcode}) {
    mqttService.sendSilentConnectPing(imei: imei, passcode: passcode);
  }

  Future<void> assignPanelId({
    required String imei,
    required String passcode,
    required String panelId,
  }) {
    return mqttService.assignPanelId(
      imei: imei,
      passcode: passcode,
      panelId: panelId,
    );
  }

  Future<bool> assignDestinationSettings({
    required String imei,
    required String passcode,
    String type = "1",
    String ip = "182.73.129.27",
    String port = "05600",
    String ip2 = "0.0.0.0",
    String port2 = "00000",
  }) {
    return mqttService.assignDestinationSettings(
      imei: imei,
      passcode: passcode,
      type: type,
      ip: ip,
      port: port,
      ip2: ip2,
      port2: port2,
    );
  }

  Future<bool> assignAdminNumbers({
    required String imei,
    required String passcode,
    required List<String> formattedNumbers,
  }) {
    return mqttService.assignAdminNumbers(
      imei: imei,
      passcode: passcode,
      formattedNumbers: formattedNumbers,
    );
  }

  Future<String?> readTelephoneSettings({
    required String imei,
    required String passcode,
  }) {
    return mqttService.readTelephoneSettings(imei: imei, passcode: passcode);
  }

  Future<String?> readDestinationSettings({
    required String imei,
    required String passcode,
  }) {
    return mqttService.readDestinationSettings(imei: imei, passcode: passcode);
  }

  Future<void> assignAdminNumber({
    required String imei,
    required String passcode,
    required String adminNumber,
  }) {
    return mqttService.assignAdminNumber(
      imei: imei,
      passcode: passcode,
      adminNumber: adminNumber,
    );
  }

  Future<String?> readPanelId({
    required String imei,
    required String passcode,
  }) {
    return mqttService.readPanelId(imei: imei, passcode: passcode);
  }

  Future<void> disconnectPanel({
    required String imei,
    required String passcode,
  }) {
    return mqttService.disconnectPanel(imei: imei, passcode: passcode);
  }

  Future<bool> panic({required String imei, required String passcode}) {
    return mqttService.panic(imei: imei, passcode: passcode);
  }

  Future<List<int>> ensureOutputsEnabled({
    required String imei,
    required String passcode,
    List<int> outputs = const [1, 2, 3],
  }) {
    return mqttService.ensureOutputsEnabled(
      imei: imei,
      passcode: passcode,
      outputs: outputs,
    );
  }

  Future<bool> setOutput({
    required String imei,
    required String passcode,
    required int output,
    required bool on,
  }) {
    return mqttService.setOutput(
      imei: imei,
      passcode: passcode,
      output: output,
      on: on,
    );
  }

  Future<bool> alarmAbort({required String imei, required String passcode}) {
    return mqttService.alarmAbort(imei: imei, passcode: passcode);
  }

  Future<void> arm({required String imei, required String passcode}) {
    return mqttService.arm(imei: imei, passcode: passcode);
  }

  Future<void> disarm({required String imei, required String passcode}) {
    return mqttService.disarm(imei: imei, passcode: passcode);
  }

  Future<void> readDashboard({required String imei, required String passcode}) {
    return mqttService.readDashboard(imei: imei, passcode: passcode);
  }

  Future<void> readAlarmLogs({required String imei, required String passcode}) {
    return mqttService.readAlarmLogs(imei: imei, passcode: passcode);
  }

  Future<DashboardInputSummary?> readDashboardInputSummary({
    required String imei,
    required String passcode,
    int zoneCount = 4,
  }) {
    return mqttService.readDashboardInputSummary(
      imei: imei,
      passcode: passcode,
      zoneCount: zoneCount,
    );
  }

  Future<InputSettings?> readInputSettings({
    required String imei,
    required String passcode,
    required String inputNumber,
    String? productNumber,
  }) {
    return mqttService.readInputSettings(
      imei: imei,
      passcode: passcode,
      inputNumber: inputNumber,
      productNumber: productNumber,
    );
  }

  Future<bool> writeInputSettings({
    required String imei,
    required String passcode,
    required InputSettings currentSettings,
    required String newInputName,
    required String newEnabled,
  }) {
    return mqttService.writeInputSettings(
      imei: imei,
      passcode: passcode,
      currentSettings: currentSettings,
      newInputName: newInputName,
      newEnabled: newEnabled,
    );
  }

  Future<void> readEventLogs({required String imei, required String passcode}) {
    return mqttService.readEventLogs(imei: imei, passcode: passcode);
  }

  Future<bool> queueAbort({required String imei, required String passcode}) {
    return mqttService.queueAbort(imei: imei, passcode: passcode);
  }

  Future<bool> sounderOff({required String imei, required String passcode}) {
    return mqttService.sounderOff(imei: imei, passcode: passcode);
  }

  Future<String?> readAudioStatus({
    required String imei,
    required String passcode,
  }) {
    return mqttService.readAudioStatus(imei: imei, passcode: passcode);
  }

  Future<String?> writeAudioDownload({
    required String imei,
    required String passcode,
    required String downloadMask,
  }) {
    return mqttService.writeAudioDownload(
      imei: imei,
      passcode: passcode,
      downloadMask: downloadMask,
    );
  }
}
