import 'package:flutter/material.dart';

class PreWorkoutScreen extends StatelessWidget {
  const PreWorkoutScreen({super.key});

  static const routeName = '/pre-workout';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre Workout')),
      body: const Center(
        child: Text('TODO: Implement Pre Workout UI per design.'),
      ),
    );
  }
}
