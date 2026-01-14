

import 'package:biometric/data/student_repository.dart';
import 'package:biometric/domain/student_usecase.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  late final StudentUseCase studentUseCase;

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal() {
    final repository = StudentRepository();
    studentUseCase = StudentUseCase(repository);
  }
}
