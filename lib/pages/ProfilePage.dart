import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:reservation_parties_communes_nemea/services/AuthService.dart';
import 'package:reservation_parties_communes_nemea/services/BookingService.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> userBookings = [];
  bool _isLoading = true;
  bool _isLoadingStats = true;

  // Statistiques utilisateur
  int totalBookings = 0;
  int upcomingBookings = 0;
  String favoriteSpace = "Aucun";
  double averageDuration = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        // Charger le profil utilisateur
        final profile = await _authService.getUserFromUUID(currentUser.id);

        // Charger les réservations pour les statistiques
        final bookings = await BookingService().getBookingsForUser(currentUser.id);

        setState(() {
          userProfile = profile;
          userBookings = bookings;
          _isLoading = false;
        });

        // Calculer les statistiques
        _calculateStats();
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
        _isLoadingStats = false;
      });
    }
  }

  void _calculateStats() {
    try {
      totalBookings = userBookings.length;

      // Compter les réservations à venir
      final now = DateTime.now();
      upcomingBookings = userBookings.where((booking) {
        try {
          final startDate = DateTime.parse(booking['start_date']);
          return startDate.isAfter(now);
        } catch (e) {
          return false;
        }
      }).length;

      // Trouver l'espace le plus réservé
      if (userBookings.isNotEmpty) {
        final spaceCount = <String, int>{};
        for (final booking in userBookings) {
          final spaceName = booking['Spaces']?['name'] ?? 'Inconnu';
          spaceCount[spaceName] = (spaceCount[spaceName] ?? 0) + 1;
        }

        if (spaceCount.isNotEmpty) {
          favoriteSpace = spaceCount.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }

        // Calculer la durée moyenne des réservations
        double totalHours = 0;
        int validBookings = 0;

        for (final booking in userBookings) {
          try {
            final start = DateTime.parse(booking['start_date']);
            final end = DateTime.parse(booking['end_date']);
            final duration = end.difference(start).inMinutes / 60.0;
            totalHours += duration;
            validBookings++;
          } catch (e) {
            // Ignorer les réservations avec des dates invalides
          }
        }

        if (validBookings > 0) {
          averageDuration = totalHours / validBookings;
        }
      }

      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _authService.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userProfile?['name'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Modifier le profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'L\'email ne peut pas être modifié depuis cette interface.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Ici vous pourriez ajouter la logique pour sauvegarder les modifications
                // Par exemple, appeler une méthode de AuthService pour mettre à jour le nom
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  _authService.changeUserName(newName);
                  setState(() {
                    userProfile?['name'] = newName;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom ne peut pas être vide.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom a été mis à jour avec succès.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du profil...'),
          ],
        ),
      )
          : CustomScrollView(
        slivers: [
          // App Bar avec avatar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(
                          _getInitials(userProfile?['name'] ?? currentUser?.email ?? 'U'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Nom
                    Text(
                      userProfile?['name'] ?? 'Utilisateur',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Email
                    Text(
                      currentUser?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
              ),
            ],
          ),

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistiques
                  const Text(
                    'Mes statistiques',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingStats)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(
                          'Total réservations',
                          totalBookings.toString(),
                          Icons.event,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'À venir',
                          upcomingBookings.toString(),
                          Icons.schedule,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Espace favori',
                          favoriteSpace,
                          Icons.favorite,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Durée moyenne',
                          '${averageDuration.toStringAsFixed(1)}h',
                          Icons.timer,
                          Colors.orange,
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Actions
                  const Text(
                    'Paramètres',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildActionCard(
                    'Modifier le profil',
                    'Changez votre nom et vos informations',
                    Icons.edit,
                    Colors.blue,
                    _showEditProfileDialog,
                  ),

                  const SizedBox(height: 12),

                  _buildActionCard(
                    'À propos',
                    'Informations sur l\'application',
                    Icons.info,
                    Colors.grey,
                        () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Réservation Parties Communes',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.apartment, size: 64),
                        children: [
                          const Text(
                            'Application de réservation des parties communes pour les résidences Nemea.',
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Bouton de déconnexion
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return parts[0][0].toUpperCase();
    }
  }
}