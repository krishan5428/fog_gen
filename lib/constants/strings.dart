/// G4 (4G) models. These panels talk over MQTT (AWS IoT) instead of TCP/SMS
/// and are saved on the server with `pnl_type = 4GCOM`.
/// See docs/G4_MQTT_FLOW.md.
const Set<String> fourGComPanels = {
  'FIRE PANEL-2 ZONE - F02L G4',
  'FIRE PANEL-4 ZONE - F04L G4',
  'FIRE COMMUNICATOR-MX FCOM G4',
};

/// Server `pnl_type` value for G4 panels.
const String fourGComPanelType = '4GCOM';
