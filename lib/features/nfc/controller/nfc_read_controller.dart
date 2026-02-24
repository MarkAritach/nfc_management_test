import 'package:flutter/material.dart';
import '../../../core/helpers/nfc_helper.dart';

enum NfcScanStatus { idle, scanning, success, error }

class NfcReadController extends ChangeNotifier {
  NfcScanStatus status = NfcScanStatus.idle;
  String statusMessage = 'กด Start เพื่อเริ่มอ่าน NFC';
  List<String> records = [];
  Map<String, dynamic> tagInfo = {};

  Future<void> startScan() async {
    final isAvailable = await NfcHelper.isAvailable();
    if (!isAvailable) {
      status = NfcScanStatus.error;
      statusMessage = '❌ เครื่องนี้ไม่มี NFC หรือ NFC ปิดอยู่';
      notifyListeners();
      return;
    }

    status = NfcScanStatus.scanning;
    statusMessage = '📡 กำลังรอ NFC Tag...';
    records = [];
    tagInfo = {};
    notifyListeners();

    await NfcHelper.startReadSession(
      onSuccess: (data, info) {
        status = NfcScanStatus.success;
        statusMessage = '✅ อ่านสำเร็จ! พบ ${data.length} record';
        records = data;
        tagInfo = info;
        notifyListeners();
      },
      onError: (error) {
        status = NfcScanStatus.error;
        statusMessage = '❌ $error';
        notifyListeners();
      },
    );
  }

  Future<void> stopScan() async {
    await NfcHelper.stopSession();
    status = NfcScanStatus.idle;
    statusMessage = 'หยุดการสแกนแล้ว';
    notifyListeners();
  }
}