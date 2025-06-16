import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/services/BookingService.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'AddBookingPage.dart'; // Ajoutez cet import

class MyBookings extends StatefulWidget {
  const MyBookings({super.key});

  @override
  State<MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<MyBookings> {
  late Future<dynamic> bookingsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  // Méthode séparée pour charger les réservations
  void _loadBookings() {
    setState(() {
      _isLoading = true;
    });

    bookingsFuture = BookingService().getBookingsForUser(
        Supabase.instance.client.auth.currentUser!.id
    ).then((data) {
      setState(() {
        _isLoading = false;
      });
      return data;
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      throw error;
    });
  }

  // Fonction pour formater les dates
  String formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Date non disponible';

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Format de date invalide';
      }

      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Erreur de format: $dateValue';
    }
  }

  // Navigation vers la page d'ajout de réservation
  void _navigateToAddBooking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBookingPage(),
      ),
    );

    // Si une réservation a été créée, recharger la liste
    if (result == true) {
      _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: bookingsFuture,
        builder: (context, snapshot) {
          // Pendant le chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des réservations...'),
                ],
              ),
            );
          }

          // En cas d'erreur
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookings,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Quand les données sont disponibles
          if (snapshot.hasData) {
            final bookings = snapshot.data;

            // Si aucune réservation
            if (bookings == null || (bookings is List && bookings.isEmpty)) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune réservation trouvée',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddBooking,
                      icon: const Icon(Icons.add),
                      label: const Text('Créer ma première réservation'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Afficher la liste des réservations
            if (bookings is List) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.event,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      title: Text(
                        booking['Spaces']?['name'] ?? 'Espace inconnu',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Début: ${formatDate(booking['start_date'])}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_filled, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Fin: ${formatDate(booking['end_date'])}'),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'cancel') {
                            BookingService().deleteBooking(booking['id']).then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Réservation annulée')),
                              );
                              _loadBookings(); // Recharger les réservations
                            }).catchError((error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $error')),
                              );
                            });
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Annuler'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            // Fallback pour autres types de données
            return Center(
              child: Text('Réservations: ${bookings.toString()}'),
            );
          }

          // État par défaut
          return const Center(
            child: Text('Aucune donnée disponible'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBooking,
        foregroundColor: Colors.white,
        backgroundColor: Colors.amber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}