import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference get _tasks => _firestore.collection('tasks');

  Stream<List<TaskModel>> getTasks() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();

    return _tasks
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs.map((doc) {
        return TaskModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  Future<void> addTask({
    required String title,
    required String category,
    required String priority,
    String? time,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _tasks.add({
      'title': title,
      'category': category,
      'priority': priority,
      'time': time,
      'isCompleted': false,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });
  }

  Future<void> updateTask(TaskModel task) async {
    await _tasks.doc(task.id).update({
      'title': task.title,
      'category': task.category,
      'priority': task.priority,
      'time': task.time,
    });
  }

  Future<void> toggleTask(TaskModel task) async {
    await _tasks.doc(task.id).update({
      'isCompleted': !task.isCompleted,
      'completedAt': !task.isCompleted ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _tasks.doc(taskId).delete();
  }
}