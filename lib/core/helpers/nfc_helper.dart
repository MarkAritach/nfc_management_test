import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager/ndef_record.dart' as ndef;

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

          // Get UID and tag info based on platform
          if (Platform.isAndroid) {
            final nfcTagAndroid = NfcTagAndroid.from(tag);
            if (nfcTagAndroid != null) {
              final uid = nfcTagAndroid.id.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
              tagInfo['uid'] = uid;
              tagInfo['techList'] = nfcTagAndroid.techList;
              debugPrint('🆔 UID: $uid');
              debugPrint('📋 Tech List: ${nfcTagAndroid.techList}');

              // Get NFC-A specific info if available
              final nfcA = NfcAAndroid.from(tag);
              if (nfcA != null) {
                tagInfo['type'] = 'NFC-A';
                tagInfo['atqa'] = nfcA.atqa.toString();
                tagInfo['sak'] = nfcA.sak.toString();
                debugPrint('   ATQA: ${nfcA.atqa}');
                debugPrint('   SAK: ${nfcA.sak}');
              }

              // Get NFC-B specific info if available
              final nfcB = NfcBAndroid.from(tag);
              if (nfcB != null) {
                tagInfo['type'] = 'NFC-B';
              }

              // Get NFC-F specific info if available
              final nfcF = NfcFAndroid.from(tag);
              if (nfcF != null) {
                tagInfo['type'] = 'NFC-F';
              }

              // Get NFC-V specific info if available
              final nfcV = NfcVAndroid.from(tag);
              if (nfcV != null) {
                tagInfo['type'] = 'NFC-V';
              }
            }
          } else if (Platform.isIOS) {
            // iOS handling - get identifier from available tag types
            final ndefIos = NdefIos.from(tag);
            if (ndefIos != null) {
              tagInfo['type'] = 'NDEF';
              debugPrint('✅ iOS NDEF Tag found');
            }
          }

          try {
            // Try to get NDEF data
            ndef.NdefMessage? message;

            if (Platform.isAndroid) {
              final ndefTag = NdefAndroid.from(tag);
              if (ndefTag == null) {
                debugPrint('❌ Tag ไม่รองรับ NDEF');
                onError('Tag นี้ไม่รองรับ NDEF');
                await NfcManager.instance.stopSession();
                return;
              }

              // เพิ่มข้อมูล NDEF
              tagInfo['maxSize'] = ndefTag.maxSize;
              tagInfo['writable'] = ndefTag.isWritable;

              debugPrint('✅ NDEF Tag found');
              debugPrint('📏 Max Size: ${ndefTag.maxSize} bytes');
              debugPrint('✏️  Writable: ${ndefTag.isWritable}');

              // อ่านข้อมูลจาก NDEF Tag
              try {
                message = await ndefTag.getNdefMessage();
                debugPrint('📨 NDEF Message: $message');
              } catch (readError) {
                debugPrint('⚠️ ไม่สามารถอ่าน NDEF Message: $readError');
                debugPrint('⚠️ Tag อาจว่างเปล่าหรือไม่มีข้อมูล');
                onSuccess([], tagInfo); // ส่ง empty list พร้อม tagInfo
                await NfcManager.instance.stopSession();
                return;
              }
            } else if (Platform.isIOS) {
              final ndefTag = NdefIos.from(tag);
              if (ndefTag == null) {
                debugPrint('❌ Tag ไม่รองรับ NDEF');
                onError('Tag นี้ไม่รองรับ NDEF');
                await NfcManager.instance.stopSession();
                return;
              }

              tagInfo['capacity'] = ndefTag.capacity;
              tagInfo['writable'] = ndefTag.status == NdefStatusIos.readWrite;

              debugPrint('✅ NDEF Tag found (iOS)');
              debugPrint('📏 Capacity: ${ndefTag.capacity} bytes');
              debugPrint('✏️  Status: ${ndefTag.status}');

              try {
                message = await ndefTag.readNdef();
                debugPrint('📨 NDEF Message: $message');
              } catch (readError) {
                debugPrint('⚠️ ไม่สามารถอ่าน NDEF Message: $readError');
                onSuccess([], tagInfo);
                await NfcManager.instance.stopSession();
                return;
              }
            }

            if (message == null || message.records.isEmpty) {
              debugPrint('⚠️ Tag ไม่มี Records');
              onSuccess([], tagInfo); // ส่ง empty list พร้อม tagInfo
              await NfcManager.instance.stopSession();
              return;
            }

            debugPrint('📊 NDEF Message Records: ${message.records.length}');

            // กรอง Empty Records ออก (TNF = 0x00 และ payload ว่าง)
            final records = message.records
                .where((record) {
                  // ถ้าเป็น Empty Record (TNF = 0) และ payload ว่าง -> ข้าม
                  if (record.typeNameFormat == ndef.TypeNameFormat.empty &&
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
            if (Platform.isAndroid) {
              final ndefTag = NdefAndroid.from(tag);
              if (ndefTag == null) {
                debugPrint('❌ Tag ไม่รองรับ NDEF');
                onError('Tag นี้ไม่รองรับ NDEF');
                await NfcManager.instance.stopSession();
                return;
              }

              if (!ndefTag.isWritable) {
                debugPrint('❌ Tag ไม่สามารถเขียนได้');
                onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
                await NfcManager.instance.stopSession();
                return;
              }

              debugPrint('✅ Tag สามารถเขียนได้');
              debugPrint('📝 กำลังเขียนข้อความ: $text');

              // สร้าง NDEF Message using ndef_record package
              final textRecord = ndef.NdefRecord(
                typeNameFormat: ndef.TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x54]), // 'T' for text
                identifier: Uint8List(0),
                payload: Uint8List.fromList([0x02, 0x65, 0x6E, ...text.codeUnits]), // Language code 'en' + text
              );

              final ndefMessage = ndef.NdefMessage(records: [textRecord]);

              // เขียนลง Tag
              await ndefTag.writeNdefMessage(ndefMessage);

              debugPrint('✅ เขียนสำเร็จ!');
              onSuccess();
              await NfcManager.instance.stopSession();
            } else if (Platform.isIOS) {
              final ndefTag = NdefIos.from(tag);
              if (ndefTag == null) {
                onError('Tag นี้ไม่รองรับ NDEF');
                await NfcManager.instance.stopSession();
                return;
              }

              if (ndefTag.status != NdefStatusIos.readWrite) {
                onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
                await NfcManager.instance.stopSession();
                return;
              }

              debugPrint('📝 กำลังเขียนข้อความ: $text');

              final textRecord = ndef.NdefRecord(
                typeNameFormat: ndef.TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x54]),
                identifier: Uint8List(0),
                payload: Uint8List.fromList([0x02, 0x65, 0x6E, ...text.codeUnits]),
              );

              final ndefMessage = ndef.NdefMessage(records: [textRecord]);
              await ndefTag.writeNdef(ndefMessage);

              debugPrint('✅ เขียนสำเร็จ!');
              onSuccess();
              await NfcManager.instance.stopSession();
            }
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
            if (Platform.isAndroid) {
              final ndefTag = NdefAndroid.from(tag);
              if (ndefTag == null) {
                onError('Tag นี้ไม่รองรับ NDEF');
                await NfcManager.instance.stopSession();
                return;
              }

              if (!ndefTag.isWritable) {
                onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
                await NfcManager.instance.stopSession();
                return;
              }

              debugPrint('📝 กำลังเขียน URL: $url');

              // Create URI record
              final uriRecord = ndef.NdefRecord(
                typeNameFormat: ndef.TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x55]), // 'U' for URI
                identifier: Uint8List(0),
                payload: Uint8List.fromList([0x00, ...url.codeUnits]), // 0x00 = no prefix
              );

              final ndefMessage = ndef.NdefMessage(records: [uriRecord]);

              // เขียนลง Tag
              await ndefTag.writeNdefMessage(ndefMessage);

              debugPrint('✅ เขียน URL สำเร็จ!');
              onSuccess();
              await NfcManager.instance.stopSession();
            } else if (Platform.isIOS) {
              final ndefTag = NdefIos.from(tag);
              if (ndefTag == null) {
                onError('Tag นี้ไม่รองรับ NDEF');
                await NfcManager.instance.stopSession();
                return;
              }

              if (ndefTag.status != NdefStatusIos.readWrite) {
                onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
                await NfcManager.instance.stopSession();
                return;
              }

              debugPrint('📝 กำลังเขียน URL: $url');

              final uriRecord = ndef.NdefRecord(
                typeNameFormat: ndef.TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x55]),
                identifier: Uint8List(0),
                payload: Uint8List.fromList([0x00, ...url.codeUnits]),
              );

              final ndefMessage = ndef.NdefMessage(records: [uriRecord]);
              await ndefTag.writeNdef(ndefMessage);

              debugPrint('✅ เขียน URL สำเร็จ!');
              onSuccess();
              await NfcManager.instance.stopSession();
            }
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
            if (Platform.isAndroid) {
              final ndefTag = NdefAndroid.from(tag);
              if (ndefTag == null) {
                onError('Tag นี้ไม่รองรับ NDEF');
                await NfcManager.instance.stopSession();
                return;
              }

              debugPrint('📊 Tag Info:');
              debugPrint('   - Max Size: ${ndefTag.maxSize} bytes');
              debugPrint('   - Writable: ${ndefTag.isWritable}');

              if (!ndefTag.isWritable) {
                onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
                await NfcManager.instance.stopSession();
                return;
              }

              debugPrint('🗑️ กำลังลบข้อมูลใน Tag...');

              // วิธีที่ 1: ลอง Format NDEF ใหม่ด้วย Empty Message (ทำให้ Tag กลับมาเป็นว่างเปล่า)
              try {
                // สร้าง Empty NDEF Message (ไม่มี record เลย)
                final emptyMessage = ndef.NdefMessage(records: []);

                debugPrint('📏 Attempting to write completely empty message...');
                await ndefTag.writeNdefMessage(emptyMessage);
                debugPrint('✅ ลบข้อมูลสำเร็จ! Tag ว่างเปล่าแล้ว');
                onSuccess();
              } catch (writeError) {
                debugPrint('⚠️ Cannot write empty message: $writeError');
                debugPrint('🔄 Trying fallback method: Write empty record...');

                // วิธีที่ 2 (fallback): ใช้ Empty Record
                try {
                  final emptyRecord = ndef.NdefRecord(
                    typeNameFormat: ndef.TypeNameFormat.empty,
                    type: Uint8List(0),
                    identifier: Uint8List(0),
                    payload: Uint8List(0),
                  );

                  final emptyRecordMessage = ndef.NdefMessage(records: [emptyRecord]);

                  await ndefTag.writeNdefMessage(emptyRecordMessage);
                  debugPrint('✅ ลบข้อมูลสำเร็จ! (ใช้ empty record)');
                  onSuccess();
                } catch (fallbackError) {
                  debugPrint('❌ Fallback also failed: $fallbackError');
                  onError('เขียนไม่สำเร็จ: Tag อาจถูกล็อคหรือไม่รองรับการเขียน');
                }
              }
            } else if (Platform.isIOS) {
              final ndefTag = NdefIos.from(tag);
              if (ndefTag == null) {
                onError('Tag นี้ไม่รองรับ NDEF');
                await NfcManager.instance.stopSession();
                return;
              }

              if (ndefTag.status != NdefStatusIos.readWrite) {
                onError('Tag นี้ไม่สามารถเขียนได้ (Read-only)');
                await NfcManager.instance.stopSession();
                return;
              }

              debugPrint('🗑️ กำลังลบข้อมูลใน Tag...');

              try {
                final emptyMessage = ndef.NdefMessage(records: []);
                await ndefTag.writeNdef(emptyMessage);
                debugPrint('✅ ลบข้อมูลสำเร็จ! Tag ว่างเปล่าแล้ว');
                onSuccess();
              } catch (writeError) {
                debugPrint('⚠️ Cannot write empty message: $writeError');

                try {
                  final emptyRecord = ndef.NdefRecord(
                    typeNameFormat: ndef.TypeNameFormat.empty,
                    type: Uint8List(0),
                    identifier: Uint8List(0),
                    payload: Uint8List(0),
                  );

                  final emptyRecordMessage = ndef.NdefMessage(records: [emptyRecord]);
                  await ndefTag.writeNdef(emptyRecordMessage);
                  debugPrint('✅ ลบข้อมูลสำเร็จ! (ใช้ empty record)');
                  onSuccess();
                } catch (fallbackError) {
                  debugPrint('❌ Fallback also failed: $fallbackError');
                  onError('เขียนไม่สำเร็จ: Tag อาจถูกล็อคหรือไม่รองรับการเขียน');
                }
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
