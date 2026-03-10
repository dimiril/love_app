import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/shared_pref.dart';
import 'like_provider.dart';
import 'follow_provider.dart';
import 'profile_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadUser();
  }

  void _loadUser() {
    final userData = SharedPref.getString('user_data');
    if (userData != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userData));
        notifyListeners();
      } catch (e) {
        debugPrint("Error decoding user data: $e");
      }
    }
  }

  Future<void> updateUserLocal(UserModel updatedUser) async {
    _user = updatedUser;
    await SharedPref.setString('user_data', jsonEncode(updatedUser.toMap()));
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final updatedUser = await _authService.getUserProfile(_user!.id);
      if (updatedUser != null) {
        updateUserLocal(updatedUser);
      }
    } catch (e) {
      debugPrint("Error refreshing user: $e");
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? username,
    String? bio,
    File? photo,
    File? cover,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    final updatedUser = await _userService.updateUser(
      userId: _user!.id,
      name: name,
      username: username,
      bio: bio,
      photo: photo,
      cover: cover,
    );
    if (updatedUser != null) {
      await updateUserLocal(updatedUser);
      _isLoading = false;
      return true;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login() async {
    _isLoading = true;
    notifyListeners();

    // يتم إرسال الـ FCM Token تلقائياً داخل هذه الدالة في AuthService
    final user = await _authService.loginWithGoogle();
    
    if (user != null) {
      await updateUserLocal(user);
      _isLoading = false;
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout(BuildContext context) async {
    final likeProvider = context.read<LikeProvider>();
    final followProvider = context.read<FollowProvider>();
    final profileProvider = context.read<ProfileProvider>();
    await _authService.logout();
    await SharedPref.clear();
    _user = null;
    likeProvider.clear();
    followProvider.clear();
    profileProvider.clearProfile();
    notifyListeners();
  }
}
