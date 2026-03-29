import 'package:flutter/material.dart';

class AroviaBackground extends StatelessWidget {
  final Widget child;

  const AroviaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// Main gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE8F8EF),
                Color(0xFFDDF3E7),
                Color(0xFFCFEBDD),
              ],
            ),
          ),
        ),

        /// Top soft glow
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha:0.12),
            ),
          ),
        ),

        /// Bottom organic shape
        Positioned(
          bottom: -150,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.08),
            ),
          ),
        ),
        
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.07),
            ),
          ),
        ),
        /// App content
        SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}