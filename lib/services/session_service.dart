class SessionService {
  SessionService._();

  static int? userId;
  static String? email;
  static String? fullName;
  static String? token;
  static int? activeGroupId;
  static String? activeGroupName;
  static String? activeGroupCode;

  static bool get isLoggedIn => userId != null;

  static void clear() {
    userId = null;
    email = null;
    fullName = null;
    token = null;
    activeGroupId = null;
    activeGroupName = null;
    activeGroupCode = null;
  }
}
