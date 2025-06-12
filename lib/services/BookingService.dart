import 'package:reservation_parties_communes_nemea/services/AuthService.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final BookingService _instance = BookingService._internal();
  BookingService._internal();
  factory BookingService() {
    return _instance;
  }

  // Method to create a booking
  Future<void> createBooking(String spaceId, int userId, DateTime startTime, DateTime endTime) async {
    try {
      print('Creating booking with:');
      print('  spaceId: $spaceId');
      print('  userId: $userId');
      print('  startTime: ${startTime.toIso8601String()}');
      print('  endTime: ${endTime.toIso8601String()}');

      final response = await _supabase.from('Bookings').insert({
        'space_id': spaceId,
        'user_id': userId,
        'start_date': startTime.toIso8601String(),
        'end_date': endTime.toIso8601String(),
      });

      print('Booking created successfully');
    } catch (e) {
      print('Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  // Version de debug pour voir exactement ce qui est retourné
  Future<List<Map<String, dynamic>>> getBookingsForUser(String UUID) async {
    try {
      print('Getting bookings for UUID: $UUID');

      final user = await AuthService().getUserFromUUID(UUID);
      if (user == null) {
        throw Exception('User not found');
      }

      print('Found user: $user');

      // Essayons différentes variantes de noms de colonnes
      final response = await _supabase
          .from('Bookings')
          .select('*')  // D'abord récupérer tout pour voir la structure
          .eq('user_id', user['id']);

      print('Raw response from Supabase: $response');
      print('Response type: ${response.runtimeType}');

      if (response is List) {
        final bookingsList = List<Map<String, dynamic>>.from(response);

        // Debug: afficher la structure de chaque booking
        for (int i = 0; i < bookingsList.length; i++) {
          print('Booking $i keys: ${bookingsList[i].keys.toList()}');
          print('Booking $i: ${bookingsList[i]}');
        }

        // Maintenant essayons avec le join
        final responseWithSpaces = await _supabase
            .from('Bookings')
            .select('*, Spaces(name)')
            .eq('user_id', user['id']);

        print('Response with spaces: $responseWithSpaces');

        if (responseWithSpaces is List) {
          return List<Map<String, dynamic>>.from(responseWithSpaces);
        }

        return bookingsList;
      }

      return [];
    } catch (e) {
      print('Error getting bookings: $e');
      throw Exception('Failed to get bookings: $e');
    }
  }

  // Version alternative pour tester différents noms de colonnes
  Future<List<Map<String, dynamic>>> getBookingsForUserAlternative(String UUID) async {
    try {
      final userId = await AuthService().getUserFromUUID(UUID);
      if (userId == null) {
        throw Exception('User not found');
      }

      // Essayer différentes variantes de noms de colonnes
      final possibleQueries = [
        '*, Spaces(name)',
        'id, space_id, user_id, start_time, end_time, created_at, Spaces(name)',
        'id, space_id, user_id, startTime, endTime, created_at, Spaces(name)',
        'id, space_id, user_id, start_date, end_date, created_at, Spaces(name)',
        'id, space_id, user_id, startDate, endDate, created_at, Spaces(name)',
      ];

      for (String query in possibleQueries) {
        try {
          print('Trying query: $query');
          final response = await _supabase
              .from('Bookings')
              .select(query)
              .eq('user_id', userId['id']);

          print('Success with query: $query');
          print('Response: $response');

          if (response is List) {
            return List<Map<String, dynamic>>.from(response);
          }
        } catch (e) {
          print('Query failed: $query, error: $e');
          continue;
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get bookings: $e');
    }
  }

  // Méthode pour supprimer une réservation
  Future<void> deleteBooking(int bookingId) async {
    try {
      final response = await _supabase.from('Bookings').delete().eq('id', bookingId);
      print('Booking deleted successfully');
    } catch (e) {
      print('Error deleting booking: $e');
      throw Exception('Failed to delete booking: $e');
    }
  }
}