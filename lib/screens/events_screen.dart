import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final startWeekday = firstDayOfMonth.weekday % 7;
    final firstToDisplay =
        firstDayOfMonth.subtract(Duration(days: startWeekday));

    return List.generate(
      42,
      (index) => firstToDisplay.add(Duration(days: index)),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _taskTimeText(Map<String, dynamic> task) {
    final startHour = task['startHour'];
    final startMinute = task['startMinute'];
    final endHour = task['endHour'];
    final endMinute = task['endMinute'];

    if (startHour == null || startMinute == null) {
      return 'No time selected';
    }

    final start = _formatTime(startHour, startMinute);

    if (endHour == null || endMinute == null) {
      return start;
    }

    final end = _formatTime(endHour, endMinute);
    return '$start - $end';
  }

  Future<void> _toggleTask(String docId, bool currentValue) async {
    await _firestore.collection('tasks').doc(docId).update({
      'isCompleted': !currentValue,
    });
  }

  Future<void> _deleteTask(String docId) async {
    await _firestore.collection('tasks').doc(docId).delete();
  }

  Future<void> _showAddTaskDialog(Color primaryColor) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                          initialTime: TimeOfDay.now(),
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
                          initialTime: TimeOfDay.now(),
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
                        const SnackBar(content: Text('Title cannot be empty')),
                      );
                      return;
                    }

                    final selectedDateOnly = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                    );

                    await _firestore.collection('tasks').add({
                      'title': title,
                      'description': description,
                      'isCompleted': false,
                      'userId': userId,
                      'createdAt': FieldValue.serverTimestamp(),
                      'taskDate': Timestamp.fromDate(selectedDateOnly),
                      'startHour': startTime?.hour,
                      'startMinute': startTime?.minute,
                      'endHour': endTime?.hour,
                      'endMinute': endTime?.minute,
                      'category': 'Planned',
                      'priority': 'Normal',
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
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

  IconData _getTaskIcon(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('gym') || lower.contains('workout')) {
      return Icons.fitness_center;
    } else if (lower.contains('lunch') || lower.contains('dinner')) {
      return Icons.restaurant;
    } else if (lower.contains('meeting') || lower.contains('standup')) {
      return Icons.access_time;
    } else if (lower.contains('mail') || lower.contains('email')) {
      return Icons.done_all;
    }

    return Icons.event_note;
  }

  Color _getTaskIconBg(String title, bool isDark) {
    final lower = title.toLowerCase();

    if (lower.contains('gym') || lower.contains('workout')) {
      return isDark ? const Color(0xFF143A2D) : const Color(0xFFD8F3E8);
    } else if (lower.contains('lunch') || lower.contains('dinner')) {
      return isDark ? const Color(0xFF4A3515) : const Color(0xFFF6E9B8);
    } else if (lower.contains('meeting') || lower.contains('standup')) {
      return isDark ? const Color(0xFF32245A) : const Color(0xFFE8E6F7);
    } else if (lower.contains('mail') || lower.contains('email')) {
      return isDark ? const Color(0xFF374151) : const Color(0xFFE8EDF5);
    }

    return isDark ? const Color(0xFF374151) : const Color(0xFFEAECEF);
  }

  Color _getTaskIconColor(String title, bool isDark, Color primaryColor) {
    final lower = title.toLowerCase();

    if (lower.contains('gym') || lower.contains('workout')) {
      return isDark ? const Color(0xFF7BE7A4) : const Color(0xFF0F9D6C);
    } else if (lower.contains('lunch') || lower.contains('dinner')) {
      return isDark ? const Color(0xFFFFC56D) : const Color(0xFFDE7A00);
    } else if (lower.contains('meeting') || lower.contains('standup')) {
      return primaryColor;
    } else if (lower.contains('mail') || lower.contains('email')) {
      return isDark ? const Color(0xFFCBD5E1) : const Color(0xFFA0AABA);
    }

    return isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(currentMonth);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor =
        isDark ? const Color(0xFF8B8CFF) : const Color(0xFF4B4ACF);
    final bgColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final darkText = isDark ? Colors.white : const Color(0xFF0F172A);
    final lightText =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8);
    final fadedText =
        isDark ? const Color(0xFF4B5563) : const Color(0xFFD3DCE8);
    final iconColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF243B63);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFD8DEE8);
    final shadowColor = Colors.black.withOpacity(isDark ? 0.18 : 0.05);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: primaryColor,
          elevation: 0,
          onPressed: () => _showAddTaskDialog(primaryColor),
          child: const Icon(
            Icons.add,
            size: 34,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('tasks')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            final taskDates = docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['taskDate'] as Timestamp?;
                  if (ts == null) return null;
                  final d = ts.toDate();
                  return DateTime(d.year, d.month, d.day);
                })
                .whereType<DateTime>()
                .toSet();

            final selectedDayTasks = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['taskDate'] as Timestamp?;
              if (ts == null) return false;
              final d = ts.toDate();
              return _isSameDay(d, selectedDate);
            }).toList();

            selectedDayTasks.sort((a, b) {
              final ad = a.data() as Map<String, dynamic>;
              final bd = b.data() as Map<String, dynamic>;

              final aHour = ad['startHour'] ?? 99;
              final aMinute = ad['startMinute'] ?? 99;
              final bHour = bd['startHour'] ?? 99;
              final bMinute = bd['startMinute'] ?? 99;

              final aTotal = aHour * 60 + aMinute;
              final bTotal = bHour * 60 + bMinute;

              return aTotal.compareTo(bTotal);
            });

            final remainingCount = selectedDayTasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['isCompleted'] != true;
            }).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 32,
                        color: iconColor,
                      ),
                      Text(
                        "Calendar",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),
                      Icon(
                        Icons.search,
                        size: 32,
                        color: iconColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  /// month selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(
                              currentMonth.year,
                              currentMonth.month - 1,
                            );
                          });
                        },
                        icon: Icon(
                          Icons.chevron_left,
                          size: 30,
                          color: darkText,
                        ),
                      ),
                      Text(
                        "${_monthName(currentMonth.month)} ${currentMonth.year}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(
                              currentMonth.year,
                              currentMonth.month + 1,
                            );
                          });
                        },
                        icon: Icon(
                          Icons.chevron_right,
                          size: 30,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _WeekDayLabel("S", lightText),
                      _WeekDayLabel("M", lightText),
                      _WeekDayLabel("T", lightText),
                      _WeekDayLabel("W", lightText),
                      _WeekDayLabel("T", lightText),
                      _WeekDayLabel("F", lightText),
                      _WeekDayLabel("S", lightText),
                    ],
                  ),

                  const SizedBox(height: 18),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: days.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final isSelected = _isSameDay(day, selectedDate);
                      final isCurrentMonth = _isSameMonth(day, currentMonth);
                      final hasTask = taskDates.any((d) => _isSameDay(d, day));

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = day;
                            currentMonth = DateTime(day.year, day.month);
                          });
                        },
                        child: Container(
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.22),
                                      blurRadius: 12,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                )
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${day.day}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : isCurrentMonth
                                          ? darkText
                                          : fadedText,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (hasTask && !isSelected)
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(height: 7),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 26),

                  Center(
                    child: Container(
                      width: 88,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFD9DEE8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Events",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),
                      Text(
                        "$remainingCount events left",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  if (selectedDayTasks.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
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
                          "No events for this day",
                          style: TextStyle(
                            fontSize: 16,
                            color: lightText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
                    ...selectedDayTasks.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final completed = data['isCompleted'] == true;
                      final title = data['title'] ?? '';
                      final timeText = _taskTimeText(data);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _TaskCard(
                          title: title,
                          time: timeText,
                          icon: _getTaskIcon(title),
                          iconBg: _getTaskIconBg(title, isDark),
                          iconColor:
                              _getTaskIconColor(title, isDark, primaryColor),
                          completed: completed,
                          cardColor: cardColor,
                          darkText: darkText,
                          lightText: lightText,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                          shadowColor: shadowColor,
                          onCheck: () => _toggleTask(doc.id, completed),
                          onDelete: () => _deleteTask(doc.id),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _WeekDayLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool completed;
  final Color cardColor;
  final Color darkText;
  final Color lightText;
  final Color borderColor;
  final Color primaryColor;
  final Color shadowColor;
  final VoidCallback onCheck;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.title,
    required this.time,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.completed,
    required this.cardColor,
    required this.darkText,
    required this.lightText,
    required this.borderColor,
    required this.primaryColor,
    required this.shadowColor,
    required this.onCheck,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(completed ? 0.72 : 1),
        borderRadius: BorderRadius.circular(28),
        border: completed ? Border.all(color: borderColor) : null,
        boxShadow: completed
            ? []
            : [
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
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: darkText.withOpacity(completed ? 0.55 : 1),
                    decoration: completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: lightText.withOpacity(completed ? 0.65 : 1),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onCheck,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                    color: completed ? primaryColor : cardColor,
                  ),
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete_outline,
                  color: lightText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}