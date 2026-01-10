import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsGraphPage extends StatefulWidget {
  final int id; // post or activity id
  final String type; // "post" or "activity"

  const AnalyticsGraphPage({super.key, required this.id, required this.type});

  @override
  State<AnalyticsGraphPage> createState() => _AnalyticsGraphPageState();
}

class _AnalyticsGraphPageState extends State<AnalyticsGraphPage> {
  final supabase = Supabase.instance.client;

  int totalBookings = 0;
  int paidBookings = 0;
  int pendingBookings = 0;
  int cancelledBookings = 0;
  int favourites = 0;

  int totalUsers = 0; // visibility
  int engagementBookings = 0;
  int engagementFavs = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    try {
      /// --------------------------------------------
      /// 1. Choose the correct BOOKINGS TABLE
      /// --------------------------------------------
      final bookingsTable =
          widget.type == "post" ? "bookings" : "bookings_acts";

      final idColumn = widget.type == "post" ? "post_id" : "activity_id";

      /// --------------------------------------------
      /// 2. BOOKINGS QUERY (dynamic table)
      /// --------------------------------------------
      final bookingRaw = await supabase
          .from(bookingsTable)
          .select('status')
          .eq(idColumn, widget.id);

      final bookingData =
          List<Map<String, dynamic>>.from(bookingRaw as List<dynamic>);

      /// --------------------------------------------
      /// 3. FAVOURITES QUERY (same table)
      /// --------------------------------------------
      final favRaw = await supabase
          .from('favorites')
          .select('id')
          .eq('item_type', widget.type)
          .eq('item_id', widget.id);

      final favData = List<Map<String, dynamic>>.from(favRaw as List<dynamic>);

      /// --------------------------------------------
      /// 4. TOTAL USERS (from profiles)
      /// --------------------------------------------
      final userRaw = await supabase.from('profiles').select('id');
      final userData =
          List<Map<String, dynamic>>.from(userRaw as List<dynamic>);

      /// --------------------------------------------
      /// 5. PROCESS BOOKINGS
      /// --------------------------------------------
      int t = bookingData.length;
      int paid = 0, pending = 0, cancelled = 0;

      for (final b in bookingData) {
        final status = b['status'];
        if (status == 'paid')
          paid++;
        else if (status == 'pending')
          pending++;
        else if (status == 'cancelled') cancelled++;
      }

      if (!mounted) return;

      setState(() {
        totalBookings = t;
        paidBookings = paid;
        pendingBookings = pending;
        cancelledBookings = cancelled;
        favourites = favData.length;

        totalUsers = userData.length;
        engagementBookings = t;
        engagementFavs = favData.length;

        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Widget statCard(String title, int value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.type == "post" ? "Post Analytics" : "Activity Analytics"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  statCard("Total Users (Visibility)", totalUsers,
                      Icons.people_alt, Colors.indigo),
                  statCard("Total Bookings", totalBookings,
                      Icons.event_available, Colors.blue),
                  statCard("Paid Bookings", paidBookings, Icons.check_circle,
                      Colors.green),
                  statCard("Pending Payments", pendingBookings,
                      Icons.hourglass_bottom, Colors.orange),
                  statCard("Cancellations", cancelledBookings, Icons.cancel,
                      Colors.red),
                  statCard(
                      "Favourites", favourites, Icons.favorite, Colors.pink),
                  const SizedBox(height: 25),
                  const Text("ENGAGEMENT",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  statCard("Bookings (Engagement)", engagementBookings,
                      Icons.book_online, Colors.deepPurple),
                  statCard("Favourites (Engagement)", engagementFavs,
                      Icons.favorite_border, Colors.teal),
                ],
              ),
            ),
    );
  }
}
