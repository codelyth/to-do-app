import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String category;
  final String priority;
  final String? time;
  final bool isCompleted;
  final String userId;
  final Timestamp createdAt;
  final Timestamp? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.time,
    required this.isCompleted,
    required this.userId,
    required this.createdAt,
    this.completedAt,
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'Planned',
      priority: map['priority'] ?? 'LOW',
      time: map['time'],
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      completedAt: map['completedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'priority': priority,
      'time': time,
      'isCompleted': isCompleted,
      'userId': userId,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? category,
    String? priority,
    String? time,
    bool? isCompleted,
    String? userId,
    Timestamp? createdAt,
    Timestamp? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}