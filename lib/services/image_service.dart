import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ImageService {
  static String get _clientId => dotenv.env['IMGUR_CLIENT_ID'] ?? '';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      if (_clientId.isEmpty) {
        throw Exception('Imgur client ID not found');
      }

      // Add size validation
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception('Image size exceeds 10MB limit');
      }

      final uri = Uri.parse('https://api.imgur.com/3/image');
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Client-ID $_clientId',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'image': base64Image, 'type': 'base64'}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['data']['link'];
      } else {
        print('Upload failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}
