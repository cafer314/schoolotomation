import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  // Kişisel bilgiler için controller'lar
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _personalFormKey = GlobalKey<FormState>();

  // Veriler
  List<Class> _classes = [];
  List<Subject> _allSubjects = [];
  List<Subject> _studentSubjects = [];
  List<Exam> _studentExams = [];
  List<Grade> _studentGrades = [];
  Class? _selectedClass;
  bool _isLoading = true;
  bool _isEditingPersonal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      // Kişisel bilgileri form'a yükle
      _nameController.text = widget.student.name;
      _surnameController.text = widget.student.surname;
      _usernameController.text = widget.student.username;
      _passwordController.text = widget.student.password;

      // Sınıfları yükle
      _classes = await _databaseService.getClasses();
      _selectedClass = _classes.firstWhere(
        (c) => c.id == widget.student.classId,
      );

      // Tüm dersleri yükle
      _allSubjects = await _databaseService.getSubjects();

      // Öğrencinin sınıfındaki dersleri yükle
      _studentSubjects = await _databaseService.getSubjectsForClass(
        widget.student.classId,
      );

      // Öğrencinin sınavlarını yükle
      await _loadStudentExams();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStudentExams() async {
    try {
      // Öğrencinin aldığı derslerin sınavlarını al
      List<Exam> allExams = [];
      for (Subject subject in _studentSubjects) {
        List<Exam> subjectExams = await _databaseService.getExamsBySubject(
          subject.id!,
        );
        allExams.addAll(subjectExams);
      }
      _studentExams = allExams;

      // Öğrencinin notlarını al
      _studentGrades = await _databaseService.getGradesByStudent(
        widget.student.id!,
      );
    } catch (e) {
      print('Sınav yükleme hatası: $e');
    }
  }

  Future<void> _updatePersonalInfo() async {
    if (_personalFormKey.currentState!.validate()) {
      try {
        final updatedStudent = Student(
          id: widget.student.id,
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          classId: _selectedClass!.id!,
          createdAt: widget.student.createdAt,
        );

        await _databaseService.updateStudent(updatedStudent);

        setState(() => _isEditingPersonal = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kişisel bilgiler güncellendi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحديث المعلومات الشخصية: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addSubjectToStudent(Subject subject) async {
    try {
      // Öğrencinin sınıfına dersi ekle (eğer yoksa)
      await _databaseService.addSubjectToClass(
        widget.student.classId,
        subject.id!,
      );

      // Listeyi yenile
      _studentSubjects = await _databaseService.getSubjectsForClass(
        widget.student.classId,
      );
      await _loadStudentExams();

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${subject.name} dersi eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة المادة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeSubjectFromStudent(Subject subject) async {
    try {
      // Öğrencinin sınıfından dersi kaldır
      await _databaseService.removeSubjectFromClass(
        widget.student.classId,
        subject.id!,
      );

      // Listeyi yenile
      _studentSubjects = await _databaseService.getSubjectsForClass(
        widget.student.classId,
      );
      await _loadStudentExams();

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${subject.name} dersi kaldırıldı!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إزالة المادة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateGrade(int examId, double newGrade) async {
    try {
      final existingGrade = _studentGrades.firstWhere(
        (g) => g.examId == examId,
        orElse: () => Grade(
          studentId: widget.student.id!,
          examId: examId,
          grade: newGrade,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (existingGrade.id != null) {
        // Mevcut notu güncelle
        final updatedGrade = Grade(
          id: existingGrade.id,
          studentId: existingGrade.studentId,
          examId: existingGrade.examId,
          grade: newGrade,
          createdAt: existingGrade.createdAt,
        );
        await _databaseService.updateGrade(updatedGrade);
      } else {
        // Yeni not ekle
        await _databaseService.insertGrade(existingGrade);
      }

      // Notları yenile
      _studentGrades = await _databaseService.getGradesByStudent(
        widget.student.id!,
      );
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الدرجة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الدرجة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفاصيل الطالب',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'المعلومات الشخصية'),
            Tab(text: 'المواد الدراسية'),
            Tab(text: 'الدرجات'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.teal.shade700, Colors.teal.shade50],
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalInfoTab(),
                  _buildSubjectsTab(),
                  _buildExamsTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _personalFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'المعلومات الشخصية',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(
                                () => _isEditingPersonal = !_isEditingPersonal,
                              );
                              if (!_isEditingPersonal) {
                                // İptal edildiğinde orijinal değerleri geri yükle
                                _nameController.text = widget.student.name;
                                _surnameController.text =
                                    widget.student.surname;
                                _usernameController.text =
                                    widget.student.username;
                                _passwordController.text =
                                    widget.student.password;
                              }
                            },
                            icon: Icon(
                              _isEditingPersonal ? Icons.cancel : Icons.edit,
                            ),
                            color: _isEditingPersonal
                                ? Colors.red
                                : Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ad
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditingPersonal,
                        decoration: InputDecoration(
                          labelText: 'الاسم',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الاسم مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Soyad
                      TextFormField(
                        controller: _surnameController,
                        enabled: _isEditingPersonal,
                        decoration: InputDecoration(
                          labelText: 'الاسم الكامل',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الاسم الكامل مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kullanıcı adı
                      TextFormField(
                        controller: _usernameController,
                        enabled: _isEditingPersonal,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.account_circle),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'اسم المستخدم مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Şifre
                      TextFormField(
                        controller: _passwordController,
                        enabled: _isEditingPersonal,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'الرقم السري',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرقم السري مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sınıf seçimi
                      DropdownButtonFormField<Class>(
                        value: _selectedClass,
                        decoration: InputDecoration(
                          labelText: 'الفصل',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.class_),
                        ),
                        items: _classes.map((classData) {
                          return DropdownMenuItem(
                            value: classData,
                            child: Text(classData.name),
                          );
                        }).toList(),
                        onChanged: _isEditingPersonal
                            ? (Class? newValue) {
                                setState(() => _selectedClass = newValue);
                              }
                            : null,
                        validator: (value) {
                          if (value == null) {
                            return 'الفصل مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_isEditingPersonal)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _updatePersonalInfo,
                            icon: const Icon(Icons.save),
                            label: Text(
                              'حفظ',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mevcut dersler
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المواد المسجلة',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_studentSubjects.isEmpty)
                    Center(
                      child: Text(
                        'لا توجد مواد مسجلة',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _studentSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _studentSubjects[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: Icon(
                              Icons.book,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          title: Text(
                            subject.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeSubjectFromStudent(subject),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ders ekleme
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إضافة مادة دراسية',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_allSubjects.isEmpty)
                    Center(
                      child: Text(
                        'لا توجد مواد متاحة للإضافة',
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = _allSubjects[index];
                        final isAlreadyAdded = _studentSubjects.any(
                          (s) => s.id == subject.id,
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAlreadyAdded
                                ? Colors.grey.shade100
                                : Colors.teal.shade100,
                            child: Icon(
                              Icons.book,
                              color: isAlreadyAdded
                                  ? Colors.grey.shade600
                                  : Colors.teal.shade700,
                            ),
                          ),
                          title: Text(
                            subject.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: isAlreadyAdded
                                  ? Colors.grey.shade600
                                  : null,
                            ),
                          ),
                          trailing: isAlreadyAdded
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () =>
                                      _addSubjectToStudent(subject),
                                ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsTab() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _studentExams.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد درجات',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _studentExams.length,
                itemBuilder: (context, index) {
                  final exam = _studentExams[index];
                  final grade = _studentGrades.firstWhere(
                    (g) => g.examId == exam.id,
                    orElse: () => Grade(
                      studentId: widget.student.id!,
                      examId: exam.id!,
                      grade: 0,
                      createdAt: DateTime.now().toIso8601String(),
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: Icon(Icons.quiz, color: Colors.teal.shade700),
                      ),
                      title: Text(
                        exam.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'الدرجة: ${grade.grade.toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: grade.grade.toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          onChanged: (value) {
                            final newGrade = double.tryParse(value);
                            if (newGrade != null &&
                                newGrade >= 0 &&
                                newGrade <= 100) {
                              _updateGrade(exam.id!, newGrade);
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
