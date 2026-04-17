class SyncSettings {
  final bool isEnabled;
  final String roomId;
  final String password;
  final String userName; // 追加
  final String deviceId; // 追加
  final String supabaseUrl;
  final String supabaseAnonKey;

  const SyncSettings({
    this.isEnabled = false,
    this.roomId = '',
    this.password = '',
    this.userName = '自分', // デフォルト値
    this.deviceId = '', // 追加
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
  });

  SyncSettings copyWith({
    bool? isEnabled,
    String? roomId,
    String? password,
    String? userName,
    String? deviceId,
    String? supabaseUrl,
    String? supabaseAnonKey,
  }) {
    return SyncSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      roomId: roomId ?? this.roomId,
      password: password ?? this.password,
      userName: userName ?? this.userName,
      deviceId: deviceId ?? this.deviceId,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
    );
  }
}
