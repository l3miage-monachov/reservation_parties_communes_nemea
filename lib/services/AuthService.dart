import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  // Private constructor
  AuthService._internal();

  // Factory constructor to return the singleton instance
  factory AuthService() {
    return _instance;
  }

  // Method to check if the user is authenticated
  bool isAuthenticated() {
    // Implement your authentication logic here
    return false; // Placeholder return value
  }

  //sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  //sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword(String email, String password) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  //Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  //get user email
  String? getUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}