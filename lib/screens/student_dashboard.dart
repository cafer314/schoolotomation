import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/models.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  List<Grade> _grades = [];
  List<Subject> _subjects = [];
  List<Exam> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final student = authProvider.currentStudent;

    if (student != null) {
      try {
        final grades = await _databaseService.getGradesByStudent(student.id!);
        final subjects = await _databaseService.getSubjectsForStudent(
          student.id!,
        );
        final exams = await _databaseService.getExamsForStudent(student.id!);

        setState(() {
          _grades = grades;
          _subjects = subjects;
          _exams = exams;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
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

  Color _getGradeColor(double grade) {
    if (grade >= 85) return Colors.green;
    if (grade >= 70) return Colors.orange;
    if (grade >= 50) return Colors.yellow.shade700;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final student = authProvider.currentStudent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'لوحة تحكم الطالب',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade700, Colors.green.shade50],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hoş geldin kartı
                      Container(
                        width: double.infinity,
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.green.shade100,
                              child: Icon(
                                Icons.school,
                                size: 30,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مرحباً بك،',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '${student?.name} ${student?.surname}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // İstatistikler
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'المواد الدراسية',
                              _subjects.length.toString(),
                              Icons.book,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'الدرجات',
                              _grades.length.toString(),
                              Icons.grade,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tab bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                labelColor: Colors.green.shade700,
                                unselectedLabelColor: Colors.grey.shade600,
                                indicatorColor: Colors.green.shade700,
                                tabs: [
                                  Tab(
                                    child: Text(
                                      'المواد الدراسية',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Text(
                                      'الدرجات',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 400,
                                child: TabBarView(
                                  children: [
                                    // Dersler tab'ı
                                    _subjects.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.book_outlined,
                                                  size: 80,
                                                  color: Colors.grey.shade300,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'لا توجد مواد دراسية',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(16),
                                            itemCount: _subjects.length,
                                            itemBuilder: (context, index) {
                                              final subject = _subjects[index];
                                              return Card(
                                                margin: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.green.shade100,
                                                    child: Icon(
                                                      Icons.book,
                                                      color:
                                                          Colors.green.shade700,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    subject.name,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    'مادة دراسية',
                                                    style: GoogleFonts.poppins(
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                    // Notlar tab'ı
                                    _grades.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.grade_outlined,
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
                                                  'لم يتم إدخال أي درجات بعد',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(16),
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
                                              final gradeColor = _getGradeColor(
                                                grade.grade,
                                              );

                                              return Card(
                                                margin: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor: gradeColor
                                                        .withOpacity(0.1),
                                                    child: Text(
                                                      grade.grade
                                                          .toStringAsFixed(1),
                                                      style: TextStyle(
                                                        color: gradeColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    _getExamName(grade.examId),
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'المادة: ${_getSubjectName(exam.subjectId)}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: gradeColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${grade.grade.toStringAsFixed(1)}/100',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                  ),
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
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
