class Attendance {
  final int attId;
  final int stdId;
  final int courseID;
  final String fingerprintHash;
  final String latitude;
  final String longitude;
  final String? timestamp;
  final String? status;
  final String? markedBy;
  final String? markedAt;
  final String? createdAt;
  final int? teacherId;
  final String? notes;
  final bool? valid;
  final String? courseTitle;

  Attendance({
    required this.attId,
    required this.stdId,
    required this.courseID,
    required this.fingerprintHash,
    required this.latitude,
    required this.longitude,
    this.timestamp,
    this.status,
    this.markedBy,
    this.markedAt,
    this.createdAt,
    this.teacherId,
    this.notes,
    this.valid,
    this.courseTitle,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    String? courseTitle;
    if (json['course'] != null &&
        json['course'] is Map &&
        json['course']['title'] != null) {
      courseTitle = json['course']['title'];
    }
    return Attendance(
      attId: json['attId'] ?? json['id'] ?? 0,
      stdId: json['stdId'] ?? 0,
      courseID: json['courseID'] ?? 0,
      fingerprintHash: json['fingerprinthash'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      timestamp: json['timestamp'],
      status: json['status'],
      markedBy: json['markedBy'],
      markedAt: json['markedAt'],
      createdAt: json['createdAt'],
      teacherId: json['teacherId'],
      notes: json['notes'],
      valid: json['valid'],
      courseTitle: courseTitle,
    );
  }
}
