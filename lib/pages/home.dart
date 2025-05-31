import 'package:flutter/material.dart';

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
          ? AppBar(title: const Text('Home'))
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
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.calendar_today)),
            label: 'my bookings',
          ),
          NavigationDestination(
            icon: Badge(label: Text('2'), child: Icon(Icons.person)),
            label: 'Profile',
          ),
        ],
      ),

      body:
      <Widget>[
        /// Home page
        Card(
          shadowColor: Colors.transparent,
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(child: Center(child: Text('Home page'))),
        ),

        // My bookings page
        const RegisterPage(),

        // call the ProfilePage.dart class
        const ProfilePage()

      ][currentPageIndex],
    );
  }


}