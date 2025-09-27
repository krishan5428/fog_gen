class SitePanelSimInfo {
  final String siteName;
  final String panelSimNumber;

  SitePanelSimInfo({required this.siteName, required this.panelSimNumber});

  @override
  String toString() {
    return 'Site: $siteName | SIM: $panelSimNumber';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SitePanelSimInfo &&
        other.siteName == siteName &&
        other.panelSimNumber == panelSimNumber;
  }

  @override
  int get hashCode => siteName.hashCode ^ panelSimNumber.hashCode;
}
