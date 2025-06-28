import 'package:sqflite/sqflite.dart';
import '../models/database_helper.dart';
import '../models/models.dart';

class DatabaseService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Sınıf işlemleri
  Future<int> insertClass(Class classData) async {
    final db = await _databaseHelper.database;
    return await db.insert('classes', classData.toMap());
  }

  Future<List<Class>> getClasses() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('classes');
    return List.generate(maps.length, (i) => Class.fromMap(maps[i]));
  }

  Future<void> deleteClass(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateClass(Class classData) async {
    final db = await _databaseHelper.database;
    await db.update(
      'classes',
      classData.toMap(),
      where: 'id = ?',
      whereArgs: [classData.id],
    );
  }

  // Ders işlemleri
  Future<int> insertSubject(Subject subject) async {
    final db = await _databaseHelper.database;
    return await db.insert('subjects', subject.toMap());
  }

  Future<List<Subject>> getSubjects() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('subjects');
    return List.generate(maps.length, (i) => Subject.fromMap(maps[i]));
  }

  Future<void> deleteSubject(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSubject(Subject subject) async {
    final db = await _databaseHelper.database;
    await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  // Sınıf-Ders ilişki işlemleri
  Future<void> addSubjectToClass(int classId, int subjectId) async {
    final db = await _databaseHelper.database;
    await db.insert('class_subjects', {
      'class_id': classId,
      'subject_id': subjectId,
    });
  }

  Future<List<Subject>> getSubjectsForClass(int classId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT s.* FROM subjects s
      INNER JOIN class_subjects cs ON s.id = cs.subject_id
      WHERE cs.class_id = ?
    ''',
      [classId],
    );
    return List.generate(maps.length, (i) => Subject.fromMap(maps[i]));
  }

  Future<void> removeSubjectFromClass(int classId, int subjectId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'class_subjects',
      where: 'class_id = ? AND subject_id = ?',
      whereArgs: [classId, subjectId],
    );
  }

  Future<List<Class>> getClassesForSubject(int subjectId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT c.* FROM classes c
      INNER JOIN class_subjects cs ON c.id = cs.class_id
      WHERE cs.subject_id = ?
    ''',
      [subjectId],
    );
    return List.generate(maps.length, (i) => Class.fromMap(maps[i]));
  }

  Future<List<Map<String, dynamic>>> getClassSubjectsBySubject(
    int subjectId,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'class_subjects',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    return maps;
  }

  Future<void> removeSubjectFromAllClasses(int subjectId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'class_subjects',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
  }

  // Öğrenci işlemleri
  Future<List<Student>> getAllStudents() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('students');
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<Student?> getStudentById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<Student?> getStudentByUsername(String username) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertStudent(Student student) async {
    final db = await _databaseHelper.database;
    return await db.insert('students', student.toMap());
  }

  Future<int> updateStudent(Student student) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Student>> getStudentsByClass(int classId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'class_id = ?',
      whereArgs: [classId],
    );
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  // Öğretmen işlemleri
  Future<Teacher?> getTeacherByUsername(String username) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'teachers',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return Teacher.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertTeacher(Teacher teacher) async {
    final db = await _databaseHelper.database;
    return await db.insert('teachers', teacher.toMap());
  }

  // Sınav işlemleri
  Future<List<Exam>> getAllExams() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('exams');
    return List.generate(maps.length, (i) => Exam.fromMap(maps[i]));
  }

  Future<Exam?> getExamById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exams',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Exam.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Exam>> getExamsBySubject(int subjectId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'exams',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    return List.generate(maps.length, (i) => Exam.fromMap(maps[i]));
  }

  Future<int> insertExam(Exam exam) async {
    final db = await _databaseHelper.database;
    return await db.insert('exams', exam.toMap());
  }

  Future<int> updateExam(Exam exam) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'exams',
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<int> deleteExam(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  // Not işlemleri
  Future<List<Grade>> getAllGrades() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('grades');
    return List.generate(maps.length, (i) => Grade.fromMap(maps[i]));
  }

  Future<Grade?> getGradeById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grades',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Grade.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Grade>> getGradesByStudent(int studentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grades',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return List.generate(maps.length, (i) => Grade.fromMap(maps[i]));
  }

  Future<List<Grade>> getGradesByExam(int examId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grades',
      where: 'exam_id = ?',
      whereArgs: [examId],
    );
    return List.generate(maps.length, (i) => Grade.fromMap(maps[i]));
  }

  Future<Grade?> getGradeByStudentAndExam(int studentId, int examId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'grades',
      where: 'student_id = ? AND exam_id = ?',
      whereArgs: [studentId, examId],
    );
    if (maps.isNotEmpty) {
      return Grade.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertGrade(Grade grade) async {
    final db = await _databaseHelper.database;
    return await db.insert('grades', grade.toMap());
  }

  Future<int> updateGrade(Grade grade) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'grades',
      grade.toMap(),
      where: 'id = ?',
      whereArgs: [grade.id],
    );
  }

  Future<int> deleteGrade(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete('grades', where: 'id = ?', whereArgs: [id]);
  }

  // Sınıf-Ders ilişki işlemleri
  Future<List<Subject>> getSubjectsForStudent(int studentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT DISTINCT s.* FROM subjects s
      INNER JOIN class_subjects cs ON s.id = cs.subject_id
      INNER JOIN students st ON cs.class_id = st.class_id
      WHERE st.id = ?
    ''',
      [studentId],
    );
    return List.generate(maps.length, (i) => Subject.fromMap(maps[i]));
  }

  Future<List<Exam>> getExamsForStudent(int studentId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT DISTINCT e.* FROM exams e
      INNER JOIN subjects s ON e.subject_id = s.id
      INNER JOIN class_subjects cs ON s.id = cs.subject_id
      INNER JOIN students st ON cs.class_id = st.class_id
      WHERE st.id = ?
    ''',
      [studentId],
    );
    return List.generate(maps.length, (i) => Exam.fromMap(maps[i]));
  }
}
