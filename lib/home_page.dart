// home_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/cupertino.dart';
import 'activity_details_page.dart';
import 'post_details_page.dart';
import 'search_page.dart';
import 'posts_page.dart';
import 'notifications_page.dart';
import 'kolkata_destinations.dart';
import 'posts_feed.dart';
import 'activity_feed.dart';
import 'global_search_live_page.dart';
import 'paris_page.dart';
import 'dubai_page.dart';
import 'newyork_page.dart';
import 'rio_page.dart';
import 'bali_page.dart';
import 'ads_feed.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  String? fullName;
  String? locationName;
  String? profileImageUrl;

  int _currentIndex = 0;
  late final List<String> _slideshowImages;
  late final List<String> _captions;
  late final Timer _timer;

  bool boostedLoading = true;
  String? boostedError;
  List<Map<String, dynamic>> boostedItems = [];

  @override
  void initState() {
    super.initState();
    _initData();

    _slideshowImages = [
      'assets/sea.jpg',
      'assets/mountain1.jpg',
      'assets/mountain.jpg',
      'assets/Victoria-Memorial.jpg',
      'assets/Pareshnath-Jain-Temple.jpg',
    ];

    _captions = [
      "Find Peace by the Sea",
      "Conquer the Peaks",
      "Breathe in the Mountains",
      "Explore Victoria Memorial",
      "Discover Pareshnath Temple",
    ];

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() =>
            _currentIndex = (_currentIndex + 1) % _slideshowImages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    await _fetchUserName();
    await _fetchLocation();
    await _fetchBoostedItems();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => fullName = "Guest");
        return;
      }
      final data = await supabase
          .from('profiles')
          .select('full_name, profile_image_url')
          .eq('id', user.id)
          .maybeSingle();
      setState(() {
        fullName = data?['full_name'] ?? "Guest";
        profileImageUrl = data?['profile_image_url'];
      });
    } catch (_) {
      setState(() => fullName = "Guest");
    }
  }

  // rens sHotLoader = new sHotLoader(System.in)
  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => locationName = "Location disabled");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => locationName = "Permission denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      final placemark = placemarks.first;
      setState(() {
        locationName =
            "${placemark.locality ?? 'Unknown'}, ${placemark.country ?? ''}";
      });
    } catch (_) {
      setState(() => locationName = null);
    }
  }

  Future<void> _fetchBoostedItems() async {
    setState(() {
      boostedLoading = true;
      boostedError = null;
    });

    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();

      final boostedPostsResp = await supabase
          .from('posts')
          .select()
          .eq('is_boosted', true)
          .gt('boost_end', nowIso)
          .order('boost_end', ascending: false);

      final boostedActsResp = await supabase
          .from('activities')
          .select()
          .eq('is_boosted', true)
          .gt('boost_end', nowIso)
          .order('boost_end', ascending: false);

      final postsList = boostedPostsResp is List
          ? List<Map<String, dynamic>>.from(boostedPostsResp)
          : <Map<String, dynamic>>[];
      final actsList = boostedActsResp is List
          ? List<Map<String, dynamic>>.from(boostedActsResp)
          : <Map<String, dynamic>>[];

      final combined = <Map<String, dynamic>>[];
      for (var p in postsList) {
        final copy = Map<String, dynamic>.from(p);
        copy['__type'] = 'post';
        combined.add(copy);
      }
      for (var a in actsList) {
        final copy = Map<String, dynamic>.from(a);
        copy['__type'] = 'activity';
        combined.add(copy);
      }

      combined.sort((a, b) {
        final aEnd = DateTime.tryParse(a['boost_end']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bEnd = DateTime.tryParse(b['boost_end']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bEnd.compareTo(aEnd);
      });

      setState(() {
        boostedItems = combined;
        boostedLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching boosted items: $e');
      setState(() {
        boostedError = 'Failed to load boosted content';
        boostedLoading = false;
      });
    }
  }

  void _openItem(Map<String, dynamic> item) {
    if (item['__type'] == 'post') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => PostDetailsPage(post: item)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ActivityDetailsPage(activity: item)));
    }
  }

  // Helper: format remaining time text
  String _formatRemaining(String boostEnd) {
    try {
      final end = DateTime.parse(boostEnd).toLocal();
      final diff = end.difference(DateTime.now());
      if (diff.isNegative) return 'Expired';
      if (diff.inDays >= 1) return '${diff.inDays}d left';
      if (diff.inHours >= 1) return '${diff.inHours}h left';
      return '${diff.inMinutes}m left';
    } catch (_) {
      return '';
    }
  }

  // Category actions map - keeps your original navigation intent
  void _onCategoryTap(String key) {
    switch (key) {
      case 'Tours':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const PostsPage()));
        break;
      case 'Activities':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ActivitiesFeed()));
        break;
      case 'Bookings':
        // If you have a bookings page, navigate to it. For now open search.
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SearchPage()));
        break;
      case 'Guides':
        // If you keep GuidesList, import/navigation apply
        // Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidesList()));
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SearchPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffDEDDC4),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 🔹 Top search bar (glass)
              // 🌄 HERO SECTION (Image + Search + Title)
              SizedBox(
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _slideshowImages[_currentIndex],
                      fit: BoxFit.cover,
                    ),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.25),
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),

                    // 🔍 Search bar inside hero
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GlobalSearchLivePage(),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.28),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.45),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  SizedBox(width: 16),
                                  Icon(Icons.search, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "Where to go",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Spacer(),
                                  Icon(Icons.mic_none, color: Colors.white70),
                                  SizedBox(width: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ✨ Title text
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Discover The",
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Unknown",
                              style: GoogleFonts.playfair(
                                color: Colors.white,
                                fontSize: 58,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 44,
                              height: 2,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Profile row  ✅ FIXED BRACKETS HERE
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty
                            ? Image.network(
                                profileImageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Image.asset("assets/default_avatar.png"),
                              )
                            : Image.asset("assets/default_avatar.png"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good Morning,",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Color(0xff000000),
                          ),
                        ),
                        Text(
                          fullName ?? "User",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            //fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Material(
                      shape: const CircleBorder(),
                      color: Colors.white,
                      elevation: 3,
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 🔵 Featured Tours
              Padding(
                padding: EdgeInsets.zero,
                child: Text(
                  "Featured Tours",
                  style: GoogleFonts.waterfall(
                    fontSize: 68,
                    //fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 220, child: PostsFeed()),
              const SizedBox(height: 16),

              // 🟡 Activities in Kolkata
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  "Discover Activities...",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    //fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 230, child: ActivitiesFeed()),
              const SizedBox(height: 18),

              // 🟣 Sponsored / Ads
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  "Sponsored",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    //fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const AdsFeed(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: 78,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff4f8bff),
                  Color(0xff2b6df6),
                ],
              ),
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xff2b3e55),
            ),
          ),
        ],
      ),
    );
  }

  // Section title helper matching screenshot style
  Widget _sectionTitle(String title, {bool showButton = false}) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.waterfall(
                fontSize: 58, fontWeight: FontWeight.w700)),
        const Spacer(),
        if (showButton)
          TextButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SearchPage())),
            child: Text('See All',
                style: GoogleFonts.inter(color: const Color(0xff4b8bff))),
          ),
      ],
    );
  }
}
