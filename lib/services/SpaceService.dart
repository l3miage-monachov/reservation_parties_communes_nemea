import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class SpaceService {
  // declare supabase client
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'Spaces';

  // Method to get details of a space
  getSpaceDetails(int spaceId) async {
    // Implementation for fetching space details
    return await _supabase
        .from(_tableName)
        .select()
        .eq('id', spaceId)
        .maybeSingle();
  }

  // Method to update a space
  Future<void> updateSpace(String spaceId, String name, String description) async {
    // Implementation for updating a space
  }

  // Method to delete a space
  Future<void> deleteSpace(String spaceId) async {
    // Implementation for deleting a space
  }
}