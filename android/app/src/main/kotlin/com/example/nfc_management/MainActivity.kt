package com.example.nfc_management

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // MainActivity จะใช้ launchMode="singleTop" ใน AndroidManifest
    // ทำให้ NFC Manager plugin สามารถรับ NFC Intent ได้โดยอัตโนมัติ
    // ผ่าน Foreground Dispatch Mode ที่ตั้งค่าไว้แล้ว
}
