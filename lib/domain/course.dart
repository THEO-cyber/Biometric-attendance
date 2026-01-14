class Course {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
  final int id;
  final String name;
  final int? teacherId;

  Course({required this.id, required this.name, this.teacherId});

  factory Course.fromJson(Map<String, dynamic> json) {
    try {
      return Course(
        id: json['id'] ?? json['courseID'] ?? 0,
        name:
            json['name']?.toString() ?? json['title']?.toString() ?? 'Unknown',
        teacherId: json['teacherId'] ?? json['instructorID'],
      );
    } catch (e, stack) {
      print('[Course.fromJson] Error parsing: $json\n$e\n$stack');
      return Course(id: 0, name: 'Invalid', teacherId: null);
    }
  }
}
