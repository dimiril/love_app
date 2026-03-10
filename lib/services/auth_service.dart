import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/api_urls.dart';
import '../models/user_model.dart';
import '../utils/shared_pref.dart';
import 'base_service.dart';

class AuthService extends BaseService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: "864797227247-bi4ehktlp1nh8p7t0a3njpphmut7dscl.apps.googleusercontent.com",
  );

  Future<UserModel?> loginWithGoogle() async {
    try {
      // 1. تسجيل الدخول بجوجل
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return null;

      // 2. جلب الـ FCM Token للإشعارات
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print('Error getting FCM token: $e');
      }

      // 3. إرسال البيانات للسيرفر
      final response = await safePost(
        ApiUrls.googleLogin,
        data: {
          'idToken': idToken,
          'fcm_token': fcmToken, // إرسال التوكن الجديد
        },
      );

      if (response != null && response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['user']);
      }
    } catch (e) {
      print('Google Login Error: $e');
    }
    return null;
  }

  Future<UserModel?> getUserProfile(int userId) async {
    try {
      final response = await safeGet(
        ApiUrls.userProfile,
        queryParameters: {'user_id': userId},
      );

      if (response != null && response.data['status'] == 'success') {
        return UserModel.fromJson(response.data['user']);
      }
    } catch (e) {
      print('Get User Profile Error: $e');
    }
    return null;
  }

  Future<void> logout() async {
    try {
      // 1. تسجيل الخروج من جوجل
      await _googleSignIn.signOut();
      
      await SharedPref.clear();
    } catch (e) {
      print('Logout Error: $e');
    }
  }
}
