class SyncSettings {
  final bool isEnabled;
  final String roomId;
  final String password;
  final String supabaseUrl;
  final String supabaseAnonKey;

  const SyncSettings({
    this.isEnabled = false,
    this.roomId = '',
    this.password = '',
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
  });

  SyncSettings copyWith({
    bool? isEnabled,
    String? roomId,
    String? password,
    String? supabaseUrl,
    String? supabaseAnonKey,
  }) {
    return SyncSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      roomId: roomId ?? this.roomId,
      password: password ?? this.password,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
    );
  }
}
