import 'dart:convert';

class Partner {
  final String id; // 内部管理用 (UUIDなど)
  final String displayName; // ユーザーが決める表示名
  final String roomId;
  final String password;
  final String profileName; // ルーム内のどの名前を表示するか
  final bool isReadOnly; // 閲覧専用フラグ

  const Partner({
    required this.id,
    required this.displayName,
    required this.roomId,
    required this.password,
    required this.profileName,
    this.isReadOnly = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'room_id': roomId,
      'password': password,
      'profile_name': profileName,
      'is_read_only': isReadOnly,
    };
  }

  factory Partner.fromMap(Map<String, dynamic> map) {
    return Partner(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      roomId: map['room_id'] as String,
      password: map['password'] as String,
      profileName: map['profile_name'] as String,
      isReadOnly: map['is_read_only'] as bool? ?? true,
    );
  }

  String toJson() => json.encode(toMap());
  factory Partner.fromJson(String source) => Partner.fromMap(json.decode(source));
}
