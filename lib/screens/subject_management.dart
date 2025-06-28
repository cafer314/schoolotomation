import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  List<Subject> _subjects = [];
  List<Class> _classes = [];
  List<int> _selectedClassIds = [];
  bool _isLoading = true;
  bool _isAdding = false;
  bool _isEditing = false;
  int? _editingSubjectId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _databaseService.getSubjects();
      final classes = await _databaseService.getClasses();
      setState(() {
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

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);
    try {
      final newSubject = Subject(
        name: _subjectNameController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );
      final subjectId = await _databaseService.insertSubject(newSubject);

      // Seçili sınıfları derse ata
      for (int classId in _selectedClassIds) {
        await _databaseService.addSubjectToClass(classId, subjectId);
      }

      _subjectNameController.clear();
      _selectedClassIds.clear();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المادة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في إضافة المادة: $e')));
      }
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _updateSubject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEditing = true);
    try {
      final updatedSubject = Subject(
        id: _editingSubjectId,
        name: _subjectNameController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await _databaseService.updateSubject(updatedSubject);

      // Mevcut sınıf ilişkilerini kaldır
      await _databaseService.removeSubjectFromAllClasses(_editingSubjectId!);

      // Yeni sınıf ilişkilerini ekle
      for (int classId in _selectedClassIds) {
        await _databaseService.addSubjectToClass(classId, _editingSubjectId!);
      }

      _subjectNameController.clear();
      _selectedClassIds.clear();
      _editingSubjectId = null;
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المادة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحديث المادة: $e')));
      }
    } finally {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _deleteSubject(int subjectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه المادة؟'),
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
        await _databaseService.deleteSubject(subjectId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المادة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ في حذف المادة: $e')));
        }
      }
    }
  }

  Future<void> _startEditing(Subject subject) async {
    try {
      final assignedClasses = await _databaseService.getClassesForSubject(
        subject.id!,
      );
      setState(() {
        _editingSubjectId = subject.id;
        _subjectNameController.text = subject.name;
        _selectedClassIds = assignedClasses.map((c) => c.id!).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل بيانات المادة: $e')),
        );
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingSubjectId = null;
      _subjectNameController.clear();
      _selectedClassIds.clear();
    });
  }

  void _toggleClassSelection(int classId) {
    setState(() {
      if (_selectedClassIds.contains(classId)) {
        _selectedClassIds.remove(classId);
      } else {
        _selectedClassIds.add(classId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة المواد',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Form bölümü
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingSubjectId == null
                              ? 'إضافة مادة جديدة'
                              : 'تعديل المادة',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _subjectNameController,
                          decoration: InputDecoration(
                            labelText: 'اسم المادة',
                            hintText: 'مثال: الرياضيات',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.orange.shade700,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم المادة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Sınıf seçimi
                        Text(
                          'الفصول الدراسية المخصصة:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _classes.length,
                            itemBuilder: (context, index) {
                              final classItem = _classes[index];
                              final isSelected = _selectedClassIds.contains(
                                classItem.id,
                              );
                              return CheckboxListTile(
                                title: Text(
                                  classItem.name,
                                  style: GoogleFonts.poppins(),
                                ),
                                value: isSelected,
                                onChanged: (value) =>
                                    _toggleClassSelection(classItem.id!),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _editingSubjectId == null
                                    ? (_isAdding ? null : _addSubject)
                                    : (_isEditing ? null : _updateSubject),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isAdding || _isEditing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _editingSubjectId == null
                                            ? 'إضافة'
                                            : 'تحديث',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            if (_editingSubjectId != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _cancelEditing,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'إلغاء',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Liste başlığı
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.book, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'المواد الدراسية (${_subjects.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dersler listesi
                Expanded(
                  child: _subjects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.book,
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
                              const SizedBox(height: 8),
                              Text(
                                'أضف مواد دراسية جديدة للبدء',
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
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(
                                    Icons.book,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                title: Text(
                                  subject.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'تاريخ الإنشاء: ${DateTime.parse(subject.createdAt).toString().split(' ')[0]}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _startEditing(subject),
                                      color: Colors.blue,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _deleteSubject(subject.id!),
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
            ),
    );
  }
}
