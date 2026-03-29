import 'package:flutter/material.dart';
import '../widgets/arovia_background.dart';

class HabitHistoryScreen extends StatelessWidget {
  final String habitName;
  final List<bool> history;

  const HabitHistoryScreen({
    super.key,
    required this.habitName,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Scaffold(
      appBar: AppBar(
        title: Text(habitName),
        backgroundColor: const Color(0xFF4CAF90),
      ),
      body: AroviaBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Last 7 Days",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) {

                  final completed = history[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0,4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        Text(days[index]),

                        Icon(
                          completed
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: completed
                              ? const Color(0xFF4CAF90)
                              : Colors.redAccent,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}