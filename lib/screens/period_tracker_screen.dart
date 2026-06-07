import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/period_tracker_service.dart';
import '../widgets/arovia_background.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  Future<Map<String, dynamic>> _statsFuture = Future.value({});
  DateTime? _nextPeriod;
  int? _daysUntil;
  String _currentPhase = 'unknown';
  int _cycleLength = 28;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profileId = await _getActiveProfileId();
    final stats = await PeriodTrackerService.getCycleStats(profileId);
    final nextPeriod = await PeriodTrackerService.predictNextPeriod(profileId);
    final daysUntil = await PeriodTrackerService.daysUntilNextPeriod(profileId);
    final phase = await PeriodTrackerService.getCurrentPhase(profileId);
    final length = await PeriodTrackerService.getCycleLength(profileId);

    setState(() {
      _nextPeriod = nextPeriod;
      _daysUntil = daysUntil;
      _currentPhase = phase;
      _cycleLength = length;
      _statsFuture = Future.value(stats);
    });
  }

  Future<String?> _getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeProfileId');
  }

  void _showAddPeriodDialog() async {
    final profileId = await _getActiveProfileId();
    int flowIntensity = 2;
    String mood = 'neutral';
    String symptoms = '';
    String notes = '';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('📅 Log Period'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date selector with date picker
                Row(
                  children: [
                    const Text('Period Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.pink),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.pink.shade50,
                          ),
                          child: Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Flow Intensity
                const Text('Flow Intensity:', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: flowIntensity.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  label: flowIntensity == 1 ? 'Light' : flowIntensity == 2 ? 'Medium' : 'Heavy',
                  activeColor: Colors.pink.shade400,
                  inactiveColor: Colors.pink.shade200,
                  onChanged: (value) {
                    setState(() => flowIntensity = value.toInt());
                  },
                ),
                const SizedBox(height: 16),

                // Mood
                const Text('Mood:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: ['😢 sad', '😐 neutral', '😊 happy', '😤 irritated'].map((m) {
                    final val = m.split(' ')[1];
                    return FilterChip(
                      label: Text(m),
                      selected: mood == val,
                      selectedColor: Colors.pink.shade200,
                      onSelected: (selected) {
                        setState(() => mood = val);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Symptoms
                const Text('Symptoms (comma-separated):', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  onChanged: (val) => symptoms = val,
                  decoration: InputDecoration(
                    hintText: 'cramps, bloating, headache, fatigue...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    helperText: '💡 Common: cramps, bloating, headache, fatigue, acne',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Notes
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  onChanged: (val) => notes = val,
                  decoration: InputDecoration(
                    hintText: 'Any additional notes...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
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
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final entry = PeriodEntry(
                  date: selectedDate,
                  flowIntensity: flowIntensity,
                  mood: mood,
                  symptoms: symptoms,
                  notes: notes,
                );

                await PeriodTrackerService.addPeriodEntry(entry, profileId);
                Navigator.pop(context);
                _loadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Period logged successfully!'),
                    backgroundColor: Colors.pinkAccent,
                  ),
                );
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCycleSettingsDialog() async {
    final profileId = await _getActiveProfileId();
    final currentLength = await PeriodTrackerService.getCycleLength(profileId);
    int newLength = currentLength;
    DateTime? startDate = await PeriodTrackerService.getCycleStart(profileId);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('⚙️ Cycle Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Average Cycle Length (days):', style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: newLength.toDouble(),
                min: 21,
                max: 35,
                divisions: 14,
                label: '$newLength days',
                onChanged: (value) {
                  setState(() => newLength = value.toInt());
                },
              ),
              const SizedBox(height: 16),
              Text('Current: $currentLength days'),
              if (startDate != null)
                Text('Last cycle start: ${startDate.toLocal().toString().split(' ')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await PeriodTrackerService.setCycleLength(newLength, profileId);
                Navigator.pop(context);
                _loadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Cycle settings updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhaseEmoji(String phase) {
    switch (phase) {
      case 'menstrual':
        return '🔴';
      case 'ovulation':
        return '💛';
      case 'luteal':
        return '🌙';
      default:
        return '❓';
    }
  }

  String _getPhaseName(String phase) {
    switch (phase) {
      case 'menstrual':
        return 'Menstrual Phase';
      case 'ovulation':
        return 'Ovulation Phase';
      case 'luteal':
        return 'Luteal Phase';
      default:
        return 'Unknown Phase';
    }
  }

  String _getPhaseDescription(String phase) {
    switch (phase) {
      case 'menstrual':
        return 'Your period - take it easy and stay hydrated';
      case 'ovulation':
        return 'Peak energy & confidence - go for it!';
      case 'luteal':
        return 'Slow down - focus on rest & nutrition';
      default:
        return 'Enter your first period start date to unlock next-cycle predictions and phase guidance.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Period Tracker 🌿'),
        backgroundColor: const Color(0xFFF4FBF6),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showCycleSettingsDialog,
            tooltip: 'Cycle Settings',
          ),
        ],
      ),
      body: AroviaBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Phase Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getPhaseEmoji(_currentPhase),
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPhaseName(_currentPhase),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getPhaseDescription(_currentPhase),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Next Period Prediction
            if (_daysUntil != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.pink.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📅 Next Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _nextPeriod!.toLocal().toString().split(' ')[0],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.pink,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_daysUntil} days',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.pink.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '📅 First Cycle Start Needed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Log your first period start date above to begin predicting your next cycle and get month-long period guidance.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Log Period Button
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Log Period Today'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _showAddPeriodDialog,
            ),
            const SizedBox(height: 16),

            // Cycle Stats
            FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'Log your first period start date to unlock tracking insights and cycle predictions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final stats = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cycle Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Total Logs'),
                            trailing: Text(
                              '${stats['totalEntries']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Divider(color: Colors.grey.shade400),
                          ListTile(
                            title: const Text('Average Cycle Length'),
                            trailing: Text(
                              '${stats['avgCycleLength']} days',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
