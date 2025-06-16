// Page principale pour ajouter une réservation
import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/services/AuthService.dart';
import 'package:reservation_parties_communes_nemea/services/BookingService.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class AddBookingPage extends StatefulWidget {
  const AddBookingPage({super.key});

  @override
  State<AddBookingPage> createState() => _AddBookingPageState();
}

class _AddBookingPageState extends State<AddBookingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Données de la réservation
  String? selectedSpaceId;
  String? selectedSpaceName;
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int userId = 0;

  // Nouvelles variables pour la gestion des conflits
  List<Map<String, dynamic>> occupiedSlots = [];
  List<Map<String, String>> suggestedSlots = [];
  bool isCheckingConflicts = false;
  String? conflictError;

  final List<String> _stepTitles = [
    'Choisir un espace',
    'Choisir la date',
    'Choisir l\'heure',
    'Confirmer'
  ];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canGoNext() {
    switch (_currentPage) {
      case 0:
        return selectedSpaceId != null;
      case 1:
        return selectedDate != null;
      case 2:
        return startTime != null && endTime != null && conflictError == null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  // Nouvelle méthode pour charger les créneaux occupés
  Future<void> _loadOccupiedSlots() async {
    if (selectedSpaceId == null || selectedDate == null) return;

    try {
      final slots = await BookingService().getOccupiedSlots(selectedSpaceId!, selectedDate!);
      final suggestions = await BookingService().getSuggestedFreeSlots(selectedSpaceId!, selectedDate!);

      setState(() {
        occupiedSlots = slots;
        suggestedSlots = suggestions;
      });
    } catch (e) {
      print('Erreur lors du chargement des créneaux: $e');
    }
  }

  // Vérifier les conflits en temps réel lors de la sélection d'horaires
  Future<void> _checkTimeConflicts() async {
    if (selectedSpaceId == null || selectedDate == null || startTime == null || endTime == null) {
      setState(() {
        conflictError = null;
      });
      return;
    }

    setState(() {
      isCheckingConflicts = true;
      conflictError = null;
    });

    try {
      final startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        startTime!.hour,
        startTime!.minute,
      );

      final endDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        endTime!.hour,
        endTime!.minute,
      );

      // Vérifier si l'heure de fin est après l'heure de début
      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        setState(() {
          conflictError = 'L\'heure de fin doit être après l\'heure de début';
          isCheckingConflicts = false;
        });
        return;
      }

      final conflicts = await BookingService().checkBookingConflicts(
        selectedSpaceId!,
        startDateTime,
        endDateTime,
      );

      setState(() {
        if (conflicts.isNotEmpty) {
          conflictError = 'Ce créneau est déjà réservé. Veuillez choisir un autre horaire.';
        } else {
          conflictError = null;
        }
        isCheckingConflicts = false;
      });
    } catch (e) {
      setState(() {
        // L'erreur est déjà formatée par BookingService._formatErrorMessage
        conflictError = e.toString().replaceAll('Exception: ', '');
        isCheckingConflicts = false;
      });
    }
  }

  Future<void> _createBooking() async {
    if (selectedSpaceId == null || selectedDate == null || startTime == null || endTime == null) {
      return;
    }

    try {
      final startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        startTime!.hour,
        startTime!.minute,
      );

      final endDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        endTime!.hour,
        endTime!.minute,
      );

      print('Creating booking with:');
      print('  Space ID: $selectedSpaceId');
      print('  User UUID: ${Supabase.instance.client.auth.currentUser!.id}');
      print('  Start Time: $startDateTime');
      print('  End Time: $endDateTime');

      var user = await AuthService().getUserFromUUID(Supabase.instance.client.auth.currentUser!.id);
      userId = user['id'];
      print('  le vrai ID: ${Supabase.instance.client.auth.currentUser!.id}');

      await BookingService().createBooking(
        selectedSpaceId!,
        userId,
        startDateTime,
        endDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Réservation créée avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // L'erreur est déjà formatée par BookingService._formatErrorMessage
        String errorMessage = e.toString().replaceAll('Exception: ', '');

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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitles[_currentPage]),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Contenu des pages
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                // Charger les créneaux occupés quand on arrive sur la page de sélection d'heure
                if (index == 2) {
                  _loadOccupiedSlots();
                }
              },
              children: [
                _buildSpaceSelectionPage(),
                _buildDateSelectionPage(),
                _buildTimeSelectionPage(),
                _buildConfirmationPage(),
              ],
            ),
          ),

          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canGoNext()
                        ? (_currentPage == 3 ? _createBooking : _nextPage)
                        : null,
                    child: Text(_currentPage == 3 ? 'Confirmer' : 'Suivant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceSelectionPage() {
    final spaces = [
      {'id': '1', 'name': 'Cuisine', 'icon': Icons.kitchen},
      {'id': '5', 'name': 'Salon', 'icon': Icons.living},
      {'id': '2', 'name': 'Salle de sport', 'icon': Icons.fitness_center},
      {'id': '4', 'name': 'Terrasse', 'icon': Icons.balcony},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quel espace souhaitez-vous réserver ?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                final space = spaces[index];
                final isSelected = selectedSpaceId == space['id'];

                return Card(
                  elevation: isSelected ? 8 : 2,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedSpaceId = space['id'] as String;
                        selectedSpaceName = space['name'] as String;
                        // Reset les données de temps si on change d'espace
                        occupiedSlots.clear();
                        suggestedSlots.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            space['icon'] as IconData,
                            size: 48,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            space['name'] as String,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Theme.of(context).primaryColor : null,
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
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez une date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: CalendarDatePicker(
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                    // Reset les données de temps si on change de date
                    occupiedSlots.clear();
                    suggestedSlots.clear();
                    startTime = null;
                    endTime = null;
                    conflictError = null;
                  });
                },
              ),
            ),
          ),
          if (selectedDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Date sélectionnée: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez les heures',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Afficher les créneaux occupés s'il y en a
          if (occupiedSlots.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Créneaux déjà réservés :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: occupiedSlots.map((slot) {
                      final start = DateTime.parse(slot['start_date']);
                      final end = DateTime.parse(slot['end_date']);
                      return Chip(
                        label: Text(
                          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                        ),
                        backgroundColor: Colors.red.shade100,
                        side: BorderSide(color: Colors.red.shade300),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Suggestions de créneaux libres
          if (suggestedSlots.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Créneaux libres suggérés :',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: suggestedSlots.map((slot) {
                      return ActionChip(
                        label: Text('${slot['start']} - ${slot['end']}'),
                        backgroundColor: Colors.green.shade100,
                        side: BorderSide(color: Colors.green.shade300),
                        onPressed: () {
                          final startParts = slot['start']!.split(':');
                          final endParts = slot['end']!.split(':');
                          setState(() {
                            startTime = TimeOfDay(
                              hour: int.parse(startParts[0]),
                              minute: int.parse(startParts[1]),
                            );
                            endTime = TimeOfDay(
                              hour: int.parse(endParts[0]),
                              minute: int.parse(endParts[1]),
                            );
                          });
                          _checkTimeConflicts();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Heure de début
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Heure de début'),
              subtitle: Text(
                startTime != null
                    ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                    : 'Cliquez pour choisir',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: startTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    startTime = time;
                  });
                  _checkTimeConflicts();
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Heure de fin
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time_filled),
              title: const Text('Heure de fin'),
              subtitle: Text(
                endTime != null
                    ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                    : 'Cliquez pour choisir',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: endTime ?? (startTime?.replacing(hour: startTime!.hour + 1) ?? TimeOfDay.now()),
                );
                if (time != null) {
                  setState(() {
                    endTime = time;
                  });
                  _checkTimeConflicts();
                }
              },
            ),
          ),

          // Affichage de l'erreur de conflit
          if (conflictError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      conflictError!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Indicateur de vérification en cours
          if (isCheckingConflicts) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vérification de la disponibilité...',
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ],
              ),
            ),
          ],

          // Affichage de la durée si pas d'erreur
          if (startTime != null && endTime != null && conflictError == null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Durée: ${_calculateDuration()} heures',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmez votre réservation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfirmationRow(Icons.place, 'Espace', selectedSpaceName ?? ''),
                  const SizedBox(height: 12),
                  _buildConfirmationRow(
                      Icons.calendar_today,
                      'Date',
                      selectedDate != null
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : ''
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmationRow(
                      Icons.access_time,
                      'Heure de début',
                      startTime != null
                          ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                          : ''
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmationRow(
                      Icons.access_time_filled,
                      'Heure de fin',
                      endTime != null
                          ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                          : ''
                  ),
                  const SizedBox(height: 12),
                  _buildConfirmationRow(Icons.schedule, 'Durée', '${_calculateDuration()} heures'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Votre réservation sera confirmée immédiatement. Vous pourrez la consulter dans la liste de vos réservations.',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateDuration() {
    if (startTime == null || endTime == null) return '0';

    final start = Duration(hours: startTime!.hour, minutes: startTime!.minute);
    final end = Duration(hours: endTime!.hour, minutes: endTime!.minute);

    Duration duration = end - start;
    if (duration.isNegative) {
      duration = Duration(hours: 24) + duration;
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (minutes == 0) {
      return hours.toString();
    } else {
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
  }
}