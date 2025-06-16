import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:reservation_parties_communes_nemea/pages/AddBookingPage.dart';
import 'package:reservation_parties_communes_nemea/pages/MyBookings.dart';
import 'package:reservation_parties_communes_nemea/services/AuthService.dart';
import 'package:reservation_parties_communes_nemea/services/BookingService.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> recentBookings = [];
  List<Map<String, dynamic>> upcomingBookings = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();

  // Données pour les espaces populaires
  final List<Map<String, dynamic>> popularSpaces = [
    {
      'id': '1',
      'name': 'Cuisine',
      'icon': Icons.kitchen,
      'color': Colors.orange,
      'description': 'Espace de convivialité',
    },
    {
      'id': '5',
      'name': 'Salon',
      'icon': Icons.living,
      'color': Colors.blue,
      'description': 'Détente et réunions',
    },
    {
      'id': '2',
      'name': 'Salle de sport',
      'icon': Icons.fitness_center,
      'color': Colors.green,
      'description': 'Sport et bien-être',
    },
    {
      'id': '4',
      'name': 'Terrasse',
      'icon': Icons.balcony,
      'color': Colors.purple,
      'description': 'Espace extérieur',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        // Charger le profil utilisateur
        final profile = await AuthService().getUserFromUUID(currentUser.id);

        // Charger les réservations récentes et à venir
        final allBookings = await BookingService().getBookingsForUser(currentUser.id);

        final now = DateTime.now();
        final recent = allBookings.take(3).toList();
        final upcoming = allBookings.where((booking) {
          try {
            final startDate = DateTime.parse(booking['start_date']);
            return startDate.isAfter(now);
          } catch (e) {
            return false;
          }
        }).take(3).toList();

        setState(() {
          userProfile = profile;
          recentBookings = recent;
          upcomingBookings = upcoming;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bonjour';
    } else if (hour < 18) {
      return 'Bon après-midi';
    } else {
      return 'Bonsoir';
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final bookingDate = DateTime(date.year, date.month, date.day);

      if (bookingDate.isAtSameMomentAs(today)) {
        return 'Aujourd\'hui';
      } else if (bookingDate.isAtSameMomentAs(tomorrow)) {
        return 'Demain';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }

  void _navigateToAddBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBookingPage(),
      ),
    ).then((result) {
      if (result == true) {
        _loadHomeData(); // Recharger les données si une réservation a été créée
      }
    });
  }

  void _navigateToMyBookings() {
    // Vous devrez passer l'index à votre widget parent ou utiliser un Provider
    // Pour l'instant, on navigue directement
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyBookings(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec salutation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile?['name'] ?? 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToAddBooking,
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle réservation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Réservations à venir
            if (upcomingBookings.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vos prochaines réservations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _navigateToMyBookings,
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = upcomingBookings[index];
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.schedule,
                                      color: Colors.green.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      booking['Spaces']?['name'] ?? 'Espace',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_formatDate(booking['start_date'])} • ${_formatTime(booking['start_date'])} - ${_formatTime(booking['end_date'])}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Espaces populaires
            const Text(
              'Espaces disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: popularSpaces.length,
              itemBuilder: (context, index) {
                final space = popularSpaces[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: _navigateToAddBooking,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (space['color'] as Color).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              space['icon'] as IconData,
                              size: 32,
                              color: space['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            space['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            space['description'] as String,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Activité récente
            if (recentBookings.isNotEmpty) ...[
              const Text(
                'Activité récente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentBookings.length,
                itemBuilder: (context, index) {
                  final booking = recentBookings[index];
                  final isUpcoming = DateTime.parse(booking['start_date']).isAfter(DateTime.now());

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? Colors.blue.shade100
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUpcoming ? Icons.schedule : Icons.history,
                          color: isUpcoming
                              ? Colors.blue.shade600
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        booking['Spaces']?['name'] ?? 'Espace',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_formatDate(booking['start_date'])} • ${_formatTime(booking['start_date'])} - ${_formatTime(booking['end_date'])}',
                      ),
                      trailing: isUpcoming
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : null,
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // Conseils
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Conseils',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Réservez à l\'avance pour garantir votre créneau\n'
                        '• N\'oubliez pas d\'annuler si vous ne pouvez pas venir',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}