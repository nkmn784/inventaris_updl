import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Sesuai dengan nama di pojok kiri atas
  final String cloudName = 'yhovuzji';

  // Sesuai dengan nama preset yang berstatus Unsigned
  final String uploadPreset = 'updl_pln';

  // ... sisa kode di bawahnya tetap sama

  Future<String?> uploadImageBytes(Uint8List imageBytes) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/upload',
      );
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'upload.jpg',
          ),
        );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        // Ini akan mencetak alasan pasti kenapa Cloudinary menolak upload
        print('Cloudinary Error: $responseString');
        return null;
      }
    } catch (e) {
      print('HTTP Request Error: $e');
      return null;
    }
  }
}
