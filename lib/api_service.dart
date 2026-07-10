import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/folder.dart';
import 'models/file_item.dart';

class ApiService {
  // Base URL is dynamic. Web uses 127.0.0.1, Android uses 10.0.2.2 (Emulator loopback)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  /// Saves the user ID locally after a successful login
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  /// Retrieves the saved user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// Saves the channel ID locally
  static Future<void> saveChannelId(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('channel_id', channelId);
  }

  /// Retrieves the saved channel ID
  static Future<String?> getChannelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('channel_id');
  }

  /// Clears user data (Logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('channel_id');
  }

  // ==========================================
  // Auth Operations
  // ==========================================

  /// Step 1: Send OTP to the user's phone
  static Future<bool> sendCode(String phone) async {
    final uri = Uri.parse('$baseUrl/auth/send-code').replace(queryParameters: {
      'user_id': phone,
      'phone': phone,
    });
    
    try {
      final response = await http.post(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Step 2: Verify OTP
  static Future<Map<String, dynamic>?> verifyCode(String phone, String code) async {
    final uri = Uri.parse('$baseUrl/auth/verify-code').replace(queryParameters: {
      'user_id': phone,
      'phone': phone,
      'code': code,
    });
    
    try {
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Returns map with 'user_id' and 'channel_id'
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Step 3: Set Channel
  static Future<bool> setChannel(String userId, String channelId) async {
    final uri = Uri.parse('$baseUrl/auth/set-channel').replace(queryParameters: {
      'user_id': userId,
      'channel_id': channelId,
    });
    
    try {
      final response = await http.post(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // STORAGE API
  // ==========================================

  /// Get Folders (root if parentId is null, subfolders if parentId is provided)
  static Future<List<Folder>> getFolders(String userId, {String? parentId}) async {
    final uri = parentId == null 
        ? Uri.parse('$baseUrl/folders/$userId')
        : Uri.parse('$baseUrl/folders/$userId/$parentId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Folder.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  /// Create a Folder
  static Future<bool> createFolder(String userId, String name, {String? parentId}) async {
    final uri = Uri.parse('$baseUrl/folders').replace(queryParameters: {
      'user_id': userId,
      'name': name,
      if (parentId != null) 'parent_id': parentId,
    });
    
    try {
      final response = await http.post(uri);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Upload a File via MultipartRequest (Supports Web and Desktop)
  static Future<bool> uploadFile(String userId, String fileName, {String? filePath, Uint8List? bytes, String? folderId}) async {
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    
    request.fields['user_id'] = userId;
    if (folderId != null) {
      request.fields['folder_id'] = folderId;
    }
    
    try {
      if (bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      } else {
        return false;
      }
      
      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('============= UPLOAD ERROR IN DART =============');
      print(e);
      print('================================================');
      return false;
    }
  }

  /// Get Root Files (where folder_id is null) - Assuming the backend supports it.
  /// Wait, does the backend support getting root files? 
  /// Let's look at `GET /files/{user_id}/{folder_id}`.
  /// If folder_id is 'root', we should handle it in backend, but for now we can fetch it if backend allows.
  /// Wait, let's just create a general getFiles.
  static Future<List<FileItem>> getFiles(String userId, String folderId) async {
    final uri = Uri.parse('$baseUrl/files/$userId/$folderId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => FileItem.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  // ==========================================
  // INTERACTIONS API
  // ==========================================

  static Future<bool> deleteFolder(String userId, String folderId) async {
    final uri = Uri.parse('$baseUrl/folders/$userId/$folderId');
    try {
      final response = await http.delete(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> renameFolder(String userId, String folderId, String newName) async {
    final uri = Uri.parse('$baseUrl/folders/$userId/$folderId/rename').replace(queryParameters: {
      'new_name': newName,
    });
    try {
      final response = await http.put(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteFile(String userId, String fileId) async {
    final uri = Uri.parse('$baseUrl/files/$userId/$fileId');
    try {
      final response = await http.delete(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> renameFile(String userId, String fileId, String newName) async {
    final uri = Uri.parse('$baseUrl/files/$userId/$fileId/rename').replace(queryParameters: {
      'new_name': newName,
    });
    try {
      final response = await http.put(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
