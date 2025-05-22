/*
 */

import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import '../pages/LoginPage.dart';
import '../pages/ProfilePage.dart';

class AuthGate extends StatelessWidget{
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          // loading state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // check if there is a valid session
        final session = snapshot.hasData ? snapshot.data!.session : null;
        if( session != null){
          return const ProfilePage();
        }else{
          return const LoginPage();
        }
      },
     
    );
  }

}