import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/pages/Booking.dart';
import 'package:reservation_parties_communes_nemea/services/AuthGate.dart';
import 'package:reservation_parties_communes_nemea/services/SpaceService.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://llcwasknqhliexewsmzb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsY3dhc2tucWhsaWV4ZXdzbXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ5ODYwMzMsImV4cCI6MjA2MDU2MjAzM30.R-YRydVBHTzDOoDyh7ZFjDoIjFMMdx4PVrQdeEpzjyE',
  );

  print('Fetching space details for id 1...');
  SpaceService().getSpaceDetails(1).then((value) {
    if (value == null) {
      print('Warning: Received null response. Check query criteria and Supabase table entries.');
    } else {
      print('Space details: $value');
    }
  }).catchError((error) {
    print('Error fetching space details: $error');
  });

  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: AuthGate(),
    );
  }
}

