import 'package:flutter/material.dart';
import '../../../core/helpers/nfc_helper.dart';

enum NfcWriteStatus { idle, writing, success, error }

class NfcWriteController extends ChangeNotifier {
  NfcWriteStatus status = NfcWriteStatus.idle;
  String statusMessage = 'กรอกข้อมูลและกด Write';

  Future<void> writeText(String text) async {
    if (text.isEmpty) {
      status = NfcWriteStatus.error;
      statusMessage = '❌ กรุณากรอกข้อความ';
      notifyListeners();
      return;
    }

    final isAvailable = await NfcHelper.isAvailable();
    if (!isAvailable) {
      status = NfcWriteStatus.error;
      statusMessage = '❌ เครื่องนี้ไม่มี NFC หรือ NFC ปิดอยู่';
      notifyListeners();
      return;
    }

    status = NfcWriteStatus.writing;
    statusMessage = '📡 กำลังรอ NFC Tag...';
    notifyListeners();

    await NfcHelper.writeText(
      text: text,
      onSuccess: () {
        status = NfcWriteStatus.success;
        statusMessage = '✅ เขียนสำเร็จ!';
        notifyListeners();
      },
      onError: (error) {
        status = NfcWriteStatus.error;
        statusMessage = '❌ $error';
        notifyListeners();
      },
    );
  }

  Future<void> writeUrl(String url) async {
    if (url.isEmpty) {
      status = NfcWriteStatus.error;
      statusMessage = '❌ กรุณากรอก URL';
      notifyListeners();
      return;
    }

    final isAvailable = await NfcHelper.isAvailable();
    if (!isAvailable) {
      status = NfcWriteStatus.error;
      statusMessage = '❌ เครื่องนี้ไม่มี NFC หรือ NFC ปิดอยู่';
      notifyListeners();
      return;
    }

    status = NfcWriteStatus.writing;
    statusMessage = '📡 กำลังรอ NFC Tag...';
    notifyListeners();

    await NfcHelper.writeUrl(
      url: url,
      onSuccess: () {
        status = NfcWriteStatus.success;
        statusMessage = '✅ เขียน URL สำเร็จ!';
        notifyListeners();
      },
      onError: (error) {
        status = NfcWriteStatus.error;
        statusMessage = '❌ $error';
        notifyListeners();
      },
    );
  }

  Future<void> clearTag() async {
    final isAvailable = await NfcHelper.isAvailable();
    if (!isAvailable) {
      status = NfcWriteStatus.error;
      statusMessage = '❌ เครื่องนี้ไม่มี NFC หรือ NFC ปิดอยู่';
      notifyListeners();
      return;
    }

    status = NfcWriteStatus.writing;
    statusMessage = '📡 กำลังรอ NFC Tag เพื่อลบข้อมูล...';
    notifyListeners();

    await NfcHelper.clearTag(
      onSuccess: () {
        status = NfcWriteStatus.success;
        statusMessage = '✅ ลบข้อมูลสำเร็จ! Tag ว่างเปล่าแล้ว';
        notifyListeners();
      },
      onError: (error) {
        status = NfcWriteStatus.error;
        statusMessage = '❌ $error';
        notifyListeners();
      },
    );
  }

  Future<void> stopWrite() async {
    await NfcHelper.stopSession();
    status = NfcWriteStatus.idle;
    statusMessage = 'หยุดการเขียนแล้ว';
    notifyListeners();
  }

  void reset() {
    status = NfcWriteStatus.idle;
    statusMessage = 'กรอกข้อมูลและกด Write';
    notifyListeners();
  }
}
