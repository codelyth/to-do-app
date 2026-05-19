import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todolist_app/screens/login_screen.dart';
import 'package:todolist_app/theme/theme_controller.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String get userId => currentUser!.uid;

  Future<void> _logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _getDisplayName(Map<String, dynamic>? userData) {
    final firstName = userData?['firstName']?.toString().trim() ?? '';
    final lastName = userData?['lastName']?.toString().trim() ?? '';

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    if (userData != null &&
        userData['name'] != null &&
        userData['name'].toString().trim().isNotEmpty) {
      return userData['name'];
    }

    if (currentUser?.displayName != null &&
        currentUser!.displayName!.trim().isNotEmpty) {
      return currentUser!.displayName!;
    }

    final email = currentUser?.email ?? '';
    if (email.contains('@')) return email.split('@').first;

    return 'My Profile';
  }

  String _getSubtitle(Map<String, dynamic>? userData) {
    if (userData != null &&
        userData['jobTitle'] != null &&
        userData['jobTitle'].toString().trim().isNotEmpty) {
      return userData['jobTitle'];
    }

    return currentUser?.email ?? 'Task Manager User';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatDueText(Map<String, dynamic> task) {
    final taskDateTs = task['taskDate'] as Timestamp?;
    final priority = (task['priority'] ?? 'Normal').toString();

    if (taskDateTs == null) return priority;

    final taskDate = taskDateTs.toDate();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(taskDate.year, taskDate.month, taskDate.day);

    final diff = due.difference(today).inDays;

    String dueText;
    if (diff == 0) {
      dueText = 'Due today';
    } else if (diff == 1) {
      dueText = 'Due tomorrow';
    } else if (diff > 1) {
      dueText = 'Due in $diff days';
    } else {
      dueText = 'Overdue';
    }

    return '$dueText • $priority';
  }

  IconData _getTaskIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('design') || lower.contains('ui') || lower.contains('ux')) {
      return Icons.design_services;
    } else if (lower.contains('report') ||
        lower.contains('document') ||
        lower.contains('draft')) {
      return Icons.description;
    } else if (lower.contains('meeting')) {
      return Icons.groups;
    } else if (lower.contains('gym')) {
      return Icons.fitness_center;
    } else if (lower.contains('mail')) {
      return Icons.mail_outline;
    }

    return Icons.task_alt;
  }

  Color _getTaskIconBg(String title, bool isDark) {
    final lower = title.toLowerCase();

    if (lower.contains('design') || lower.contains('ui') || lower.contains('ux')) {
      return isDark ? const Color(0xFF32245A) : const Color(0xFFE9E7FA);
    } else if (lower.contains('report') ||
        lower.contains('document') ||
        lower.contains('draft')) {
      return isDark ? const Color(0xFF26345C) : const Color(0xFFE8EAFB);
    } else if (lower.contains('meeting')) {
      return isDark ? const Color(0xFF143A2D) : const Color(0xFFE6F7F0);
    } else if (lower.contains('gym')) {
      return isDark ? const Color(0xFF143A2D) : const Color(0xFFDDF5E9);
    }

    return isDark ? const Color(0xFF374151) : const Color(0xFFEDEFF5);
  }

  Color _getTaskIconColor(String title, bool isDark, Color primaryColor) {
    final lower = title.toLowerCase();

    if (lower.contains('design') || lower.contains('ui') || lower.contains('ux')) {
      return primaryColor;
    } else if (lower.contains('report') ||
        lower.contains('document') ||
        lower.contains('draft')) {
      return isDark ? const Color(0xFF9CA3FF) : const Color(0xFF4B4ACF);
    } else if (lower.contains('meeting') || lower.contains('gym')) {
      return isDark ? const Color(0xFF7BE7A4) : const Color(0xFF0F9D6C);
    }

    return isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
  }

  Future<void> _showEditProfileDialog(
    Map<String, dynamic>? userData,
    Color primaryColor,
  ) async {
    final firstNameController = TextEditingController(
      text: userData?['firstName']?.toString() ?? '',
    );
    final lastNameController = TextEditingController(
      text: userData?['lastName']?.toString() ?? '',
    );
    final jobTitleController = TextEditingController(
      text: userData?['jobTitle']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: jobTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Title',
                    border: OutlineInputBorder(),
                  ),
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
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();
                final jobTitle = jobTitleController.text.trim();

                await _firestore.collection('users').doc(userId).set({
                  'firstName': firstName,
                  'lastName': lastName,
                  'name': '$firstName $lastName'.trim(),
                  'jobTitle': jobTitle,
                  'email': currentUser?.email ?? '',
                  'isPro': true,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
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
  }

  void _showSettingsSheet(
    Map<String, dynamic>? userData,
    Color primaryColor,
    Color cardColor,
    Color darkText,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: primaryColor),
                  title: Text(
                    'Edit Profile',
                    style: TextStyle(color: darkText),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditProfileDialog(userData, primaryColor);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.refresh, color: primaryColor),
                  title: Text(
                    'Refresh',
                    style: TextStyle(color: darkText),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: primaryColor),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: darkText),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllTasksSheet(
    List<QueryDocumentSnapshot> docs,
    Color cardColor,
    Color darkText,
    Color lightText,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    'All Tasks',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final completed = data['isCompleted'] == true;
                        return ListTile(
                          leading: Icon(
                            completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: completed ? primaryColor : lightText,
                          ),
                          title: Text(
                            data['title'] ?? '',
                            style: TextStyle(color: darkText),
                          ),
                          subtitle: Text(
                            _formatDueText(data),
                            style: TextStyle(color: lightText),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color primaryColor,
    Color cardColor,
    Color lightText,
    Color shadowColor,
  ) {
    return Expanded(
      child: Container(
        height: 118,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(Color primaryColor, Color darkText, Color cardColor) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, themeMode, child) {
        final isDark = themeMode == ThemeMode.dark;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 6),
              Switch(
                value: isDark,
                activeColor: primaryColor,
                onChanged: (value) {
                  ThemeController.setDarkMode(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(
    String docId,
    Map<String, dynamic> task,
    Color primaryColor,
  ) async {
    final titleController = TextEditingController(text: task['title'] ?? '');
    final descriptionController =
        TextEditingController(text: task['description'] ?? '');
    final priorityOptions = ['Low', 'Normal', 'High'];
    String selectedPriority = (task['priority'] ?? 'Normal').toString();

    DateTime selectedDate;
    final ts = task['taskDate'] as Timestamp?;
    if (ts != null) {
      final d = ts.toDate();
      selectedDate = DateTime(d.year, d.month, d.day);
    } else {
      selectedDate = DateTime.now();
    }

    if (!priorityOptions.contains(selectedPriority)) {
      selectedPriority = 'Normal';
    }

    await showDialog(
      context: context,
      builder: (context) {
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
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: priorityOptions
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            ),
                          )
                          .toList(),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task title cannot be empty'),
                        ),
                      );
                      return;
                    }

                    await _firestore.collection('tasks').doc(docId).update({
                      'title': title,
                      'description': description,
                      'priority': selectedPriority,
                      'taskDate': Timestamp.fromDate(
                        DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor =
        isDark ? const Color(0xFF8B8CFF) : const Color(0xFF4B4ACF);
    final bgColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final darkText = isDark ? Colors.white : const Color(0xFF0F172A);
    final lightText =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF8D97AE);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final shadowColor = Colors.black.withOpacity(isDark ? 0.18 : 0.05);
    final badgeBg = isDark ? const Color(0xFF32245A) : const Color(0xFFE8E7F8);

    return Scaffold(
      backgroundColor: bgColor,
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
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = taskSnapshot.data?.docs ?? [];

                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aCreated = aData['createdAt'] as Timestamp?;
                  final bCreated = bData['createdAt'] as Timestamp?;

                  if (aCreated == null && bCreated == null) return 0;
                  if (aCreated == null) return 1;
                  if (bCreated == null) return -1;

                  return bCreated.compareTo(aCreated);
                });

                final completedCount = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isCompleted'] == true;
                }).length;

                final pendingCount = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isCompleted'] != true;
                }).length;

                final totalCount = docs.length;
                final score = totalCount == 0
                    ? 0
                    : ((completedCount / totalCount) * 100).round();

                final activeTasks = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isCompleted'] != true;
                }).toList();

                final displayName = _getDisplayName(userData);
                final subtitle = _getSubtitle(userData);
                final isPro = userData?['isPro'] ?? true;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _showSettingsSheet(
                              userData,
                              primaryColor,
                              cardColor,
                              darkText,
                            ),
                            icon: Icon(
                              Icons.settings,
                              color: primaryColor,
                              size: 34,
                            ),
                          ),
                          Text(
                            'My Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),
                          IconButton(
                            onPressed: _logout,
                            icon: Icon(
                              Icons.logout,
                              color: primaryColor,
                              size: 34,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Divider(color: borderColor),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildThemeSwitch(
                          primaryColor,
                          darkText,
                          cardColor,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const SizedBox(height: 16),

                      /// profile area
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 168,
                              height: 168,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6AAEEA),
                                    Color(0xFF4B8AC7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.14),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(displayName),
                                  style: const TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: lightText,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (isPro)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'Pro Member',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 34),

                      /// stats
                      Row(
                        children: [
                          _buildStatCard(
                            completedCount.toString(),
                            'COMPLETED',
                            primaryColor,
                            cardColor,
                            lightText,
                            shadowColor,
                          ),
                          _buildStatCard(
                            pendingCount.toString(),
                            'PENDING',
                            primaryColor,
                            cardColor,
                            lightText,
                            shadowColor,
                          ),
                          _buildStatCard(
                            '$score%',
                            'SCORE',
                            primaryColor,
                            cardColor,
                            lightText,
                            shadowColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 34),

                      /// section title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Tasks',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAllTasksSheet(
                              docs,
                              cardColor,
                              darkText,
                              lightText,
                              primaryColor,
                            ),
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (activeTasks.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'No active tasks right now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: lightText,
                              ),
                            ),
                          ),
                        )
                      else
                        ...activeTasks.take(5).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final title = data['title'] ?? '';
                          final taskSubtitle = _formatDueText(data);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: shadowColor,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: _getTaskIconBg(title, isDark),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      _getTaskIcon(title),
                                      color: _getTaskIconColor(
                                        title,
                                        isDark,
                                        primaryColor,
                                      ),
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: darkText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          taskSubtitle,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: lightText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showEditTaskDialog(
                                      doc.id,
                                      data,
                                      primaryColor,
                                    ),
                                    icon: Icon(
                                      Icons.edit,
                                      color: lightText,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteTask(doc.id),
                                    icon: Icon(
                                      Icons.delete,
                                      color: lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 8),
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
}