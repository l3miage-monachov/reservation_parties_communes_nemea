import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/pages/RegisterPage.dart';
import 'package:reservation_parties_communes_nemea/services/AuthService.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  void logout() async {
    _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = _authService.getUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
    );
  }
}
