class MqttConstants {
  MqttConstants._();

  /// AWS IoT Core Endpoint
  static const String brokerUrl =
      'a7kwxknv6fhia-ats.iot.eu-north-1.amazonaws.com';

  /// Secure MQTT Port
  static const int port = 8883;

  /// Keep Alive Interval
  static const int keepAlivePeriod = 20;

  /// Topic Patterns
  static String subscribeTopic(String imei) => 'QlMQTT/$imei/a';

  static String publishTopic(String imei) => 'QlMQTT/$imei/b';

  /// Message Prefix
  static const String messagePrefix = 'ST';
}
