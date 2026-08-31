class UserProfile {
  final String userId;
  final String name;
  final String nationality;
  final String language; // 例: 'en', 'ja', 'ko', 'zh_tw', 'zh_cn', 'th'

  UserProfile({
    required this.userId,
    required this.name,
    required this.nationality,
    required this.language,
  });

  // Firestoreに保存するときの形式に変換
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nationality': nationality,
      'language': language,
    };
  }

  // Firestoreから取得したデータをUserProfileに変換
  factory UserProfile.fromMap(String userId, Map<String, dynamic> map) {
    return UserProfile(
      userId: userId,
      name: map['name'] ?? '',
      nationality: map['nationality'] ?? '',
      language: map['language'] ?? 'en',
    );
  }
}
