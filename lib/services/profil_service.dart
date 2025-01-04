import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supriz/consts/consts.dart';
import 'dart:io';

class ProfilService {
  Future<String?> _getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> updateProfileImage(File image) async {
    String? token = await _getAuthToken();
    final request = http.MultipartRequest(
        'POST', Uri.parse('$domaineapi/update-profile-image'));
    request.files
        .add(await http.MultipartFile.fromPath('profil_image', image.path));
    request.headers['Authorization'] = 'Bearer $token';

    print('Sending request to update profile image...');
    print('Headers: ${request.headers}');
    print('Files: ${request.files}');

    final response = await request.send();

    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', '/storage/images/$image');
      print('Success: ${data}');
      return data;
    } else {
      print(
          'Failed to update profile image. Status code: ${response.statusCode}');
      throw Exception('Failed to update profile image');
    }
  }

  /*
  Future<Map<String, dynamic>> updateName(String name, String prenom) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('firstname', prenom);
    return _updateProfile(
      endpoint: 'update-name',
      body: {'name': name, 'prenom': prenom},
    );
  }
  */

  Future<Map<String, dynamic>> updateName(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    return _updateProfile(
      endpoint: 'update-name',
      body: {'name': name},
    );
  }

  Future<Map<String, dynamic>> updateEmail(String email) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    return _updateProfile(
      endpoint: 'update-email',
      body: {'email': email},
    );
  }

  Future<Map<String, dynamic>> updateNumber(String numero) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('numero', numero);
    return _updateProfile(
      endpoint: 'update-number',
      body: {'numero': numero},
    );
  }

  Future<Map<String, dynamic>> updatePassword(
      String oldPassword, String newPassword) async {
    return _updateProfile(
      endpoint: 'update-password',
      body: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  Future<Map<String, dynamic>> _updateProfile({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    String? token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$domaineapi/$endpoint'),
      body: jsonEncode(body),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    print('Sending request to update profile...');
    print('Endpoint: $endpoint');
    print('Headers: ${response.request?.headers}');
    print('Body: ${jsonEncode(body)}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Success: ${data}');
      return data;
    } else if (response.statusCode == 302) {
      print('Redirect: ${response.headers['location']}');
      throw Exception('Redirect detected');
    } else {
      print('Failed to update profile. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to update profile');
    }
  }
}
