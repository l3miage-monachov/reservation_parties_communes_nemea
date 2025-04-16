import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/pages/Booking.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Booking(),
    );
  }
}

