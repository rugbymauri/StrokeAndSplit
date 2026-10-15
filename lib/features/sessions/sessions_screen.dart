import 'package:flutter/material.dart';

/// Recorded sessions. The list itself follows with the session recording.
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: const Center(child: Text('Noch keine Sessions aufgezeichnet.')),
    );
  }
}
