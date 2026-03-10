class ApiUrls {
  // ===== Base =====
  static const String baseUrl = 'https://alnaimi.cc/ci4_app/api';

  // ===== Auth & Sync =====
  static const String googleLogin = '$baseUrl/auth/google';
  static const String syncUrl = "$baseUrl/sync";
  static const String submitReport = '$baseUrl/reports/submit';

  // ===== Users & Profile =====
  static const String userProfile = '$baseUrl/users/profile';
  static const String updateProfile = '$baseUrl/users/update';
  static const String followUser = '$baseUrl/users/follow';
  static const String followersList = '$baseUrl/users/followers';
  static const String followingList = '$baseUrl/users/following';
  static const String userPosts = '$baseUrl/users/posts';
  static const String userVideos = '$baseUrl/users/videos';
  static const String setOnline = '$baseUrl/messages/private/status/online';
  static const String setOffline = '$baseUrl/messages/private/status/offline';

  // ===== Private Messages & Chat =====
  static const String conversations = '$baseUrl/messages/private/conversations';
  static const String chatMessages = '$baseUrl/messages/private/chat';
  static const String sendMessage = '$baseUrl/messages/private/send';
  static const String markRead = '$baseUrl/messages/private/mark-seen';
  static const String getChatId = '$baseUrl/messages/private/get-id';
  static const String userStatus = '$baseUrl/messages/private/status/check';

  // ===== Block System =====
  static const String blockUser = '$baseUrl/users/block';
  static const String unblockUser = '$baseUrl/users/unblock';
  static const String blockedList = '$baseUrl/users/list-block';
  static const String checkBlock = '$baseUrl/users/check';

  // ===== General Content =====
  static const String posts = '$baseUrl/posts';
  static const String createPost = '$baseUrl/users/posts/store'; // ✅ الرابط الجديد الذي أرسلته
  static const String videos = '$baseUrl/videos';
  static const String uploadVideo = '$baseUrl/videos/upload-video';
  static const String comments = '$baseUrl/comments';
  static const String likeToggle = '$baseUrl/like/toggle';
}
