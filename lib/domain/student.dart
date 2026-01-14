class Student {
  final int stdId;
  final String name;
  final String matricule;

  Student({required this.stdId, required this.name, required this.matricule});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      stdId: json['stdId'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      matricule: json['matricule'] ?? '',
    );
  }
}
