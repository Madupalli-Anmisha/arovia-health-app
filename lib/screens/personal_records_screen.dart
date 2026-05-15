import 'package:flutter/material.dart';
import '../services/weekly_report_service.dart';

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({Key? key}) : super(key: key);

  @override
  State<PersonalRecordsScreen> createState() => _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState extends State<PersonalRecordsScreen> {
  late Future<String> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = WeeklyReportService.getPersonalRecordsDisplay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Records'),
        backgroundColor: Colors.orange[700],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _recordsFuture =
                WeeklyReportService.getPersonalRecordsDisplay();
          });
        },
        child: FutureBuilder<String>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final recordsText = snapshot.data ?? 'No records yet';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Records display
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SelectableText(
                          recordsText,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            height: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
