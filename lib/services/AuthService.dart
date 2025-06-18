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
    return _supabase.auth.currentUser != null;
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
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user != null) {
      await createUserProfile(response.user!.id, null, email);
    }
    return response;
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

  // Méthode existante pour récupérer l'utilisateur par UUID
  Future<Map<String, dynamic>> getUserFromUUID(String uuid) async {
    return await _supabase
        .from('Profiles')
        .select('id, name, UUID, created_at')
        .eq('UUID', uuid)
        .single();
  }

  // Méthode corrigée pour changer le nom de l'utilisateur
  Future<void> changeUserName(String newName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // D'abord, récupérer l'ID numérique de l'utilisateur depuis son UUID
      final userProfile = await getUserFromUUID(user.id);
      final numericUserId = userProfile['id'];

      // Ensuite, mettre à jour le nom en utilisant l'ID numérique
      final response = await _supabase
          .from('Profiles')
          .update({'name': newName})
          .eq('id', numericUserId)
          .select('name');

      print('Nom d\'utilisateur mis à jour: $response');
    } catch (e) {
      print('Erreur lors de la mise à jour du nom: $e');
      // Transformer l'erreur technique en message utilisateur
      String userMessage = _formatErrorMessage(e.toString());
      throw Exception(userMessage);
    }
  }

  // Méthode alternative qui utilise directement l'UUID (plus simple)
  Future<void> changeUserNameByUUID(String newName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Mettre à jour directement en utilisant l'UUID
      final response = await _supabase
          .from('Profiles')
          .update({'name': newName})
          .eq('UUID', user.id)  // Utiliser l'UUID directement
          .select('name');

      print('Nom d\'utilisateur mis à jour: $response');
    } catch (e) {
      print('Erreur lors de la mise à jour du nom: $e');
      String userMessage = _formatErrorMessage(e.toString());
      throw Exception(userMessage);
    }
  }

  // Méthode pour obtenir le profil complet de l'utilisateur actuel
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      return await getUserFromUUID(user.id);
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  // Méthode pour créer un profil utilisateur lors de l'inscription
  Future<void> createUserProfile(String uuid, String? name, String? email) async {
    try {
      await _supabase.from('Profiles').insert({
        'UUID': uuid,
        'name': name ?? email?.split('@')[0] ?? 'Utilisateur',
      });
    } catch (e) {
      print('Erreur lors de la création du profil: $e');
      throw Exception('Erreur lors de la création du profil utilisateur');
    }
  }

  // Méthode pour formater les erreurs en messages utilisateur
  String _formatErrorMessage(String error) {
    if (error.contains('invalid input syntax') || error.contains('22P02')) {
      return 'Erreur de données. Veuillez réessayer.';
    }

    if (error.contains('authentication') || error.contains('unauthorized')) {
      return 'Vous devez être connecté pour effectuer cette action.';
    }

    if (error.contains('network') || error.contains('timeout')) {
      return 'Problème de connexion. Vérifiez votre internet.';
    }

    if (error.contains('not found')) {
      return 'Profil utilisateur non trouvé.';
    }

    return 'Une erreur s\'est produite. Veuillez réessayer.';
  }
}