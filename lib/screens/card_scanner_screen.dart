// lib/screens/card_scanner_screen.dart
import 'package:flutter/material.dart';

class CardScannerScreen extends StatelessWidget {
  const CardScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Card'),
      ),
      body: const Center(
        child: Text('Scanner functionality coming soon'),
      ),
    );
  }
}
