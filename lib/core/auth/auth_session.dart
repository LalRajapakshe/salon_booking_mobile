class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? accessToken;
  String? username;
  DateTime? expiresAt;

  bool get isSignedIn => accessToken != null && accessToken!.isNotEmpty;

  void save({
    required String accessToken,
    required String username,
    required DateTime expiresAt,
  }) {
    this.accessToken = accessToken;
    this.username = username;
    this.expiresAt = expiresAt;
  }

  void clear() {
    accessToken = null;
    username = null;
    expiresAt = null;
  }
}
