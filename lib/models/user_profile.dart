class UserProfile {
  final String userId;
  final String name;
  final String nationality;
  final String language; // 例: 'en', 'ja', 'ko', 'zh_tw', 'zh_cn', 'th'
  final String friendCode;
  final List<String> friends;

  UserProfile({
    required this.userId,
    required this.name,
    required this.nationality,
    required this.language,
    required this.friendCode,
    required this.friends,
  });

  // Firestoreに保存するときの形式に変換
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nationality': nationality,
      'language': language,
      'friendCode': friendCode,
      'friendCodeLower': friendCode.toLowerCase(),
      'friends': friends,
    };
  }

  // Firestoreから取得したデータをUserProfileに変換
  factory UserProfile.fromMap(String userId, Map<String, dynamic> map) {
    return UserProfile(
      userId: userId,
      name: map['name'] ?? '',
      nationality: map['nationality'] ?? '',
      language: map['language'] ?? 'en',
      friendCode: map['friendCode'] ?? '',
      friends: (map['friends'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
