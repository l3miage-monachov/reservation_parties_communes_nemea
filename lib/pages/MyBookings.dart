import 'package:flutter/material.dart';
import 'package:reservation_parties_communes_nemea/services/BookingService.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class MyBookings extends StatefulWidget {
  const MyBookings({super.key});

  @override
  State<MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<MyBookings> {
  final bookings = BookingService().getBookingsForUser(Supabase.instance.client.auth.currentUser!.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: ListView(
        children: [
          FutureBuilder(
            future: bookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final bookingList = (snapshot.data as List?) ?? [];
              if (bookingList.isEmpty) {
                return const Center(child: Text('No bookings found.'));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookingList.length,
                itemBuilder: (context, index) {
                  final booking = bookingList[index];
                  return ListTile(
                    title: Text(booking['space_id']),
                    subtitle: Text('${booking['start_time']} - ${booking['end_time']}'),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}