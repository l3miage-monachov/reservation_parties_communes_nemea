import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/pages/AddBookingPage.dart';
import 'package:reservation_parties_communes_nemea/pages/MyBookings.dart';
import 'package:reservation_parties_communes_nemea/pages/HomePage.dart'; // Nouvelle import

import 'ProfilePage.dart';
import 'RegisterPage.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: currentPageIndex == 0
          ? AppBar(
        title: const Text('Accueil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).primaryColor,
      )
          : null,

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.calendar_month),
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Mes réservations',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),

      body: <Widget>[
        /// Home page - Nouvelle page d'accueil
        const HomePage(),

        /// My bookings page
        const MyBookings(),

        /// Profile page
        const ProfilePage()
      ][currentPageIndex],

      // FAB pour créer une réservation rapidement
      floatingActionButton: currentPageIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBookingPage(),
            ),
          );
        },
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}