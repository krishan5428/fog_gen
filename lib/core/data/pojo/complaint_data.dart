class ComplaintData {
  final int id;
  final String cTkn;
  final String subject;
  final String remark;
  final String dateTime;
  final String userId;
  final String siteName;
  final String image1Path;
  final String image2Path;
  final String image3Path;

  ComplaintData({
    required this.id,
    required this.cTkn,
    required this.subject,
    required this.remark,
    required this.dateTime,
    required this.userId,
    required this.siteName,
    required this.image1Path,
    required this.image2Path,
    required this.image3Path,
  });

  factory ComplaintData.fromJson(Map<String, dynamic> json) {
    return ComplaintData(
      id: json['id'],
      cTkn: json['c_tkn'],
      subject: json['subject'],
      remark: json['remark'],
      dateTime: json['dateTime'],
      userId: json['userId'].toString(),
      siteName: json['siteName'],
      image1Path: json['image1Path'],
      image2Path: json['image2Path'],
      image3Path: json['image3Path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'c_tkn': cTkn,
      'subject': subject,
      'remark': remark,
      'dateTime': dateTime,
      'userId': userId,
      'siteName': siteName,
      'image1Path': image1Path,
      'image2Path': image2Path,
      'image3Path': image3Path,
    };
  }
}
