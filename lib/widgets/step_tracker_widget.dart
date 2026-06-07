import 'package:flutter/material.dart';
import '../services/enhanced_step_tracker_service.dart';
import 'dart:developer' as developer;

class StepTrackerWidget extends StatefulWidget {
  final int todaySteps;
  final int stepGoal;
  final VoidCallback onRefresh;

  const StepTrackerWidget({
    super.key,
    required this.todaySteps,
    required this.stepGoal,
    required this.onRefresh,
  });

  @override
  State<StepTrackerWidget> createState() => _StepTrackerWidgetState();
}

class _StepTrackerWidgetState extends State<StepTrackerWidget> {
  late TextEditingController _stepsController;
  bool _isLoading = false;
  String? _trackerMode;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController(text: widget.todaySteps.toString());
    _loadTrackerMode();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _loadTrackerMode() async {
    final mode = EnhancedStepTrackerService.getTrackerMode();
    setState(() {
      _trackerMode = mode;
    });
  }

  Future<void> _updateSteps(int newSteps) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await EnhancedStepTrackerService.setManualSteps(newSteps);
      widget.onRefresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Steps updated to $newSteps'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('Error updating steps: $e', name: 'StepTrackerWidget');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📱 Update Steps'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current: ${widget.todaySteps} / ${widget.stepGoal} steps',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_trackerMode == 'manual')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ Manual mode: Sensor unavailable. Enter steps manually from your watch/phone.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter total steps for today',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.directions_walk),
              ),
            ),
            const SizedBox(height: 12),
            if (_trackerMode == 'manual')
              const Text(
                '💡 Tip: If you have a smartwatch, check your daily steps there and enter the total.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    final newSteps = int.tryParse(_stepsController.text) ?? 0;
                    Navigator.pop(context);
                    _updateSteps(newSteps);
                  },
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.stepGoal > 0 ? widget.todaySteps / widget.stepGoal : 0;
    final isGoalReached = widget.todaySteps >= widget.stepGoal;
    final statusColor = isGoalReached ? Colors.green : Colors.blue;
    final statusEmoji = isGoalReached ? '✅' : '🚶';

    return Card(
      elevation: 2,
      color: statusColor.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$statusEmoji Step Tracker',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_trackerMode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _trackerMode == 'sensor' ? Colors.green.shade200 : Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _trackerMode == 'sensor' ? '📡 Auto' : '✏️ Manual',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _trackerMode == 'sensor' ? Colors.green.shade900 : Colors.orange.shade900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${widget.todaySteps}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  ' / ${widget.stepGoal}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: statusColor.withAlpha(75),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% of daily goal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _showManualInputDialog,
                icon: const Icon(Icons.edit),
                label: Text(_trackerMode == 'manual' ? 'Enter Steps' : 'Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                ),
              ),
            ),
            if (_trackerMode == 'manual')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '⚠️ Sensor not detected. Using manual mode. You can sync from your smartwatch or fitness app.',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
