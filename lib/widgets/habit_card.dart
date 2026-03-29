import 'package:flutter/material.dart';
import 'arovia_card.dart';

class HabitCard extends StatelessWidget {
  final String habitName;
  final int streak;
  final bool completed;
  final VoidCallback onTap;
  final VoidCallback onCheck;

  const HabitCard({
    super.key,
    required this.habitName,
    required this.streak,
    required this.completed,
    required this.onTap,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AroviaCard(
        child: Row(
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: completed,
                onChanged: (_) => onCheck(),
                activeColor: const Color(0xFF4CAF90),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// Habit icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF90).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.self_improvement,
                color: Color(0xFF4CAF90),
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            /// Habit details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    habitName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [

                      const Text("🔥",
                          style: TextStyle(fontSize: 14)),

                      const SizedBox(width: 4),

                      Text(
                        "$streak day streak",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            )
          ],
        ),
      ),
    );
  }
}