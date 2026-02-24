import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcHelper {
  /// เช็คว่าเครื่องมี NFC ไหม
  static Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// เริ่ม session อ่าน NFC (ใช้ Foreground Dispatch เพื่อป้องกันการเด้งไปแอปอื่น)
  static Future<void> startReadSession({
    required void Function(List<String> records, Map<String, dynamic> tagInfo) onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          debugPrint('=== NFC Tag Discovered ===');

          // สร้าง Map สำหรับเก็บข้อมูล Tag
          final Map<String, dynamic> tagInfo = {};

          // แสดง UID / Serial Number
          final nfca = tag.data['nfca'];
          final nfcb = tag.data['nfcb'];
          final nfcf = tag.data['nfcf'];
          final nfcv = tag.data['nfcv'];

          if (nfca != null) {
            final identifier = nfca['identifier'] as List<dynamic>?;
            if (identifier != null) {
              final uid = identifier.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
              tagInfo['uid'] = uid;
              tagInfo['type'] = 'NFC-A';
              tagInfo['atqa'] = nfca['atqa'].toString();
              tagInfo['sak'] = nfca['sak'].toString();
              debugPrint('🆔 NFC-A UID: $uid');
              debugPrint('   ATQA: ${nfca['atqa']}');
              debugPrint('   SAK: ${nfca['sak']}');
            }
          }

          if (nfcb != null) {
            final identifier = nfcb['identifier'] as List<dynamic>?;
            if (identifier != null) {
              final uid = identifier.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
              tagInfo['uid'] = uid;
              tagInfo['type'] = 'NFC-B';
              debugPrint('🆔 NFC-B UID: $uid');
            }
          }

          if (nfcf != null) {
            final identifier = nfcf['identifier'] as List<dynamic>?;
            if (identifier != null) {
              final uid = identifier.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
              tagInfo['uid'] = uid;
              tagInfo['type'] = 'NFC-F';
              debugPrint('🆔 NFC-F UID: $uid');
            }
          }

          if (nfcv != null) {
            final identifier = nfcv['identifier'] as List<dynamic>?;
            if (identifier != null) {
              final uid = identifier.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
              tagInfo['uid'] = uid;
              tagInfo['type'] = 'NFC-V';
              debugPrint('🆔 NFC-V UID: $uid');
            }
          }

          debugPrint('📦 Full Tag Data: ${tag.data}');

          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              debugPrint('❌ Tag ไม่รองรับ NDEF');
              onError('Tag นี้ไม่รองรับ NDEF');
              await NfcManager.instance.stopSession();
              return;
            }

            // เพิ่มข้อมูล NDEF
            tagInfo['maxSize'] = ndef.maxSize;
            tagInfo['writable'] = ndef.isWritable;

            debugPrint('✅ NDEF Tag found');
            debugPrint('📏 Max Size: ${ndef.maxSize} bytes');
            debugPrint('✏️  Writable: ${ndef.isWritable}');

            // อ่านข้อมูลจาก NDEF Tag
            NdefMessage? message;
            try {
              message = await ndef.read();
              debugPrint('📨 NDEF Message: $message');
            } catch (readError) {
              debugPrint('⚠️ ไม่สามารถอ่าน NDEF Message: $readError');
              debugPrint('⚠️ Tag อาจว่างเปล่าหรือไม่มีข้อมูล');
              onSuccess([], tagInfo); // ส่ง empty list พร้อม tagInfo
              await NfcManager.instance.stopSession();
              return;
            }

            debugPrint('📊 NDEF Message Records: ${message.records.length}');

            if (message.records.isEmpty) {
              debugPrint('⚠️ Tag ไม่มี Records');
              onSuccess([], tagInfo); // ส่ง empty list พร้อม tagInfo
              await NfcManager.instance.stopSession();
              return;
            }

            // กรอง Empty Records ออก (TNF = 0x00 และ payload ว่าง)
            final records = message.records
                .where((record) {
                  // ถ้าเป็น Empty Record (TNF = 0) และ payload ว่าง -> ข้าม
                  if (record.typeNameFormat == NdefTypeNameFormat.empty &&
                      record.payload.isEmpty) {
                    debugPrint('⚠️ พบ Empty Record - ข้าม');
                    return false;
                  }
                  return true;
                })
                .map((record) {
                  final payload = String.fromCharCodes(record.payload);
                  debugPrint('📝 Record:');
                  debugPrint('   - Type: ${String.fromCharCodes(record.type)}');
                  debugPrint('   - Payload: $payload');
                  debugPrint('   - Identifier: ${record.identifier}');
                  return payload;
                })
                .toList();

            debugPrint('📊 Valid Records (after filtering empty): ${records.length}');

            debugPrint('=== ✅ Success: ${records.length} records ===');
            onSuccess(records, tagInfo);
            await NfcManager.instance.stopSession();
          } catch (e) {
            debugPrint('❌ Error: $e');
            onError(e.toString());
            await NfcManager.instance.stopSession();
          }
        },
        // เปิดใช้ Foreground Dispatch Mode - ดัก NFC ตอนแอปเปิดอยู่เท่านั้น
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
      );
    } catch (e) {
      debugPrint('❌ ไม่สามารถเริ่ม NFC session: $e');
      onError('ไม่สามารถเริ่ม NFC session: ${e.toString()}');
    }
  }

  /// หยุด session
  static Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }

  /// เขียนข้อมูล Text ลง NFC Tag
  static Future<void> writeText({
    required String text,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          debugPrint('=== NFC Tag Discovered for Writing ===');

          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              debugPrint('❌ Tag ไม่รองรับ NDEF');
              onError('Tag นี้ไม่รองรับ NDEF');
              await NfcManager.instance.stopSession();
              return;
            }

            if (!ndef.isWritable) {
              debugPrint('❌ Tag ไม่สามารถเขียนได้');
              onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
              await NfcManager.instance.stopSession();
              return;
            }

            debugPrint('✅ Tag สามารถเขียนได้');
            debugPrint('📝 กำลังเขียนข้อความ: $text');

            // สร้าง NDEF Message
            final ndefMessage = NdefMessage([
              NdefRecord.createText(text),
            ]);

            // เขียนลง Tag
            await ndef.write(ndefMessage);

            debugPrint('✅ เขียนสำเร็จ!');
            onSuccess();
            await NfcManager.instance.stopSession();
          } catch (e) {
            debugPrint('❌ Error writing: $e');
            onError('เขียนไม่สำเร็จ: ${e.toString()}');
            await NfcManager.instance.stopSession();
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
      );
    } catch (e) {
      debugPrint('❌ ไม่สามารถเริ่ม NFC write session: $e');
      onError('ไม่สามารถเริ่ม NFC session: ${e.toString()}');
    }
  }

  /// เขียน URL ลง NFC Tag
  static Future<void> writeUrl({
    required String url,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          debugPrint('=== NFC Tag Discovered for Writing URL ===');

          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              onError('Tag นี้ไม่รองรับ NDEF');
              await NfcManager.instance.stopSession();
              return;
            }

            if (!ndef.isWritable) {
              onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
              await NfcManager.instance.stopSession();
              return;
            }

            debugPrint('📝 กำลังเขียน URL: $url');

            // สร้าง NDEF Message
            final ndefMessage = NdefMessage([
              NdefRecord.createUri(Uri.parse(url)),
            ]);

            // เขียนลง Tag
            await ndef.write(ndefMessage);

            debugPrint('✅ เขียน URL สำเร็จ!');
            onSuccess();
            await NfcManager.instance.stopSession();
          } catch (e) {
            debugPrint('❌ Error writing URL: $e');
            onError('เขียนไม่สำเร็จ: ${e.toString()}');
            await NfcManager.instance.stopSession();
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
      );
    } catch (e) {
      onError('ไม่สามารถเริ่ม NFC session: ${e.toString()}');
    }
  }

  /// ลบข้อมูลใน NFC Tag (Clear/Erase)
  static Future<void> clearTag({
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          debugPrint('=== NFC Tag Discovered for Clearing ===');

          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              onError('Tag นี้ไม่รองรับ NDEF');
              await NfcManager.instance.stopSession();
              return;
            }

            debugPrint('📊 Tag Info:');
            debugPrint('   - Max Size: ${ndef.maxSize} bytes');
            debugPrint('   - Writable: ${ndef.isWritable}');

            if (!ndef.isWritable) {
              onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
              await NfcManager.instance.stopSession();
              return;
            }

            debugPrint('🗑️ กำลังลบข้อมูลใน Tag...');

            // วิธีที่ 1: ลอง Format NDEF ใหม่ด้วย Empty Message (ทำให้ Tag กลับมาเป็นว่างเปล่า)
            try {
              // สร้าง Empty NDEF Message (ไม่มี record เลย)
              final emptyMessage = NdefMessage([]);

              debugPrint('📏 Attempting to write completely empty message...');
              await ndef.write(emptyMessage);
              debugPrint('✅ ลบข้อมูลสำเร็จ! Tag ว่างเปล่าแล้ว');
              onSuccess();
            } catch (writeError) {
              debugPrint('⚠️ Cannot write empty message: $writeError');
              debugPrint('🔄 Trying fallback method: Write empty record...');

              // วิธีที่ 2 (fallback): ใช้ Empty Record
              try {
                final emptyRecordMessage = NdefMessage([
                  NdefRecord(
                    typeNameFormat: NdefTypeNameFormat.empty,
                    type: Uint8List(0),
                    identifier: Uint8List(0),
                    payload: Uint8List(0),
                  ),
                ]);

                await ndef.write(emptyRecordMessage);
                debugPrint('✅ ลบข้อมูลสำเร็จ! (ใช้ empty record)');
                onSuccess();
              } catch (fallbackError) {
                debugPrint('❌ Fallback also failed: $fallbackError');
                onError('เขียนไม่สำเร็จ: Tag อาจถูกล็อคหรือไม่รองรับการเขียน');
              }
            }

            await NfcManager.instance.stopSession();
          } catch (e) {
            debugPrint('❌ Error clearing tag: $e');
            onError('ลบข้อมูลไม่สำเร็จ: ${e.toString()}');
            await NfcManager.instance.stopSession();
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
      );
    } catch (e) {
      onError('ไม่สามารถเริ่ม NFC session: ${e.toString()}');
    }
  }
}