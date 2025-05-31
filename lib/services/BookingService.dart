import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class BookingService {
  // This class will handle the booking logic of the application.
  // It will interact with the Supabase database to manage bookings.
  final SupabaseClient _supabase = Supabase.instance.client;

  // Singleton instance
  static final BookingService _instance = BookingService._internal();
  // Private constructor
  BookingService._internal();
  // Factory constructor to return the singleton instance
  factory BookingService() {
    return _instance;
  }

  // Method to create a booking
  Future<void> createBooking(String spaceId, String userId, DateTime startTime, DateTime endTime) async {
    final response = await _supabase.from('Bookings').insert({
      'space_id': spaceId,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    });

    if (response.error != null) {
      throw Exception('Failed to create booking: ${response.error!.message}');
    }
  }

  // Method to get bookings for a specific user
  getBookingsForUser(String userId) async {
    return await _supabase
            .from('Bookings')
            .select('*, Profiles(name)')
            .eq('UUID', userId);
  }

}