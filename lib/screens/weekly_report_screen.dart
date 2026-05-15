import 'package:flutter/material.dart';
import '../services/weekly_report_service.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  late Future<String> _summaryFuture;
  late Future<List<Map<String, dynamic>>> _weeklyDataFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = WeeklyReportService.generateWeeklySummary();
    _weeklyDataFuture = WeeklyReportService.getWeeklyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Report'),
        backgroundColor: Colors.blue[700],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _summaryFuture = WeeklyReportService.generateWeeklySummary();
            _weeklyDataFuture = WeeklyReportService.getWeeklyData();
          });
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                FutureBuilder<String>(
                  future: _summaryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    return Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SelectableText(
                          snapshot.data ?? '',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            height: 1.8,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Daily breakdown
                const Text(
                  'Daily Breakdown (Last 7 Days)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _weeklyDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    final weeklyData = snapshot.data ?? [];

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: weeklyData.length,
                      itemBuilder: (context, index) {
                        final day = weeklyData[index];
                        final date = day['date'] ?? '';
                        final steps = day['steps'] ?? 0;
                        final calories = day['calories'] ?? 0;
                        final fiber = day['fiber'] ?? 0;

                        // Parse date for day of week
                        DateTime parsedDate = DateTime.parse(date);
                        String dayName = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ][parsedDate.weekday - 1];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$dayName ($date)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '👟 $steps steps',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '🍽️ $calories cal',
                                      style: TextStyle(
                                        color: calories > 2000
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '🥬 ${fiber}g fiber',
                                      style: TextStyle(
                                        color: fiber >= 25
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
