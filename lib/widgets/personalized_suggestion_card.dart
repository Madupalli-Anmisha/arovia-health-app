import 'package:flutter/material.dart';
import '../services/health_profile_service.dart';
import '../services/llm_suggestion_service.dart';

class PersonalizedSuggestionCard extends StatefulWidget {
  final String foodConsumed;
  final int caloriesConsumed;
  final int dailyCalorieGoal;
  final int totalCaloriesToday;
  final HealthProfile healthProfile;
  final VoidCallback onDismiss;
  
  const PersonalizedSuggestionCard({
    super.key,
    required this.foodConsumed,
    required this.caloriesConsumed,
    required this.dailyCalorieGoal,
    required this.totalCaloriesToday,
    required this.healthProfile,
    required this.onDismiss,
  });

  @override
  State<PersonalizedSuggestionCard> createState() =>
      _PersonalizedSuggestionCardState();
}

class _PersonalizedSuggestionCardState extends State<PersonalizedSuggestionCard> {
  late Future<String> _suggestionFuture;
  
  @override
  void initState() {
    super.initState();
    _suggestionFuture = LLMSuggestionService.getMealSuggestion(
      foodConsumed: widget.foodConsumed,
      caloriesConsumed: widget.caloriesConsumed,
      dailyGoal: widget.dailyCalorieGoal,
      caloriesSoFar: widget.totalCaloriesToday,
      healthConditions: widget.healthProfile.healthConditions,
      age: widget.healthProfile.age,
      gender: widget.healthProfile.gender,
    );
  }

  @override
  Widget build(BuildContext context) {
    final caloriesRemaining = widget.dailyCalorieGoal - widget.totalCaloriesToday;
    final percentOfGoal = ((widget.totalCaloriesToday / widget.dailyCalorieGoal) * 100).toStringAsFixed(0);
    
    // Determine card color based on calorie intake
    final cardColor = caloriesRemaining > 500
        ? Colors.green[50]
        : caloriesRemaining > 200
            ? Colors.orange[50]
            : Colors.red[50];
    
    final accentColor = caloriesRemaining > 500
        ? Colors.green
        : caloriesRemaining > 200
            ? Colors.orange
            : Colors.red;

    return Dismissible(
      key: Key(widget.foodConsumed),
      onDismissed: (_) => widget.onDismiss(),
      child: Card(
        color: cardColor,
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withOpacity(0.5), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with food name and emoji
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Just Ate 🍽️',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.foodConsumed,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.caloriesConsumed} cal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Calorie progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$percentOfGoal% / 100%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (widget.totalCaloriesToday / widget.dailyCalorieGoal).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caloriesRemaining > 0
                        ? '🔥 ${caloriesRemaining} cal remaining'
                        : '⚠️ Exceeded by ${(caloriesRemaining.abs())} cal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // AI Suggestion
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                ),
                child: FutureBuilder<String>(
                  future: _suggestionFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Getting AI suggestion...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Text(
                        'Error loading suggestion: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      );
                    }
                    
                    return Text(
                      snapshot.data ?? 'No suggestion available',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Quick balancing actions (simple, non-LLM suggestions)
              Builder(builder: (context) {
                final int calories = widget.caloriesConsumed;
                final int walkMinutes = (calories / 4).ceil(); // ~4 kcal/min walking
                final int jogMinutes = (calories / 8).ceil(); // ~8 kcal/min jogging
                final int yogaMinutes = (calories / 3).ceil(); // ~3 kcal/min gentle yoga

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Balance Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: Text('Walk • $walkMinutes min'),
                          avatar: const Icon(Icons.directions_walk, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Try a $walkMinutes minute brisk walk to burn roughly $calories kcal.')),
                            );
                          },
                        ),
                        ActionChip(
                          label: Text('Jog • $jogMinutes min'),
                          avatar: const Icon(Icons.directions_run, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Try $jogMinutes minutes of jogging to balance the intake.')),
                            );
                          },
                        ),
                        ActionChip(
                          label: Text('Yoga • $yogaMinutes min'),
                          avatar: const Icon(Icons.self_improvement, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Try $yogaMinutes minutes of gentle yoga or stretching.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }),
              
              // Health conditions notice
              if (widget.healthProfile.healthConditions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your profile: ${widget.healthProfile.healthConditions.map((c) => c.name).join(', ')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Could navigate to full nutrition details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Suggestion saved for ${widget.foodConsumed}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Got it'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily motivation banner
class DailyMotivationBanner extends StatelessWidget {
  final HealthProfile healthProfile;
  final int caloriesConsumed;
  final int dailyGoal;

  const DailyMotivationBanner({
    super.key,
    required this.healthProfile,
    required this.caloriesConsumed,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: LLMSuggestionService.getDailyMotivation(
        age: healthProfile.age,
        caloriesConsumed: caloriesConsumed,
        dailyGoal: dailyGoal,
        healthConditions: healthProfile.healthConditions,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.purple[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  snapshot.data ?? 'Keep going! You\'re doing great!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Health summary widget
class HealthSummaryWidget extends StatelessWidget {
  final HealthProfile healthProfile;
  final int caloriesConsumed;
  final int stepsToday;
  final int fiberConsumed;

  const HealthSummaryWidget({
    super.key,
    required this.healthProfile,
    required this.caloriesConsumed,
    required this.stepsToday,
    required this.fiberConsumed,
  });

  @override
  Widget build(BuildContext context) {
    final caloriesPercent = ((caloriesConsumed / healthProfile.targetCalories) * 100).toStringAsFixed(0);
    final fiberPercent = ((fiberConsumed / 25) * 100).toStringAsFixed(0);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Today\'s Health Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              icon: '🔥',
              label: 'Calories',
              value: '$caloriesConsumed / ${healthProfile.targetCalories}',
              percent: double.parse(caloriesPercent) / 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              icon: '👟',
              label: 'Steps',
              value: stepsToday.toString(),
              percent: (stepsToday / 10000).clamp(0, 1),
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              icon: '🥬',
              label: 'Fiber',
              value: '$fiberConsumed / 25g',
              percent: (fiberConsumed / 25).clamp(0, 1),
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
