// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'activity_details_page.dart';

class ActivitiesFeed extends StatefulWidget {
  const ActivitiesFeed({super.key});

  @override
  State<ActivitiesFeed> createState() => _ActivitiesFeedState();
}

class _ActivitiesFeedState extends State<ActivitiesFeed> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> activities = [];

  static const Color tileWhite = Colors.white;
  static const Color titleBlack = Color(0xFF101316);
  static const Color mutedGrey = Color(0xFF7A8A9A);
  static const Color accentBlue = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    try {
      final data = await supabase
          .from('activities')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        activities = (data as List).cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading activities: $e");
      setState(() => isLoading = false);
    }
  }

  // 🧩 WHITE TILE CARD DESIGN
  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final title = activity['title'] ?? "Untitled Activity";
    final description = activity['description'] ?? "";
    final location = activity['location'] ?? "Unknown";
    final imageUrl = activity['image_url'] ?? "";
    final createdAt = DateTime.tryParse(activity['created_at'] ?? '');
    final formattedDate =
        createdAt != null ? DateFormat.yMMMd().format(createdAt) : "Date N/A";

    return Container(
      width: 200, // 👈 smaller
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailsPage(activity: activity),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Smaller Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 110, // 👈 smaller
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 110,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_outlined,
                          size: 34, color: Colors.white70),
                    ),
            ),

            // 📄 Compact details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14, // 👈 smaller
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101316),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFF1E88E5)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF7A8A9A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description.isEmpty ? "No description" : description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.3,
                      color: const Color(0xFF7A8A9A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF7A8A9A),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActivityDetailsPage(activity: activity),
                            ),
                          );
                        },
                        child: Text(
                          "View",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF1E88E5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentBlue),
      );
    }

    if (activities.isEmpty) {
      return const Center(
        child: Text("No activities found."),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: activities.length,
      itemBuilder: (context, i) => _buildActivityTile(activities[i]),
    );
  }
}
