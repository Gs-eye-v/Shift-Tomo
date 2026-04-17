class Profile {
  final String id;
  final String name;
  final bool isMe;

  const Profile({
    required this.id,
    required this.name,
    this.isMe = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_me': isMe ? 1 : 0,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      isMe: (map['is_me'] as int) == 1,
    );
  }
}
