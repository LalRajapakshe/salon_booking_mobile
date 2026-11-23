class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  String? accessToken;
  String? username;
  String? fullName;
  DateTime? expiresAt;
  int? branchId;
  int? employeeId;
  Set<String> permissions = {};

  bool get isSignedIn => accessToken != null && accessToken!.isNotEmpty;

  bool can(String permission) => permissions.contains(permission);

  void save({
    required String accessToken,
    required String username,
    required DateTime expiresAt,
    String? fullName,
    int? branchId,
    int? employeeId,
    Set<String>? permissions,
  }) {
    this.accessToken = accessToken;
    this.username = username;
    this.fullName = fullName;
    this.expiresAt = expiresAt;
    this.branchId = branchId;
    this.employeeId = employeeId;
    this.permissions = permissions ?? {};
  }

  void clear() {
    accessToken = null;
    username = null;
    fullName = null;
    expiresAt = null;
    branchId = null;
    employeeId = null;
    permissions = {};
  }
}
