import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/services/BookingService.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'AddBookingPage.dart';

class MyBookings extends StatefulWidget {
  const MyBookings({super.key});

  @override
  State<MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<MyBookings> {
  late Future<dynamic> bookingsFuture;
  bool _isLoading = false;
  String _selectedFilter = 'all'; // all, upcoming, past

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

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

      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Erreur de format: $dateValue';
    }
  }

  String formatTime(dynamic dateValue) {
    if (dateValue == null) return '';

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return '';
      }

      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  bool isUpcoming(dynamic dateValue) {
    if (dateValue == null) return false;

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return false;
      }

      return date.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String getDuration(dynamic startDate, dynamic endDate) {
    if (startDate == null || endDate == null) return '';

    try {
      DateTime start = startDate is String ? DateTime.parse(startDate) : startDate;
      DateTime end = endDate is String ? DateTime.parse(endDate) : endDate;

      Duration duration = end.difference(start);
      int hours = duration.inHours;
      int minutes = duration.inMinutes % 60;

      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h${minutes.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  List<dynamic> _filterBookings(List<dynamic> bookings) {
    switch (_selectedFilter) {
      case 'upcoming':
        return bookings.where((booking) => isUpcoming(booking['start_date'])).toList();
      case 'past':
        return bookings.where((booking) => !isUpcoming(booking['start_date'])).toList();
      default:
        return bookings;
    }
  }

  void _navigateToAddBooking() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBookingPage(),
      ),
    );

    if (result == true) {
      _loadBookings();
    }
  }

  void _showCancelDialog(BuildContext context, dynamic booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler la réservation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['Spaces']?['name'] ?? 'Espace inconnu',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Le ${formatDate(booking['start_date'])}'),
                    Text('${formatTime(booking['start_date'])} - ${formatTime(booking['end_date'])}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Garder'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking(booking['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _cancelBooking(int bookingId) {
    BookingService().deleteBooking(bookingId).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Réservation annulée avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      _loadBookings();
    }).catchError((error) {
      // L'erreur est déjà formatée par BookingService._formatErrorMessage
      String errorMessage = error.toString().replaceAll('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
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
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        label: Text('Toutes'),
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: 'upcoming',
                        label: Text('À venir'),
                        icon: Icon(Icons.schedule),
                      ),
                      ButtonSegment(
                        value: 'past',
                        label: Text('Passées'),
                        icon: Icon(Icons.history),
                      ),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedFilter = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Liste des réservations
          Expanded(
            child: FutureBuilder<dynamic>(
              future: bookingsFuture,
              builder: (context, snapshot) {
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

                if (snapshot.hasData) {
                  final allBookings = snapshot.data;

                  if (allBookings == null || (allBookings is List && allBookings.isEmpty)) {
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

                  if (allBookings is List) {
                    final filteredBookings = _filterBookings(allBookings);

                    // Trier par date (les plus récentes en premier)
                    filteredBookings.sort((a, b) {
                      try {
                        final dateA = DateTime.parse(a['start_date']);
                        final dateB = DateTime.parse(b['start_date']);
                        return dateB.compareTo(dateA);
                      } catch (e) {
                        return 0;
                      }
                    });

                    if (filteredBookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.filter_list, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune réservation ${_selectedFilter == 'upcoming' ? 'à venir' : _selectedFilter == 'past' ? 'passée' : ''} trouvée',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = filteredBookings[index];
                        final upcoming = isUpcoming(booking['start_date']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: upcoming
                                  ? Border.all(color: Colors.green.shade300, width: 1)
                                  : null,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: upcoming
                                      ? Colors.green.shade100
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  upcoming ? Icons.schedule : Icons.history,
                                  color: upcoming
                                      ? Colors.green.shade600
                                      : Colors.grey.shade600,
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      booking['Spaces']?['name'] ?? 'Espace inconnu',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (upcoming)
                                    Chip(
                                      label: const Text(
                                        'À venir',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      backgroundColor: Colors.green.shade100,
                                      side: BorderSide(color: Colors.green.shade300),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        formatDate(booking['start_date']),
                                        style: TextStyle(color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${formatTime(booking['start_date'])} - ${formatTime(booking['end_date'])}',
                                        style: TextStyle(color: Colors.grey.shade700),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          getDuration(booking['start_date'], booking['end_date']),
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: upcoming
                                  ? IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _showCancelDialog(context, booking),
                                tooltip: 'Annuler la réservation',
                              )
                                  : Icon(Icons.check_circle, color: Colors.grey.shade400),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return Center(
                    child: Text('Réservations: ${allBookings.toString()}'),
                  );
                }

                return const Center(
                  child: Text('Aucune donnée disponible'),
                );
              },
            ),
          ),
        ],
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