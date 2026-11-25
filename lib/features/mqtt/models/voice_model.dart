class VoiceModel {
  final int? id;
  final String imei;
  final String voiceNo;
  final String voiceSize;
  final int
  isActive; // 0 = No file on device, 1 = Downloaded, 2 = Downloading, 3 = In Queue, 9 = Failed
  final int isDevice; // 0 = Local cache only, 1 = Uploaded to cloud server
  final String path; // Local disk path if downloaded
  final String sizeBool;

  VoiceModel({
    this.id,
    required this.imei,
    required this.voiceNo,
    required this.voiceSize,
    required this.isActive,
    required this.isDevice,
    required this.path,
    required this.sizeBool,
  });

  VoiceModel copyWith({
    int? id,
    String? imei,
    String? voiceNo,
    String? voiceSize,
    int? isActive,
    int? isDevice,
    String? path,
    String? sizeBool,
  }) {
    return VoiceModel(
      id: id ?? this.id,
      imei: imei ?? this.imei,
      voiceNo: voiceNo ?? this.voiceNo,
      voiceSize: voiceSize ?? this.voiceSize,
      isActive: isActive ?? this.isActive,
      isDevice: isDevice ?? this.isDevice,
      path: path ?? this.path,
      sizeBool: sizeBool ?? this.sizeBool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'voice_no': voiceNo,
      'voice_size': voiceSize,
      'is_active': isActive,
      'is_device': isDevice,
      'path': path,
      'size_bool': sizeBool,
    };
  }

  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    return VoiceModel(
      id: json['id'] as int?,
      imei: json['imei']?.toString() ?? '',
      voiceNo: json['voice_no']?.toString() ?? '',
      voiceSize: json['voice_size']?.toString() ?? '0',
      isActive: json['is_active'] as int? ?? 0,
      isDevice: json['is_device'] as int? ?? 0,
      path: json['path']?.toString() ?? '',
      sizeBool: json['size_bool']?.toString() ?? '0',
    );
  }
}
