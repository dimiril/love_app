class UserModel {
  final int id;
  final String name;
  final String? username;
  final String photoUrl;
  final String? coverUrl;
  final String? status;
  final String? bio;

  final int postsCount;
  final int commentsCount;
  final int profileViews;
  final int followersCount;
  final int followingCount;

  // إعدادات الخصوصية
  final bool chatEnabled;
  final bool notificationsEnabled;
  final bool followEnabled;

  final String? token;

  UserModel({
    required this.id,
    required this.name,
    this.username,
    required this.photoUrl,
    this.coverUrl,
    this.status,
    this.bio,
    this.postsCount = 0,
    this.commentsCount = 0,
    this.profileViews = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.chatEnabled = true,
    this.notificationsEnabled = true,
    this.followEnabled = true,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة داخلية لتحويل القيم إلى bool بشكل مضمون
    bool toBool(dynamic value) {
      if (value == null) return true; // القيمة الافتراضية مفعل
      if (value is bool) return value;
      final String str = value.toString();
      return str == "1" || str.toLowerCase() == "true";
    }

    return UserModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      username: json['username'],
      photoUrl: json['photo_url'] ?? '',
      coverUrl: json['cover_url'],
      status: json['status'],
      bio: json['bio'],
      postsCount: int.parse(json['posts_count']?.toString() ?? '0'),
      commentsCount: int.parse(json['comments_count']?.toString() ?? '0'),
      profileViews: int.parse(json['profile_views']?.toString() ?? '0'),
      followersCount: int.parse(json['followers_count']?.toString() ?? '0'),
      followingCount: int.parse(json['following_count']?.toString() ?? '0'),

      chatEnabled: toBool(json['chat_enabled']),
      notificationsEnabled: toBool(json['notifications_enabled']),
      followEnabled: toBool(json['follow_enabled']),
      
      token: json['token'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'photo_url': photoUrl,
      'cover_url': coverUrl,
      'status': status,
      'bio': bio,
      'posts_count': postsCount,
      'comments_count': commentsCount,
      'profile_views': profileViews,
      'followers_count': followersCount,
      'following_count': followingCount,
      'chat_enabled': chatEnabled ? 1 : 0,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'follow_enabled': followEnabled ? 1 : 0,
      'token': token,
    };
  }
}
