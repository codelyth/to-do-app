import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? _getTaskDate(Map<String, dynamic> data) {
    final taskDate = data['taskDate'];
    final createdAt = data['createdAt'];

    if (taskDate is Timestamp) return _dateOnly(taskDate.toDate());
    if (createdAt is Timestamp) return _dateOnly(createdAt.toDate());

    return null;
  }

  List<DateTime> _last7Days() {
    final today = _dateOnly(DateTime.now());
    return List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
  }

  String _dayName(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }

  int _calculateStreak(List<Map<String, dynamic>> tasks) {
    final completedDates = tasks
        .where((task) => task['isCompleted'] == true)
        .map(_getTaskDate)
        .whereType<DateTime>()
        .toSet();

    int streak = 0;
    DateTime current = _dateOnly(DateTime.now());

    while (completedDates.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Map<String, int> _categoryCounts(List<Map<String, dynamic>> tasks) {
    final result = {
      'Today': 0,
      'Planned': 0,
      'Personal': 0,
    };

    for (final task in tasks) {
      final category = (task['category'] ?? 'Planned').toString();

      if (result.containsKey(category)) {
        result[category] = result[category]! + 1;
      } else {
        result['Planned'] = result['Planned']! + 1;
      }
    }

    return result;
  }

  String _motivationalMessage(double score) {
    if (score >= 0.80) return "Amazing work!";
    if (score >= 0.50) return "You're making progress!";
    if (score > 0) return "Keep going!";
    return "Let's get started!";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor =
        isDark ? const Color(0xFF8B8CFF) : const Color(0xFF4B4ACF);
    final bgColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final darkText = isDark ? Colors.white : const Color(0xFF0F172A);
    final lightText =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF8D97AE);
    final shadowColor = Colors.black.withOpacity(isDark ? 0.18 : 0.04);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data?.docs.map((doc) {
                  return doc.data() as Map<String, dynamic>;
                }).toList() ??
                [];

            final total = tasks.length;
            final completed =
                tasks.where((task) => task['isCompleted'] == true).length;
            final pending = total - completed;
            final score = total == 0 ? 0.0 : completed / total;
            final scorePercent = (score * 100).round();

            final last7Days = _last7Days();

            final weeklyCounts = last7Days.map((day) {
              return tasks.where((task) {
                if (task['isCompleted'] != true) return false;
                final taskDate = _getTaskDate(task);
                return taskDate == day;
              }).length;
            }).toList();

            final maxWeeklyValue =
                weeklyCounts.isEmpty ? 1 : weeklyCounts.reduce(math.max);
            final categories = _categoryCounts(tasks);
            final streak = _calculateStreak(tasks);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        "Analytics",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Weekly analytics view'),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.tune,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your productivity overview",
                        style: TextStyle(
                          color: lightText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text("Streak 🔥"),
                                content: Text(
                                  streak == 0
                                      ? "Henüz streak başlamadı. Bugün en az 1 görev tamamlayarak streak başlatabilirsin."
                                      : "$streak gündür en az 1 görev tamamlıyorsun. Harika gidiyorsun!",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Tamam"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
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
                              const Text(
                                "🔥",
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "$streak",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// Hero Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.22),
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
                              Text(
                                _motivationalMessage(score),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "You completed $completed out of $total tasks.",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "$scorePercent% PRODUCTIVE",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 112,
                          height: 112,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 112,
                                height: 112,
                                child: CircularProgressIndicator(
                                  value: score,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "$scorePercent%",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
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

                  _SectionCard(
                    title: "Weekly Activity",
                    cardColor: cardColor,
                    darkText: darkText,
                    shadowColor: shadowColor,
                    child: SizedBox(
                      height: 170,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) {
                          final value = weeklyCounts[index];
                          final ratio =
                              maxWeeklyValue == 0 ? 0.05 : value / maxWeeklyValue;

                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  value.toString(),
                                  style: TextStyle(
                                    color: lightText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 22,
                                  height: 24 + (110 * ratio),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _dayName(last7Days[index]),
                                  style: TextStyle(
                                    color: lightText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      _StatCard(
                        value: completed.toString(),
                        label: "COMPLETED",
                        color: primaryColor,
                        cardColor: cardColor,
                        shadowColor: shadowColor,
                        lightText: lightText,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        value: pending.toString(),
                        label: "PENDING",
                        color: const Color(0xFFDE7A00),
                        cardColor: cardColor,
                        shadowColor: shadowColor,
                        lightText: lightText,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        value: total.toString(),
                        label: "TOTAL",
                        color: const Color(0xFF0F9D6C),
                        cardColor: cardColor,
                        shadowColor: shadowColor,
                        lightText: lightText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _SectionCard(
                    title: "Category Breakdown",
                    cardColor: cardColor,
                    darkText: darkText,
                    shadowColor: shadowColor,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 132,
                          height: 132,
                          child: CustomPaint(
                            painter: _DonutChartPainter(
                              categories,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            children: [
                              _LegendItem(
                                color: primaryColor,
                                label: "Today",
                                value: categories['Today'] ?? 0,
                                darkText: darkText,
                                lightText: lightText,
                              ),
                              const SizedBox(height: 12),
                              _LegendItem(
                                color: const Color(0xFF9B51E0),
                                label: "Planned",
                                value: categories['Planned'] ?? 0,
                                darkText: darkText,
                                lightText: lightText,
                              ),
                              const SizedBox(height: 12),
                              _LegendItem(
                                color: const Color(0xFF0F9D6C),
                                label: "Personal",
                                value: categories['Personal'] ?? 0,
                                darkText: darkText,
                                lightText: lightText,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color cardColor;
  final Color darkText;
  final Color shadowColor;

  const _SectionCard({
    required this.title,
    required this.child,
    required this.cardColor,
    required this.darkText,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color cardColor;
  final Color shadowColor;
  final Color lightText;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.cardColor,
    required this.shadowColor,
    required this.lightText,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 112,
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
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: lightText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final Color darkText;
  final Color lightText;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.darkText,
    required this.lightText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: darkText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            color: lightText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, int> categories;
  final bool isDark;

  _DonutChartPainter(
    this.categories, {
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = categories.values.fold<int>(0, (a, b) => a + b);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = isDark ? const Color(0xFF374151) : const Color(0xFFEDEFF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 12, backgroundPaint);

    if (total == 0) return;

    final colors = {
      'Today': const Color(0xFF4B4ACF),
      'Planned': const Color(0xFF9B51E0),
      'Personal': const Color(0xFF0F9D6C),
    };

    double startAngle = -math.pi / 2;

    categories.forEach((category, value) {
      if (value == 0) return;

      final sweepAngle = (value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[category] ?? const Color(0xFF4B4ACF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 12),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}