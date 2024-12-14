import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final bool isGuest;

  const HomeScreen({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FFTCG Companion'),
      ),
      body: const Center(
        child: Text('Home Screen - To be implemented'),
      ),
    );
  }
}
