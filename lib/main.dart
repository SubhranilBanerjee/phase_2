import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_slideshow_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'chat_page.dart';
import 'auth_gate.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'favorites_page.dart';
import 'bookings_page.dart';
import 'profile_page.dart';
import 'posts_page.dart';
import 'posts_page.dart';
import 'map_page.dart';

import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ehhzpedqvwvqwaauubit.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVoaHpwZWRxdnd2cXdhYXV1Yml0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4MjU4ODIsImV4cCI6MjA3MzQwMTg4Mn0.QLQu3W4wy0Bc08GaXa8D6yhGa8heIZsaFbmKNRhQXhk',
  );

  runApp(const TourGuideApp());
}

class TourGuideApp extends StatelessWidget {
  const TourGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // your base mobile design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          home: child,
        );
      },
      child: const SplashSlideshowPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    PostsPage(),
    FavoritesPage(),
    BookingsPage(),
    const ProfilePage(),
    MapPage(),
  ];

  void _onTabTapped(int index) async {
    // Profile tab check
    if (index == 5) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );

        final userAfter = Supabase.instance.client.auth.currentUser;
        if (userAfter != null && mounted) {
          setState(() => _currentIndex = 5);
        }
      } else {
        setState(() => _currentIndex = 5);
      }
      return;
    }

    // Chats tab → open separately instead of direct page

    // Regular navigation
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 👈 allows content to show behind the bar
      body: _pages[_currentIndex],

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 35), // 👈 lifts it up
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                selectedItemColor: Colors.black,
                unselectedItemColor: Colors.black.withOpacity(0.65),
                selectedIconTheme: const IconThemeData(size: 34),
                unselectedIconTheme: const IconThemeData(size: 28),
                showUnselectedLabels: false,
                onTap: _onTabTapped,
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded), label: "Explore"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.explore_rounded), label: "Activities"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.post_add_rounded), label: "Tours"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.favorite_border_rounded),
                      label: "Favorites"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.book_rounded), label: "Bookings"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded), label: "Profile"),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.map_rounded), label: "Map"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
