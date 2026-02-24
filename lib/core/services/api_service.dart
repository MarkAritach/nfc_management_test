import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // เปลี่ยน URL นี้เป็น API ของคุณ
  static const String baseUrl = 'https://your-api-url.com/api';

  /// ดึงข้อมูล Tag จาก Database โดยใช้ UID
  static Future<Map<String, dynamic>?> getTagData(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tags/$uid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        // Tag ไม่มีในระบบ
        return null;
      } else {
        throw Exception('Failed to load tag data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tag data: $e');
    }
  }

  /// บันทึกข้อมูล Tag ลง Database
  static Future<bool> saveTagData({
    required String uid,
    required String type, // NFC-A, NFC-B, etc.
    required String content, // ข้อความหรือ URL ที่เขียน
    String? atqa,
    String? sak,
    int? maxSize,
    bool? writable,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tags'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': uid,
          'type': type,
          'content': content,
          'atqa': atqa,
          'sak': sak,
          'maxSize': maxSize,
          'writable': writable,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error saving tag data: $e');
    }
  }

  /// อัปเดตข้อมูล Tag
  static Future<bool> updateTagData({
    required String uid,
    required String content,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tags/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'content': content,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating tag data: $e');
    }
  }

  /// ลบข้อมูล Tag
  static Future<bool> deleteTagData(String uid) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tags/$uid'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting tag data: $e');
    }
  }

  /// ดึงรายการ Tags ทั้งหมด
  static Future<List<Map<String, dynamic>>> getAllTags() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tags'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tags: $e');
    }
  }
}
