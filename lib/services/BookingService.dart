import 'package:reservation_parties_communes_nemea/services/AuthService.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static final BookingService _instance = BookingService._internal();
  BookingService._internal();
  factory BookingService() {
    return _instance;
  }

  // Vérifier les conflits de réservation
  Future<List<Map<String, dynamic>>> checkBookingConflicts(
      String spaceId,
      DateTime startTime,
      DateTime endTime,
      {int? excludeBookingId} // Pour exclure une réservation lors de la modification
      ) async {
    try {
      print('Checking conflicts for:');
      print('  spaceId: $spaceId');
      print('  startTime: ${startTime.toIso8601String()}');
      print('  endTime: ${endTime.toIso8601String()}');

      var query = _supabase
          .from('Bookings')
          .select('id, start_date, end_date, user_id')
          .eq('space_id', spaceId);

      // Exclure une réservation spécifique si fournie (pour les modifications)
      if (excludeBookingId != null) {
        query = query.neq('id', excludeBookingId);
      }

      final response = await query;

      if (response is List) {
        final bookings = List<Map<String, dynamic>>.from(response);

        final conflicts = bookings.where((booking) {
          final existingStart = DateTime.parse(booking['start_date']);
          final existingEnd = DateTime.parse(booking['end_date']);

          // Vérifier s'il y a chevauchement
          return _hasTimeOverlap(startTime, endTime, existingStart, existingEnd);
        }).toList();

        print('Found ${conflicts.length} conflicts');
        return conflicts;
      }

      return [];
    } catch (e) {
      print('Error checking booking conflicts: $e');
      String userMessage = _formatErrorMessage(e.toString());
      throw Exception(userMessage);
    }
  }

  // Vérifier s'il y a chevauchement entre deux créneaux
  bool _hasTimeOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    // Deux créneaux se chevauchent si :
    // - Le début du premier est avant la fin du second ET
    // - Le début du second est avant la fin du premier
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  // Méthode améliorée pour créer une réservation avec vérification
  Future<void> createBooking(String spaceId, int userId, DateTime startTime, DateTime endTime) async {
    try {
      // 1. Vérifier les conflits
      final conflicts = await checkBookingConflicts(spaceId, startTime, endTime);

      if (conflicts.isNotEmpty) {
        throw Exception('Ce créneau est déjà réservé. Veuillez choisir un autre horaire.');
      }

      // 2. Créer la réservation si pas de conflit
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
      // Transformer les erreurs techniques en messages utilisateur
      String userMessage = _formatErrorMessage(e.toString());
      throw Exception(userMessage);
    }
  }

  // Méthode pour transformer les erreurs techniques en messages utilisateur
  String _formatErrorMessage(String error) {
    // Erreurs de conflit de réservation
    if (error.contains('Conflit de réservation') || error.contains('booking_conflict_check')) {
      return 'Ce créneau est déjà réservé. Veuillez choisir un autre horaire.';
    }

    // Erreurs de validation d'horaire
    if (error.contains('heure de fin doit être après') || error.contains('P0002')) {
      return 'L\'heure de fin doit être après l\'heure de début.';
    }

    // Erreurs de connexion
    if (error.contains('Failed to connect') || error.contains('network') || error.contains('timeout')) {
      return 'Problème de connexion. Vérifiez votre internet et réessayez.';
    }

    // Erreurs d'authentification
    if (error.contains('authentication') || error.contains('unauthorized') || error.contains('401')) {
      return 'Vous devez être connecté pour effectuer cette action.';
    }

    // Erreurs de permissions
    if (error.contains('permission') || error.contains('access denied') || error.contains('403')) {
      return 'Vous n\'avez pas les permissions nécessaires pour cette action.';
    }

    // Erreurs de données manquantes
    if (error.contains('null') || error.contains('required') || error.contains('missing')) {
      return 'Certaines informations sont manquantes. Veuillez vérifier votre saisie.';
    }

    // Erreurs PostgreSQL génériques
    if (error.contains('duplicate key') || error.contains('unique constraint')) {
      return 'Cette réservation existe déjà.';
    }

    // Erreurs Supabase génériques
    if (error.contains('supabase') || error.contains('postgrest')) {
      return 'Erreur du serveur. Veuillez réessayer dans quelques instants.';
    }

    // Message générique pour toute autre erreur
    return 'Une erreur s\'est produite. Veuillez réessayer.';
  }

  // Obtenir les créneaux occupés pour un espace à une date donnée
  Future<List<Map<String, dynamic>>> getOccupiedSlots(String spaceId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _supabase
          .from('Bookings')
          .select('id, start_date, end_date, user_id')
          .eq('space_id', spaceId)
          .or('and(start_date.gte.${startOfDay.toIso8601String()},start_date.lt.${endOfDay.toIso8601String()}),and(end_date.gt.${startOfDay.toIso8601String()},end_date.lte.${endOfDay.toIso8601String()}),and(start_date.lt.${startOfDay.toIso8601String()},end_date.gt.${endOfDay.toIso8601String()})');

      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      }

      return [];
    } catch (e) {
      print('Error getting occupied slots: $e');
      String userMessage = _formatErrorMessage(e.toString());
      throw Exception(userMessage);
    }
  }

  // Proposer des créneaux libres pour un espace et une date
  Future<List<Map<String, String>>> getSuggestedFreeSlots(String spaceId, DateTime date) async {
    try {
      final occupiedSlots = await getOccupiedSlots(spaceId, date);
      final suggestions = <Map<String, String>>[];

      // Créneaux standards de 2h (vous pouvez ajuster selon vos besoins)
      final standardSlots = [
        {'start': '08:00', 'end': '10:00'},
        {'start': '10:00', 'end': '12:00'},
        {'start': '12:00', 'end': '14:00'},
        {'start': '14:00', 'end': '16:00'},
        {'start': '16:00', 'end': '18:00'},
        {'start': '18:00', 'end': '20:00'},
        {'start': '20:00', 'end': '22:00'},
      ];

      for (final slot in standardSlots) {
        final startTime = DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(slot['start']!.split(':')[0]),
            int.parse(slot['start']!.split(':')[1])
        );
        final endTime = DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(slot['end']!.split(':')[0]),
            int.parse(slot['end']!.split(':')[1])
        );

        // Vérifier si ce créneau est libre
        bool isFree = true;
        for (final occupied in occupiedSlots) {
          final occupiedStart = DateTime.parse(occupied['start_date']);
          final occupiedEnd = DateTime.parse(occupied['end_date']);

          if (_hasTimeOverlap(startTime, endTime, occupiedStart, occupiedEnd)) {
            isFree = false;
            break;
          }
        }

        if (isFree) {
          suggestions.add(slot);
        }
      }

      return suggestions;
    } catch (e) {
      print('Error getting suggested free slots: $e');
      // Pour les suggestions, on retourne une liste vide plutôt qu'une erreur
      return [];
    }
  }

  // Version de debug pour voir exactement ce qui est retourné
  Future<List<Map<String, dynamic>>> getBookingsForUser(String UUID) async {
    try {
      print('Getting bookings for UUID: $UUID');

      final user = await AuthService().getUserFromUUID(UUID);
      if (user == null) {
        throw Exception('Utilisateur non trouvé. Veuillez vous reconnecter.');
      }

      print('Found user: $user');

      // Utiliser les bons noms de tables et colonnes
      final responseWithSpaces = await _supabase
          .from('Bookings')
          .select('*, Spaces(name)')
          .eq('user_id', user['id'])
          .order('start_date', ascending: false); // Trier par date décroissante

      print('Response with spaces: $responseWithSpaces');

      if (responseWithSpaces is List) {
        return List<Map<String, dynamic>>.from(responseWithSpaces);
      }

      return [];
    } catch (e) {
      print('Error getting bookings: $e');
      String userMessage = _formatErrorMessage(e.toString());
      throw Exception(userMessage);
    }
  }

  // Méthode pour supprimer une réservation
  Future<void> deleteBooking(int bookingId) async {
    try {
      final response = await _supabase.from('Bookings').delete().eq('id', bookingId);
      print('Booking deleted successfully');
    } catch (e) {
      print('Error deleting booking: $e');
      String userMessage = _formatErrorMessage(e.toString());
      throw Exception(userMessage);
    }
  }
}