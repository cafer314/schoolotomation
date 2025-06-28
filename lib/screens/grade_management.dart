import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class GradeManagementScreen extends StatefulWidget {
  const GradeManagementScreen({super.key});

  @override
  State<GradeManagementScreen> createState() => _GradeManagementScreenState();
}

class _GradeManagementScreenState extends State<GradeManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Grade> _grades = [];
  List<Student> _students = [];
  List<Exam> _exams = [];
  List<Subject> _subjects = [];
  List<Class> _classes = [];
  Exam? _selectedExam;
  Subject? _selectedSubject;
  Class? _selectedClass;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<int, TextEditingController> _gradeControllers = {};
  List<Student> _examStudents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _gradeControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _databaseService.getAllGrades();
      final students = await _databaseService.getAllStudents();
      final exams = await _databaseService.getAllExams();
      final subjects = await _databaseService.getSubjects();
      final classes = await _databaseService.getClasses();
      setState(() {
        _grades = grades;
        _students = students;
        _exams = exams;
        _subjects = subjects;
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e')));
      }
    }
  }

  void _onSubjectChanged(Subject? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedExam = null;
      _examStudents = [];
      _clearGradeControllers();
    });
  }

  void _onClassChanged(Class? classItem) {
    setState(() {
      _selectedClass = classItem;
      _loadExamStudents();
    });
  }

  void _onExamChanged(Exam? exam) {
    setState(() {
      _selectedExam = exam;
      _loadExamStudents();
    });
  }

  Future<void> _loadExamStudents() async {
    if (_selectedExam == null) {
      setState(() {
        _examStudents = [];
        _clearGradeControllers();
      });
      return;
    }

    try {
      // Sınavın dersini al
      final exam = _exams.firstWhere((e) => e.id == _selectedExam!.id);
      final subject = _subjects.firstWhere((s) => s.id == exam.subjectId);

      // Bu dersi alan sınıfları bul
      final classSubjects = await _databaseService.getClassSubjectsBySubject(
        exam.subjectId,
      );
      final classIds = classSubjects
          .map((cs) => cs['class_id'] as int)
          .toList();

      // Bu sınıflardaki öğrencileri filtrele
      List<Student> filteredStudents = _students.where((student) {
        return classIds.contains(student.classId);
      }).toList();

      // Eğer sınıf seçilmişse, sadece o sınıftaki öğrencileri göster
      if (_selectedClass != null) {
        filteredStudents = filteredStudents.where((student) {
          return student.classId == _selectedClass!.id;
        }).toList();
      }

      setState(() {
        _examStudents = filteredStudents;
        _initializeGradeControllers();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل الطلاب: $e')));
      }
    }
  }

  void _initializeGradeControllers() {
    _clearGradeControllers();
    for (var student in _examStudents) {
      // Mevcut notu kontrol et
      final existingGrade = _grades
          .where(
            (g) => g.studentId == student.id && g.examId == _selectedExam!.id,
          )
          .firstOrNull;

      _gradeControllers[student.id!] = TextEditingController(
        text: existingGrade?.grade.toString() ?? '',
      );
    }
  }

  void _clearGradeControllers() {
    _gradeControllers.values.forEach((controller) => controller.dispose());
    _gradeControllers.clear();
  }

  Future<void> _saveGrades() async {
    if (_selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار امتحان'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      for (var student in _examStudents) {
        final controller = _gradeControllers[student.id];
        if (controller != null && controller.text.isNotEmpty) {
          final grade = double.tryParse(controller.text);
          if (grade != null && grade >= 0 && grade <= 100) {
            // Mevcut notu kontrol et
            final existingGrade = _grades
                .where(
                  (g) =>
                      g.studentId == student.id &&
                      g.examId == _selectedExam!.id,
                )
                .firstOrNull;

            if (existingGrade != null) {
              // Notu güncelle
              final updatedGrade = Grade(
                id: existingGrade.id,
                studentId: student.id!,
                examId: _selectedExam!.id!,
                grade: grade,
                createdAt: existingGrade.createdAt,
              );
              await _databaseService.updateGrade(updatedGrade);
            } else {
              // Yeni not ekle
              final newGrade = Grade(
                studentId: student.id!,
                examId: _selectedExam!.id!,
                grade: grade,
                createdAt: DateTime.now().toIso8601String(),
              );
              await _databaseService.insertGrade(newGrade);
            }
          }
        }
      }

      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الدرجات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في حفظ الدرجات: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGrade(int gradeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الدرجة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteGrade(gradeId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الدرجة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ في حذف الدرجة: $e')));
        }
      }
    }
  }

  String _getStudentName(int studentId) {
    final student = _students.firstWhere(
      (s) => s.id == studentId,
      orElse: () => Student(
        name: 'غير معروف',
        surname: '',
        username: '',
        password: '',
        classId: 0,
        createdAt: '',
      ),
    );
    return '${student.name} ${student.surname}';
  }

  String _getExamName(int examId) {
    final exam = _exams.firstWhere(
      (e) => e.id == examId,
      orElse: () => Exam(name: 'غير معروف', subjectId: 0, createdAt: ''),
    );
    return exam.name;
  }

  String _getSubjectName(int subjectId) {
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => Subject(name: 'غير معروف', createdAt: ''),
    );
    return subject.name;
  }

  String _getClassName(int classId) {
    final classItem = _classes.firstWhere(
      (c) => c.id == classId,
      orElse: () => Class(name: 'غير معروف', createdAt: ''),
    );
    return classItem.name;
  }

  Color _getGradeColor(double grade) {
    if (grade >= 85) return Colors.green;
    if (grade >= 70) return Colors.orange;
    if (grade >= 50) return Colors.yellow.shade700;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة الدرجات',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sınav seçimi bölümü
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختيار الامتحان',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Subject>(
                        value: _selectedSubject,
                        decoration: InputDecoration(
                          labelText: 'المادة الدراسية',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.shade700,
                              width: 2,
                            ),
                          ),
                        ),
                        items: _subjects.map((subject) {
                          return DropdownMenuItem<Subject>(
                            value: subject,
                            child: Text(
                              subject.name,
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }).toList(),
                        onChanged: _onSubjectChanged,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Exam>(
                        value: _selectedExam,
                        decoration: InputDecoration(
                          labelText: 'الامتحان',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.shade700,
                              width: 2,
                            ),
                          ),
                        ),
                        items: _selectedSubject != null
                            ? _exams
                                  .where(
                                    (exam) =>
                                        exam.subjectId == _selectedSubject!.id,
                                  )
                                  .map((exam) {
                                    return DropdownMenuItem<Exam>(
                                      value: exam,
                                      child: Text(
                                        exam.name,
                                        style: GoogleFonts.poppins(),
                                      ),
                                    );
                                  })
                                  .toList()
                            : [],
                        onChanged: _onExamChanged,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Class>(
                        value: _selectedClass,
                        decoration: InputDecoration(
                          labelText: 'الصف (اختياري)',
                          hintText: 'اختر صف محدد أو اتركه فارغاً لجميع الصفوف',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red.shade700,
                              width: 2,
                            ),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<Class>(
                            value: null,
                            child: Text('جميع الصفوف'),
                          ),
                          ..._classes.map((classItem) {
                            return DropdownMenuItem<Class>(
                              value: classItem,
                              child: Text(
                                classItem.name,
                                style: GoogleFonts.poppins(),
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: _onClassChanged,
                      ),
                    ],
                  ),
                ),

                // Öğrenci listesi ve not girişi
                if (_selectedExam != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'طلاب الامتحان (${_examStudents.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveGrades,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isSaving ? 'حفظ...' : 'حفظ الدرجات',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _examStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا يوجد طلاب لهذا الامتحان',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'اختر امتحان آخر أو تحقق من إعدادات الصفوف',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _examStudents.length,
                            itemBuilder: (context, index) {
                              final student = _examStudents[index];
                              final controller = _gradeControllers[student.id];
                              final existingGrade = _grades
                                  .where(
                                    (g) =>
                                        g.studentId == student.id &&
                                        g.examId == _selectedExam!.id,
                                  )
                                  .firstOrNull;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.red.shade100,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${student.name} ${student.surname}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'الصف: ${_getClassName(student.classId)}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (existingGrade != null)
                                              Text(
                                                'الدرجة الحالية: ${existingGrade.grade.toStringAsFixed(1)}/100',
                                                style: GoogleFonts.poppins(
                                                  color: _getGradeColor(
                                                    existingGrade.grade,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: TextFormField(
                                          controller: controller,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'الدرجة',
                                            hintText: '0-100',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                          validator: (value) {
                                            if (value != null &&
                                                value.isNotEmpty) {
                                              final grade = double.tryParse(
                                                value,
                                              );
                                              if (grade == null) {
                                                return 'رقم';
                                              }
                                              if (grade < 0 || grade > 100) {
                                                return '0-100';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],

                // Mevcut notlar listesi
                if (_selectedExam == null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.grade, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'جميع الدرجات (${_grades.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _grades.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.grade,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد درجات',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'اختر امتحان لإضافة درجات',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _grades.length,
                            itemBuilder: (context, index) {
                              final grade = _grades[index];
                              final exam = _exams.firstWhere(
                                (e) => e.id == grade.examId,
                                orElse: () => Exam(
                                  name: 'غير معروف',
                                  subjectId: 0,
                                  createdAt: '',
                                ),
                              );
                              final gradeColor = _getGradeColor(grade.grade);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: gradeColor.withOpacity(
                                      0.1,
                                    ),
                                    child: Text(
                                      grade.grade.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: gradeColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    _getStudentName(grade.studentId),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الامتحان: ${_getExamName(grade.examId)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'المادة: ${_getSubjectName(exam.subjectId)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: gradeColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${grade.grade.toStringAsFixed(1)}/100',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () =>
                                            _deleteGrade(grade.id!),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
    );
  }
}
