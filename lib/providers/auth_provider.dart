import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  Teacher? _currentTeacher;
  Student? _currentStudent;
  bool _isLoading = false;

  Teacher? get currentTeacher => _currentTeacher;
  Student? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentTeacher != null || _currentStudent != null;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> loginTeacher(String username, String password) async {
    setLoading(true);
    try {
      final teacher = await _databaseService.getTeacherByUsername(username);
      if (teacher != null && teacher.password == password) {
        _currentTeacher = teacher;
        _currentStudent = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> loginStudent(String username, String password) async {
    setLoading(true);
    try {
      final student = await _databaseService.getStudentByUsername(username);
      if (student != null && student.password == password) {
        _currentStudent = student;
        _currentTeacher = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      setLoading(false);
    }
  }

  void logout() {
    _currentTeacher = null;
    _currentStudent = null;
    notifyListeners();
  }
}
