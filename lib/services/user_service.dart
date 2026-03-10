import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_urls.dart';
import '../models/user_model.dart';
import 'base_service.dart';

class UserService extends BaseService {
  Future<UserModel?> updateUser({
    required int userId,
    String? name,
    String? username,
    String? bio,
    File? photo,
    File? cover,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'user_id': userId,
      };

      if (name != null) data['name'] = name;
      if (username != null) data['username'] = username;
      if (bio != null) data['bio'] = bio;

      if (photo != null) {
        data['photo'] = await MultipartFile.fromFile(
          photo.path,
          filename: 'profile_$userId.jpg',
        );
      }

      if (cover != null) {
        data['cover'] = await MultipartFile.fromFile(
          cover.path,
          filename: 'cover_$userId.jpg',
        );
      }

      final formData = FormData.fromMap(data);

      final response = await safePost(
        ApiUrls.updateProfile,
        data: formData,
      );

      if (response != null && response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['user']);
      }
    } catch (e) {
      print('Update User Error: $e');
    }
    return null;
  }

  /// ✅ تحديث إعدادات الخصوصية
  Future<UserModel?> updatePrivacySettings({
    required int userId,
    required bool chatEnabled,
    required bool notificationsEnabled,
    required bool followEnabled,
  }) async {
    final response = await safePost(
      '${ApiUrls.baseUrl}/users/privacy-settings',
      data: {
        'user_id': userId,
        'chat_enabled': chatEnabled ? 1 : 0,
        'notifications_enabled': notificationsEnabled ? 1 : 0,
        'follow_enabled': followEnabled ? 1 : 0,
      },
    );

    if (response != null && response.data['status'] == 'success') {
      return UserModel.fromJson(response.data['user']);
    }
    return null;
  }

  Future<List<UserModel>> fetchUserList({
    required String url,
    required int userId,
    int page = 1,
  }) async {
    try {
      final response = await safeGet(
        url,
        queryParameters: {
          'user_id': userId,
          'page': page,
        },
      );

      if (response != null && response.data['status'] == 'success') {
        final List data = response.data['data'];
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Fetch User List Error: $e');
    }
    return [];
  }
}
