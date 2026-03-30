import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashScreen extends StatefulWidget {
  const DashScreen({super.key});

  @override
  State<DashScreen> createState() => _DashScreenState();
}

class _DashScreenState extends State<DashScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Color primaryColor = const Color(0xFF4B4ACF);
  final Color bgColor = const Color(0xFFF5F6FA);
  final Color darkText = const Color(0xFF0F172A);
  final Color lightText = const Color(0xFF8D97AE);

  String selectedTab = 'Today';

  User? get currentUser => _auth.currentUser;
  String get userId => currentUser!.uid;

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 18) return "Good Afternoon,";
    return "Good Evening,";
  }

  String _userName(Map<String, dynamic>? userData) {
    final firstName = userData?['firstName']?.toString().trim() ?? '';
    final lastName = userData?['lastName']?.toString().trim() ?? '';

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    if (userData != null &&
        userData['name'] != null &&
        userData['name'].toString().trim().isNotEmpty) {
      return userData['name'].toString();
    }

    final email = currentUser?.email ?? 'User';
    if (email.contains('@')) return email.split('@').first;
    return email;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTimeRange(Map<String, dynamic> task) {
    final startHour = task['startHour'];
    final startMinute = task['startMinute'];
    final endHour = task['endHour'];
    final endMinute = task['endMinute'];

    if (startHour == null || startMinute == null) return '';

    final start = _formatTime(startHour, startMinute);

    if (endHour == null || endMinute == null) return start;

    final end = _formatTime(endHour, endMinute);
    return '$start - $end';
  }

  String _priorityText(String priority) {
    switch (priority) {
      case 'High':
        return 'HIGH PRIORITY';
      case 'Low':
        return 'LOW PRIORITY';
      default:
        return 'NORMAL';
    }
  }

  Color _priorityBgColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFFFE3E3);
      case 'Low':
        return const Color(0xFFE3F7EA);
      default:
        return const Color(0xFFF0E5FF);
    }
  }

  Color _priorityTextColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFD64545);
      case 'Low':
        return const Color(0xFF15803D);
      default:
        return const Color(0xFF9B51E0);
    }
  }

  Future<void> _toggleTaskComplete(String docId, bool currentValue) async {
    await _firestore.collection('tasks').doc(docId).update({
      'isCompleted': !currentValue,
    });
  }

  Future<void> _deleteTask(String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _firestore.collection('tasks').doc(docId).delete();
    }
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final categoryOptions = ['Today', 'Planned', 'Personal'];
    final priorityOptions = ['Low', 'Normal', 'High'];

    String selectedCategory = selectedTab;
    String selectedPriority = 'Normal';
    DateTime selectedDate = DateTime.now();
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: categoryOptions.contains(selectedCategory)
                          ? selectedCategory
                          : 'Today',
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categoryOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: priorityOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedPriority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        startTime == null
                            ? 'Select start time'
                            : 'Start: ${startTime!.format(context)}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startTime = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        endTime == null
                            ? 'Select end time'
                            : 'End: ${endTime!.format(context)}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task title cannot be empty')),
                      );
                      return;
                    }

                    try {
                      await _firestore.collection('tasks').add({
                        'title': title,
                        'description': description,
                        'category': selectedCategory,
                        'priority': selectedPriority,
                        'isCompleted': false,
                        'userId': userId,
                        'createdAt': FieldValue.serverTimestamp(),
                        'taskDate': Timestamp.fromDate(
                          DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                          ),
                        ),
                        'startHour': startTime?.hour,
                        'startMinute': startTime?.minute,
                        'endHour': endTime?.hour,
                        'endMinute': endTime?.minute,
                      });

                      if (!mounted) return;
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task added successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding task: $e')),
                      );
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(String docId, Map<String, dynamic> task) async {
    final titleController = TextEditingController(text: task['title'] ?? '');
    final descriptionController = TextEditingController(text: task['description'] ?? '');

    final categoryOptions = ['Today', 'Planned', 'Personal'];
    final priorityOptions = ['Low', 'Normal', 'High'];

    String selectedCategory = (task['category'] ?? 'Planned').toString();
    String selectedPriority = (task['priority'] ?? 'Normal').toString();

    if (!categoryOptions.contains(selectedCategory)) {
      selectedCategory = 'Planned';
    }

    if (!priorityOptions.contains(selectedPriority)) {
      selectedPriority = 'Normal';
    }

    DateTime selectedDate;
    final ts = task['taskDate'] as Timestamp?;
    if (ts != null) {
      final d = ts.toDate();
      selectedDate = DateTime(d.year, d.month, d.day);
    } else {
      selectedDate = DateTime.now();
    }

    TimeOfDay? startTime = task['startHour'] != null && task['startMinute'] != null
        ? TimeOfDay(hour: task['startHour'], minute: task['startMinute'])
        : null;

    TimeOfDay? endTime = task['endHour'] != null && task['endMinute'] != null
        ? TimeOfDay(hour: task['endHour'], minute: task['endMinute'])
        : null;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categoryOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: priorityOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedPriority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        startTime == null
                            ? 'Select start time'
                            : 'Start: ${startTime!.format(context)}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startTime = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        endTime == null
                            ? 'Select end time'
                            : 'End: ${endTime!.format(context)}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();

                    if (title.isEmpty) return;

                    await _firestore.collection('tasks').doc(docId).update({
                      'title': title,
                      'description': description,
                      'category': selectedCategory,
                      'priority': selectedPriority,
                      'taskDate': Timestamp.fromDate(
                        DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        ),
                      ),
                      'startHour': startTime?.hour,
                      'startMinute': startTime?.minute,
                      'endHour': endTime?.hour,
                      'endMinute': endTime?.minute,
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskMenu(
    BuildContext context,
    String docId,
    Map<String, dynamic> task,
    Offset position,
  ) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem<String>(
          value: 'edit',
          child: Text('Edit'),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    );

    if (selected == 'edit') {
      _showEditTaskDialog(docId, task);
    } else if (selected == 'delete') {
      _deleteTask(docId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 34),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(userId).snapshots(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tasks')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                final allTasks = docs.map((doc) {
                  return {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  };
                }).toList();

                final now = DateTime.now();
                final todayOnly = DateTime(now.year, now.month, now.day);

                final filteredTasks = allTasks.where((task) {
                  final category = (task['category'] ?? 'Planned').toString();

                  if (selectedTab == 'Today') {
                    final ts = task['taskDate'] as Timestamp?;
                    if (ts == null) return category == 'Today';

                    final d = ts.toDate();
                    final taskDay = DateTime(d.year, d.month, d.day);
                    return category == 'Today' || _isSameDay(taskDay, todayOnly);
                  }

                  return category == selectedTab;
                }).toList();

                filteredTasks.sort((a, b) {
                  final aCompleted = a['isCompleted'] == true;
                  final bCompleted = b['isCompleted'] == true;

                  if (aCompleted != bCompleted) {
                    return aCompleted ? 1 : -1;
                  }

                  final aTs = a['taskDate'] as Timestamp?;
                  final bTs = b['taskDate'] as Timestamp?;

                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;

                  return aTs.compareTo(bTs);
                });

                final completedCount =
                    filteredTasks.where((task) => task['isCompleted'] == true).length;
                final totalCount = filteredTasks.length;
                final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingText(),
                        style: TextStyle(
                          fontSize: 18,
                          color: lightText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _userName(userData),
                              style: TextStyle(
                                fontSize: 28,
                                color: darkText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Stack(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F1FA),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.notifications_none,
                                  size: 30,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.20),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Your Daily Goal",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    "You've finished\n$completedCount out of $totalCount tasks.",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: const Text(
                                      "VIEW ANALYTICS",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 13,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${(progress * 100).round()}%",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          _buildTab("Today"),
                          const SizedBox(width: 10),
                          _buildTab("Planned"),
                          const SizedBox(width: 10),
                          _buildTab("Personal"),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tasks",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),
                          Text(
                            "${filteredTasks.length} item",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      if (filteredTasks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "No tasks in this section",
                              style: TextStyle(
                                color: lightText,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else
                        ...filteredTasks.map((task) {
                          final docId = task['id'] as String;
                          final title = (task['title'] ?? '').toString();
                          final description = (task['description'] ?? '').toString();
                          final priority = (task['priority'] ?? 'Normal').toString();
                          final completed = task['isCompleted'] == true;
                          final timeText = _formatTimeRange(task);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _toggleTaskComplete(docId, completed),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                          width: 2,
                                        ),
                                        color: completed ? primaryColor : Colors.white,
                                      ),
                                      child: completed
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 22,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: darkText,
                                            decoration: completed
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 7,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _priorityBgColor(priority),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _priorityText(priority),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: _priorityTextColor(priority),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                timeText.isEmpty
                                                    ? "No time selected"
                                                    : timeText,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: lightText,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (description.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            description,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: lightText,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Builder(
                                    builder: (buttonContext) {
                                      return GestureDetector(
                                        onTapDown: (details) {
                                          _showTaskMenu(
                                            buttonContext,
                                            docId,
                                            task,
                                            details.globalPosition,
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.more_vert,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = selectedTab == label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 52,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : const Color(0xFFF0F1F6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}