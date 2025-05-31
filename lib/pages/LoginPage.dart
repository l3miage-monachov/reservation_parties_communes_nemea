// import material.dart
import 'package:flutter/material.dart';

import '../services/AuthService.dart';
import 'RegisterPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{

  //get auth service
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  //login button pressed
  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    //attempt to sign in
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      if(mounted){
        //handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          ElevatedButton(
            onPressed: login,
            child: const Text('Login'),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
            child: Center(child: Text("don't have an account? Sign up"))),
        ],
      )
    );
  }
}