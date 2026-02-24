import 'package:flutter/material.dart';
import 'features/nfc/view/nfc_read_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC App',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const NfcReadPage(),
    );
  }
}