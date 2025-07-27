// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mahallda_app/models/region_model.dart';
import 'package:mahallda_app/models/mahalla_model.dart';
import 'dart:io'; // File uchun
import 'package:path/path.dart'; // basename uchun

class ApiService {
  final String _baseUrl = 'https://hbnnarzullayev.pythonanywhere.com/api';

  Future<List<Region>> fetchRegions() async {
    final response = await http.get(Uri.parse('$_baseUrl/uzb_regions'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      // ns10_code bo'yicha noyob viloyatlarni olish
      final Map<int, Region> uniqueRegions = {};
      for (var item in jsonResponse) {
        final region = Region.fromJson(item);
        if (!uniqueRegions.containsKey(region.ns10Code)) {
          uniqueRegions[region.ns10Code] = region;
        }
      }
      return uniqueRegions.values.toList();
    } else {
      throw Exception('Failed to load regions');
    }
  }

  Future<List<Region>> fetchDistricts(int ns10Code) async {
    final response = await http.get(Uri.parse('$_baseUrl/uzb_regions'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      // ns10_code ga mos tumanlarni olish
      return jsonResponse
          .map((data) => Region.fromJson(data))
          .where((region) => region.ns10Code == ns10Code)
          .toList();
    } else {
      throw Exception('Failed to load districts');
    }
  }

  Future<List<Mahalla>> fetchMahallas(int ns10Code, int ns11Code) async {
    final response = await http.get(Uri.parse('$_baseUrl/mahalla'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse
          .map((data) => Mahalla.fromJson(data))
          .where((mahalla) =>
              mahalla.ns10Code == ns10Code && mahalla.ns11Code == ns11Code)
          .toList();
    } else {
      throw Exception('Failed to load mahallas');
    }
  }

  // Yangi metod: Rasmni tashqi API ga yuklash
  Future<String> uploadTradeImage(File imageFile) async {
    final uri = Uri.parse(
        'https://hbnappdatas.pythonanywhere.com/api/trade_img_mahallada'); // Siz bergan API manzili
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image', // API kutayotgan maydon nomi
        imageFile.path,
        filename: basename(imageFile.path),
      ));
    print('request:');
    print(request);


    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      if (jsonResponse['image_url'] != null) {
        return jsonResponse['image_url'];
      } else {
        throw Exception(
            'Image upload successful, but no image_url found in response.');
      }
    } else {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
          'Failed to upload image: ${response.statusCode} - $errorBody');
    }
  }

  Future<String> uploadProfilePhoto(File imageFile, String userId) async {
    final uri = Uri.parse('https://hbnnarzullayev.pythonanywhere.com/api/upload_img_mahallada');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path))
      ..fields['user_id'] = userId; // Add user_id to form data
    print('Request: $request');

    var response = await request.send();
    print(response.request);
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      print(responseBody); // Match backend response key
      return jsonResponse['image_url']; // Match backend response key
    } else {
      print(response.statusCode);
      throw Exception('Failed to upload image: ${response.statusCode}');
    }
  }
}
