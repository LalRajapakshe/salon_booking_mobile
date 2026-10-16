class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? accessToken;
  String? username;
  String? fullName;
  DateTime? expiresAt;
  Set<String> permissions = {};

  bool get isSignedIn => accessToken != null && accessToken!.isNotEmpty;

  bool can(String permission) => permissions.contains(permission);

  void save({
    required String accessToken,
    required String username,
    required DateTime expiresAt,
    String? fullName,
    Set<String>? permissions,
  }) {
    this.accessToken = accessToken;
    this.username = username;
    this.fullName = fullName;
    this.expiresAt = expiresAt;
    this.permissions = permissions ?? {};
  }

  void clear() {
    accessToken = null;
    username = null;
    fullName = null;
    expiresAt = null;
    permissions = {};
  }
}
