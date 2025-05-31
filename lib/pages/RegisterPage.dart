import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/pages/LoginPage.dart';
import 'package:reservation_parties_communes_nemea/services/AuthService.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  //sign up button pressed
  void signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if(password != confirmPassword){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords do not match"),
          ),
        );
      }
      return;
    }
    //attempt to sign up
    try {
      await _authService.signUpWithEmailAndPassword(email, password);

      Navigator.pop(context);
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
          title: const Text("Sign up"),
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
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            ElevatedButton(
              onPressed: signUp,
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 12),
            GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                child: Center(child: Text("you already have an account? Login"))),
          ],
        )
    );
  }
}
