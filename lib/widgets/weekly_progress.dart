import 'package:flutter/material.dart';

class WeeklyProgress extends StatelessWidget {
  final List<bool> weekData;

  const WeeklyProgress({super.key, required this.weekData});

  @override
  Widget build(BuildContext context) {

    const days = ["M","T","W","T","F","S","S"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0,4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Weekly Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {

              final completed = weekData[index];

              return Column(
                children: [

                  Icon(
                    completed
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: completed
                        ? const Color(0xFF4CAF90)
                        : Colors.grey,
                  ),

                  const SizedBox(height: 4),

                  Text(days[index]),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}