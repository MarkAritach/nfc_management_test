import 'package:flutter/material.dart';
import '../controller/nfc_read_controller.dart';

class NfcStatusCard extends StatelessWidget {
  final NfcScanStatus status;
  final String message;

  const NfcStatusCard({
    super.key,
    required this.status,
    required this.message,
  });

  Color get _color => switch (status) {
    NfcScanStatus.scanning => Colors.blue.shade50,
    NfcScanStatus.success  => Colors.green.shade50,
    NfcScanStatus.error    => Colors.red.shade50,
    NfcScanStatus.idle     => Colors.grey.shade100,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}