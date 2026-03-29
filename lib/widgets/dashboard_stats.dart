import 'package:flutter/material.dart';
import 'arovia_card.dart';

class DashboardStats extends StatelessWidget {
  final int streak;
  final int level;
  final int totalDays;

  const DashboardStats({
    super.key,
    required this.streak,
    required this.level,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    return AroviaCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          stat("🔥", streak, "Streak"),
          stat("🏆", level, "Level"),
          stat("📅", totalDays, "Days"),
        ],
      ),
    );
  }

  Widget stat(String icon, int value, String label) {

    double progress = value / 10;
    if (progress > 1) progress = 1;

    return Column(
      children: [

        Stack(
          alignment: Alignment.center,
          children: [

            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(
                  Color(0xFF4CAF90),
                ),
              ),
            ),

            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}