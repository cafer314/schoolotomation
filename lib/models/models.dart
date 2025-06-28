class Class {
  final int? id;
  final String name;
  final String createdAt;

  Class({this.id, required this.name, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'created_at': createdAt};
  }

  factory Class.fromMap(Map<String, dynamic> map) {
    return Class(
      id: map['id'],
      name: map['name'],
      createdAt: map['created_at'],
    );
  }
}

class Subject {
  final int? id;
  final String name;
  final String createdAt;

  Subject({this.id, required this.name, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'created_at': createdAt};
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      createdAt: map['created_at'],
    );
  }
}

class Student {
  final int? id;
  final String name;
  final String surname;
  final String username;
  final String password;
  final int classId;
  final String createdAt;

  Student({
    this.id,
    required this.name,
    required this.surname,
    required this.username,
    required this.password,
    required this.classId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'username': username,
      'password': password,
      'class_id': classId,
      'created_at': createdAt,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      surname: map['surname'],
      username: map['username'],
      password: map['password'],
      classId: map['class_id'],
      createdAt: map['created_at'],
    );
  }
}

class Teacher {
  final int? id;
  final String name;
  final String surname;
  final String username;
  final String password;
  final String createdAt;

  Teacher({
    this.id,
    required this.name,
    required this.surname,
    required this.username,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'username': username,
      'password': password,
      'created_at': createdAt,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      name: map['name'],
      surname: map['surname'],
      username: map['username'],
      password: map['password'],
      createdAt: map['created_at'],
    );
  }
}

class Exam {
  final int? id;
  final String name;
  final int subjectId;
  final String createdAt;

  Exam({
    this.id,
    required this.name,
    required this.subjectId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject_id': subjectId,
      'created_at': createdAt,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'],
      name: map['name'],
      subjectId: map['subject_id'],
      createdAt: map['created_at'],
    );
  }
}

class Grade {
  final int? id;
  final int studentId;
  final int examId;
  final double grade;
  final String createdAt;

  Grade({
    this.id,
    required this.studentId,
    required this.examId,
    required this.grade,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'exam_id': examId,
      'grade': grade,
      'created_at': createdAt,
    };
  }

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      studentId: map['student_id'],
      examId: map['exam_id'],
      grade: map['grade'],
      createdAt: map['created_at'],
    );
  }
}
