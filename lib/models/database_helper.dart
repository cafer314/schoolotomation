import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'school_automation.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Sınıflar tablosu
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Dersler tablosu
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Sınıf-Ders ilişki tablosu
    await db.execute('''
      CREATE TABLE class_subjects (
        class_id INTEGER,
        subject_id INTEGER,
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE,
        PRIMARY KEY (class_id, subject_id)
      )
    ''');

    // Öğretmenler tablosu
    await db.execute('''
      CREATE TABLE teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        surname TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Öğrenciler tablosu
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        surname TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        class_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE
      )
    ''');

    // Sınavlar tablosu
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        subject_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Notlar tablosu
    await db.execute('''
      CREATE TABLE grades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        exam_id INTEGER,
        grade REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE,
        UNIQUE(student_id, exam_id)
      )
    ''');

    // Varsayılan verileri ekle
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    try {
      // Varsayılan öğretmen ekle
      await db.insert('teachers', {
        'name': 'Admin/',
        'surname': 'معلم',
        'username': 'admin',
        'password': '123456',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Sınıfları ekle
      final class10a = await db.insert('classes', {
        'name': '10أ',
        'created_at': DateTime.now().toIso8601String(),
      });

      final class10b = await db.insert('classes', {
        'name': '10ب',
        'created_at': DateTime.now().toIso8601String(),
      });

      final class11a = await db.insert('classes', {
        'name': '11أ',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Dersleri ekle
      final matematik = await db.insert('subjects', {
        'name': 'الرياضيات',
        'created_at': DateTime.now().toIso8601String(),
      });

      final fizik = await db.insert('subjects', {
        'name': 'الفيزياء',
        'created_at': DateTime.now().toIso8601String(),
      });

      final kimya = await db.insert('subjects', {
        'name': 'الكيمياء',
        'created_at': DateTime.now().toIso8601String(),
      });

      final biyoloji = await db.insert('subjects', {
        'name': 'الأحياء',
        'created_at': DateTime.now().toIso8601String(),
      });

      final tarih = await db.insert('subjects', {
        'name': 'التاريخ',
        'created_at': DateTime.now().toIso8601String(),
      });

      final cografya = await db.insert('subjects', {
        'name': 'الجغرافيا',
        'created_at': DateTime.now().toIso8601String(),
      });

      final turkce = await db.insert('subjects', {
        'name': 'اللغة التركية',
        'created_at': DateTime.now().toIso8601String(),
      });

      final ingilizce = await db.insert('subjects', {
        'name': 'اللغة الإنجليزية',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Dersleri sınıflara ata
      await db.insert('class_subjects', {
        'class_id': class10a,
        'subject_id': matematik,
      });
      await db.insert('class_subjects', {
        'class_id': class10a,
        'subject_id': fizik,
      });
      await db.insert('class_subjects', {
        'class_id': class10a,
        'subject_id': kimya,
      });
      await db.insert('class_subjects', {
        'class_id': class10a,
        'subject_id': biyoloji,
      });
      await db.insert('class_subjects', {
        'class_id': class10a,
        'subject_id': tarih,
      });
      await db.insert('class_subjects', {
        'class_id': class10a,
        'subject_id': cografya,
      });
      await db.insert('class_subjects', {
        'class_id': class10a,
        'subject_id': turkce,
      });
      await db.insert('class_subjects', {
        'class_id': class10a,
        'subject_id': ingilizce,
      });

      await db.insert('class_subjects', {
        'class_id': class10b,
        'subject_id': matematik,
      });
      await db.insert('class_subjects', {
        'class_id': class10b,
        'subject_id': fizik,
      });
      await db.insert('class_subjects', {
        'class_id': class10b,
        'subject_id': kimya,
      });
      await db.insert('class_subjects', {
        'class_id': class10b,
        'subject_id': biyoloji,
      });
      await db.insert('class_subjects', {
        'class_id': class10b,
        'subject_id': tarih,
      });
      await db.insert('class_subjects', {
        'class_id': class10b,
        'subject_id': cografya,
      });
      await db.insert('class_subjects', {
        'class_id': class10b,
        'subject_id': turkce,
      });
      await db.insert('class_subjects', {
        'class_id': class10b,
        'subject_id': ingilizce,
      });

      await db.insert('class_subjects', {
        'class_id': class11a,
        'subject_id': matematik,
      });
      await db.insert('class_subjects', {
        'class_id': class11a,
        'subject_id': fizik,
      });
      await db.insert('class_subjects', {
        'class_id': class11a,
        'subject_id': kimya,
      });
      await db.insert('class_subjects', {
        'class_id': class11a,
        'subject_id': biyoloji,
      });
      await db.insert('class_subjects', {
        'class_id': class11a,
        'subject_id': tarih,
      });
      await db.insert('class_subjects', {
        'class_id': class11a,
        'subject_id': cografya,
      });
      await db.insert('class_subjects', {
        'class_id': class11a,
        'subject_id': turkce,
      });
      await db.insert('class_subjects', {
        'class_id': class11a,
        'subject_id': ingilizce,
      });

      // Öğrencileri ekle
      final List<Map<String, dynamic>> students = [
        // 10A Sınıfı - 8 öğrenci (4 kız, 4 erkek)
        {
          'name': 'فاطمة',
          'surname': 'أحمد',
          'username': 'fatima.ahmed',
          'password': '123456',
          'class_id': class10a,
        },
        {
          'name': 'عائشة',
          'surname': 'محمد',
          'username': 'aisha.mohammed',
          'password': '123456',
          'class_id': class10a,
        },
        {
          'name': 'خديجة',
          'surname': 'علي',
          'username': 'khadija.ali',
          'password': '123456',
          'class_id': class10a,
        },
        {
          'name': 'مريم',
          'surname': 'حسن',
          'username': 'maryam.hassan',
          'password': '123456',
          'class_id': class10a,
        },
        {
          'name': 'أحمد',
          'surname': 'عبدالله',
          'username': 'ahmed.abdullah',
          'password': '123456',
          'class_id': class10a,
        },
        {
          'name': 'محمد',
          'surname': 'علي',
          'username': 'mohammed.ali',
          'password': '123456',
          'class_id': class10a,
        },
        {
          'name': 'عمر',
          'surname': 'حسين',
          'username': 'omar.hussein',
          'password': '123456',
          'class_id': class10a,
        },
        {
          'name': 'يوسف',
          'surname': 'إبراهيم',
          'username': 'youssef.ibrahim',
          'password': '123456',
          'class_id': class10a,
        },

        // 10B Sınıfı - 9 öğrenci (3 kız, 6 erkek)
        {
          'name': 'نور',
          'surname': 'محمود',
          'username': 'nour.mahmoud',
          'password': '123456',
          'class_id': class10b,
        },
        {
          'name': 'سارة',
          'surname': 'عبدالرحمن',
          'username': 'sara.abdelrahman',
          'password': '123456',
          'class_id': class10b,
        },
        {
          'name': 'ليلى',
          'surname': 'مصطفى',
          'username': 'layla.mustafa',
          'password': '123456',
          'class_id': class10b,
        },
        {
          'name': 'عبدالله',
          'surname': 'أحمد',
          'username': 'abdullah.ahmed',
          'password': '123456',
          'class_id': class10b,
        },
        {
          'name': 'خالد',
          'surname': 'محمد',
          'username': 'khalid.mohammed',
          'password': '123456',
          'class_id': class10b,
        },
        {
          'name': 'علي',
          'surname': 'حسن',
          'username': 'ali.hassan',
          'password': '123456',
          'class_id': class10b,
        },
        {
          'name': 'حسن',
          'surname': 'علي',
          'username': 'hassan.ali',
          'password': '123456',
          'class_id': class10b,
        },
        {
          'name': 'محمود',
          'surname': 'عبدالله',
          'username': 'mahmoud.abdullah',
          'password': '123456',
          'class_id': class10b,
        },
        {
          'name': 'إبراهيم',
          'surname': 'يوسف',
          'username': 'ibrahim.youssef',
          'password': '123456',
          'class_id': class10b,
        },

        // 11A Sınıfı - 8 öğrenci (3 kız, 5 erkek)
        {
          'name': 'زينب',
          'surname': 'علي',
          'username': 'zainab.ali',
          'password': '123456',
          'class_id': class11a,
        },
        {
          'name': 'رنا',
          'surname': 'أحمد',
          'username': 'rana.ahmed',
          'password': '123456',
          'class_id': class11a,
        },
        {
          'name': 'هند',
          'surname': 'محمد',
          'username': 'hind.mohammed',
          'password': '123456',
          'class_id': class11a,
        },
        {
          'name': 'عبدالرحمن',
          'surname': 'علي',
          'username': 'abdelrahman.ali',
          'password': '123456',
          'class_id': class11a,
        },
        {
          'name': 'مصطفى',
          'surname': 'أحمد',
          'username': 'mustafa.ahmed',
          'password': '123456',
          'class_id': class11a,
        },
        {
          'name': 'حسين',
          'surname': 'محمد',
          'username': 'hussein.mohammed',
          'password': '123456',
          'class_id': class11a,
        },
        {
          'name': 'عبدالله',
          'surname': 'علي',
          'username': 'abdullah.ali',
          'password': '123456',
          'class_id': class11a,
        },
        {
          'name': 'يوسف',
          'surname': 'أحمد',
          'username': 'youssef.ahmed',
          'password': '123456',
          'class_id': class11a,
        },
      ];

      for (var studentData in students) {
        await db.insert('students', {
          ...studentData,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Sınavları ekle
      await db.insert('exams', {
        'name': 'امتحان الرياضيات الأول',
        'subject_id': matematik,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('exams', {
        'name': 'امتحان الفيزياء الأول',
        'subject_id': fizik,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('exams', {
        'name': 'امتحان الكيمياء الأول',
        'subject_id': kimya,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('exams', {
        'name': 'امتحان الأحياء الأول',
        'subject_id': biyoloji,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('exams', {
        'name': 'امتحان التاريخ الأول',
        'subject_id': tarih,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('exams', {
        'name': 'امتحان الجغرافيا الأول',
        'subject_id': cografya,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('exams', {
        'name': 'امتحان اللغة التركية الأول',
        'subject_id': turkce,
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('exams', {
        'name': 'امتحان اللغة الإنجليزية الأول',
        'subject_id': ingilizce,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Varsayılan veri eklenirken hata: $e');
    }
  }
}
