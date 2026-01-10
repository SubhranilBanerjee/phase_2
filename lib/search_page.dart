import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tour_guide/activity_feed.dart';
import 'activity_details_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final supabase = Supabase.instance.client;
  String selectedSort = 'Newest';

  final List<String> categories = [
    'adventure',
    'food and drinks',
    'recreation',
    'fun and games',
    'educational',
    'services',
    'misc',
  ];

  String? selectedCategory; // store selected category

  // Form controllers
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final searchController = TextEditingController();

  // Image handling
  File? _fileImage;
  Uint8List? _webImage;

  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> filteredActivities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadActivities();
    searchController.addListener(_filterActivities);
  }

// Check if a specific activity is favourited by current user
  Future<bool> isFavourite(String activityId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    // Supabase RLS policies must allow SELECT on 'favourites_acts'
    final data = await supabase
        .from('favourites_acts')
        .select()
        .eq('user_id', user.id)
        .eq('activity_id', activityId);

    return data.isNotEmpty;
  }

// Toggle favourite (add or remove)
  Future<void> toggleFavourite(String activityId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("⚠️ Please log in to manage favourites")),
        );
      }
      return;
    }

    // Optimistic UI update is generally preferred for instant feel,
    // but for simplicity, we'll refresh the state on success.

    // Check current state (we can use the isFavourite check again)
    final favData = await supabase
        .from('favourites_acts')
        .select()
        .eq('user_id', user.id)
        .eq('activity_id', activityId);

    bool isCurrentlyFavourited = favData.isNotEmpty;

    try {
      if (isCurrentlyFavourited) {
        // Already favourited → remove
        await supabase
            .from('favourites_acts')
            .delete()
            .eq('user_id', user.id)
            .eq('activity_id', activityId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("💔 Removed from Favourites")),
          );
        }
      } else {
        // Not favourited → add
        await supabase.from('favourites_acts').insert({
          'user_id': user.id,
          'activity_id': activityId,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❤️ Added to Favourites")),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error toggling favourite: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "❌ Failed to ${isCurrentlyFavourited ? 'remove' : 'add'} favourite."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Refresh the UI to reflect the change for this card
    setState(() {});
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    locationController.dispose();
    priceController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Pick image (unchanged)
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _fileImage = File(picked.path));
      }
    }
  }

  // Upload image (unchanged)
  Future<String?> uploadImage() async {
    // 👇 Replace these with your own Cloudinary credentials
    String cloudName = "dledkzh8h";
    String uploadPreset = "flutter_profile_upload";

    try {
      if (_fileImage == null && _webImage == null) {
        if (kDebugMode) {
          print("⚠️ No image selected");
        }
        return null;
      }

      // Cloudinary upload URL
      final uri =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      // Build the request
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset;

      // Attach file data
      if (kIsWeb && _webImage != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _webImage!,
          filename: 'activity_image.jpg',
        ));
      } else if (_fileImage != null) {
        request.files
            .add(await http.MultipartFile.fromPath('file', _fileImage!.path));
      }

      // Send request
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(resBody);
        if (kDebugMode) {
          print("✅ Cloudinary upload success: ${data['secure_url']}");
        }
        return data['secure_url']; // <-- Use this as your image URL
      } else {
        if (kDebugMode) {
          print("❌ Cloudinary upload failed: ${response.statusCode}");
          print("Response: $resBody");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error uploading image to Cloudinary: $e");
      }
      return null;
    }
  }

  // Load activities from Supabase (unchanged)
  Future<void> loadActivities() async {
    try {
      final data = await supabase
          .from('activities')
          .select('*, profiles(full_name, profile_image_url)')
          .order('created_at', ascending: false);

      setState(() {
        activities = List<Map<String, dynamic>>.from(data as List);
        filteredActivities = List.from(activities);
        isLoading = false;
        _sortActivities(selectedSort); // Apply current sort after loading
      });
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching activities: $e");
      }
    }
  }

  // Filter activities based on search (unchanged)
  /// FILTER ACTIVITIES (Search + Category)
  void _filterActivities() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredActivities = activities.where((activity) {
        final title = (activity['title'] ?? '').toLowerCase();
        final desc = (activity['description'] ?? '').toLowerCase();
        final location = (activity['location'] ?? '').toLowerCase();

        // SEARCH FILTER
        final matchesSearch = title.contains(query) ||
            desc.contains(query) ||
            location.contains(query);

        // CATEGORY FILTER
        final activityCategory = (activity['category'] ?? '').toLowerCase();
        final matchesCategory = selectedCategory == null ||
            selectedCategory!.toLowerCase() == 'all' ||
            activityCategory == selectedCategory!.toLowerCase();

        return matchesSearch && matchesCategory;
      }).toList();

      // After filtering, apply sorting to the results
      _sortActivities(selectedSort, shouldSetState: false);
    });
  }

  // Create new activity (unchanged)
  // --- UPDATED createActivity ---
// NOTE: Return bool to indicate success (true) or failure (false).
  Future<bool> createActivity() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Title is required")),
        );
      }
      return false;
    }

    try {
      final imageUrl = await uploadImage();

      await supabase.from('activities').insert({
        'user_id': user.id,
        'title': title,
        'description': descController.text.trim(),
        'location': locationController.text.trim(),
        'price': priceController.text.isEmpty
            ? null
            : double.tryParse(priceController.text),
        'image_url': imageUrl,
        'category': selectedCategory,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Clear form and refresh list on success
      clearForm();
      await loadActivities(); // RAGG;
      //Liner_Form
      //data_type: Dyanamic
      //data_type: Static
      //data.sort()
      //data.display()
      //data.print(), data.no_shelf()
      //import java.lang.Util.*
      //import java.util.Scanner()
      //import java.lang
      //import java.BufferedReader()
      //import java.kotlin

      // Show success snack (you said createActivity already shows success; keep it)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Activity created successfully")),
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error creating activity: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Failed to create activity")),
        );
      }
      return false;
    }
  }

  // Delete activity (unchanged)
  Future<void> deleteActivity(String activityId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('activities')
          .delete()
          .eq('id', activityId)
          .eq('user_id', user.id);

      setState(() {
        activities.removeWhere((a) => a['id'].toString() == activityId);
        filteredActivities.removeWhere((a) => a['id'].toString() == activityId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Activity deleted successfully")),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error deleting activity: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Failed to delete activity")),
        );
      }
    }
  }

  // Sort activities (unchanged)
  void _sortActivities(String sortType, {bool shouldSetState = true}) {
    if (shouldSetState) {
      setState(() {
        selectedSort = sortType;
      });
    } else {
      selectedSort = sortType;
    }

    // Sort the filtered list, not the main activities list
    // Filter activities based on search AND category
    void _filterActivities() {
      final query = searchController.text.toLowerCase();

      // Clear selected category if the user starts typing a search query,
      // or handle both simultaneously. We'll handle both simultaneously for flexibility.

      setState(() {
        filteredActivities = activities.where((activity) {
          final title = (activity['title'] ?? '').toLowerCase();
          final desc = (activity['description'] ?? '').toLowerCase();
          final location = (activity['location'] ?? '').toLowerCase();

          // --- Search Filter Check ---
          final matchesSearch = title.contains(query) ||
              desc.contains(query) ||
              location.contains(query);

          // --- Category Filter Check ---
          // If selectedCategory is null or 'All', this check is true (no filter applied)
          // Otherwise, it checks if the activity's category matches the selected one.
          final activityCategory = (activity['category'] ?? '').toLowerCase();
          final matchesCategory = selectedCategory == null ||
              selectedCategory!.toLowerCase() == 'all' ||
              activityCategory == selectedCategory!.toLowerCase();

          // Only include the activity if it passes BOTH filters
          return matchesSearch && matchesCategory;
        }).toList();

        // Re-sort the newly filtered list
        _sortActivities(selectedSort, shouldSetState: false);
      });
    }

    ;

    if (shouldSetState) {
      setState(() {});
    }
  }

  // Reset form (unchanged)
  void clearForm() {
    titleController.clear();
    descController.clear();
    locationController.clear();
    priceController.clear();
    setState(() {
      _fileImage = null;
      _webImage = null;
    });
  }

  // Bottom sheet for creating activity (unchanged)
  // --- UPDATED centered dialog: _openCreateActivitySheet ---
  void _openCreateActivitySheet() {
    // Reset any previous modal-only error state
    String? titleError;
    bool isCreating = false;

    // Ensure category is initialised (keeps class-level selectedCategory)
    // Do NOT clear selectedCategory here so user choice persists across opens if desired.
    // (You stated selectedCategory is a State variable and you want clearing after success.)

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          Future<void> pickImageModal() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(source: ImageSource.gallery);

            if (picked != null) {
              if (kIsWeb) {
                final bytes = await picked.readAsBytes();
                setModalState(() => _webImage = bytes);
                setState(() => _webImage = bytes);
              } else {
                setModalState(() => _fileImage = File(picked.path));
                setState(() => _fileImage = File(picked.path));
              }
            }
          }

          // Local helper for Add button press
          Future<void> onAddPressed() async {
            // Validate title locally and show inline error
            final title = titleController.text.trim();
            if (title.isEmpty) {
              setModalState(() => titleError = "Title is required");
              return;
            } else {
              if (titleError != null) setModalState(() => titleError = null);
            }

            // Start loading
            setModalState(() => isCreating = true);

            // Call createActivity (await its boolean result)
            bool success = await createActivity();

            // Stop loading
            if (mounted) setModalState(() => isCreating = false);

            if (success) {
              // Clear the selectedCategory state (you asked to clear form after success)
              if (mounted) setState(() => selectedCategory = null);

              // Close dialog immediately (you asked for immediate close)
              if (mounted) Navigator.of(context).pop();
              // createActivity already showed success snackbar per your setup
            } else {
              // keep dialog open (createActivity already showed failure snackbar)
              // Optionally, you could highlight fields here if desired
            }
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: EdgeInsets.zero,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sky-blue header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade400,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.explore, color: Colors.white, size: 26),
                        SizedBox(width: 10),
                        Text(
                          "Create Activity",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Form body
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Title
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: "Title *",
                            border: const OutlineInputBorder(),
                            errorText: titleError,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(
                              labelText: "Description",
                              border: OutlineInputBorder()),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),

                        // Location + Price row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: locationController,
                                decoration: const InputDecoration(
                                    labelText: "Location",
                                    border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: priceController,
                                decoration: const InputDecoration(
                                    labelText: "Price",
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Category dropdown (hardcoded list)
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: "Category",
                            border: OutlineInputBorder(),
                          ),
                          items: categories
                              .map((cat) => DropdownMenuItem(
                                  value: cat, child: Text(cat)))
                              .toList(),
                          onChanged: (value) {
                            // update both modal and page state so selection persists where appropriate
                            setModalState(() => selectedCategory = value);
                            setState(() => selectedCategory = value);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Image preview (if any)
                        if (_webImage != null || _fileImage != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb && _webImage != null
                                ? Image.memory(_webImage!,
                                    height: 150, fit: BoxFit.cover)
                                : Image.file(_fileImage!,
                                    height: 150, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Pick Image button
                        TextButton.icon(
                          onPressed: pickImageModal,
                          icon:
                              const Icon(Icons.image, color: Colors.lightBlue),
                          label: Text(
                            _webImage != null || _fileImage != null
                                ? "Change Image"
                                : "Pick Image",
                            style: const TextStyle(color: Colors.lightBlue),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Add Activity button (replaces text with spinner while creating)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isCreating ? null : onAddPressed,
                            icon: isCreating
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: isCreating
                                ? const Text("Creating...")
                                : const Text("Add Activity"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // --- Helper: get average rating from reviews_acts ---
  Future<double> getActivityRating(String activityId) async {
    try {
      final response = await supabase
          .from('reviews_acts')
          .select('rating')
          .eq('activity_id', activityId);

      if (response == null || (response is List && response.isEmpty)) {
        return 0.0;
      }

      double total = 0;
      int count = 0;
      for (var r in response as List) {
        if (r == null) continue;
        final val = (r['rating'] ?? 0);
        if (val is num) {
          total += val.toDouble();
          count++;
        }
      }
      if (count == 0) return 0.0;
      return total / count;
    } catch (e) {
      if (kDebugMode) print("Error fetching rating for $activityId -> $e");
      return 0.0;
    }
  }

// --- Pastel color map for Title Case categories ---
  Color _categoryColor(String rawCategory) {
    final c = (rawCategory ?? '').toString().trim().toLowerCase();
    switch (c) {
      case 'adventure':
        return const Color(0xFFB3E5FC); // pastel blue
      case 'food and drinks':
        return const Color(0xFFFFF3BF); // pastel yellow
      case 'recreation':
        return const Color(0xFFD7FFD9); // pastel green
      case 'fun and games':
        return const Color(0xFFE7D7FF); // pastel purple
      case 'educational':
        return const Color(0xFFFFE0CC); // pastel peach
      case 'services':
        return const Color(0xFFDCE7FF); // pastel light blue
      case 'misc':
      case 'misc.':
        return const Color(0xFFF5F5F5); // pastel gray
      default:
        return const Color(0xFFF0F0F0);
    }
  }

// --- Helper to build star icons row ---
  Widget _buildStarRow(double rating) {
    // rating 0.0..5.0
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (i <= rating.floor()) {
        stars.add(const Icon(Icons.star,
            size: 16, color: Color(0xFFFFC857))); // amber
      } else if (i - rating <= 0.5) {
        stars.add(
            const Icon(Icons.star_half, size: 16, color: Color(0xFFFFC857)));
      } else {
        stars.add(
            const Icon(Icons.star_border, size: 16, color: Color(0xFFFFC857)));
      }
    }
    return Row(children: stars);
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final activityId = activity['id']?.toString() ?? '';
    final title = (activity['title'] ?? 'Untitled Activity').toString();
    final desc = (activity['description'] ?? '').toString();
    final location = (activity['location'] ?? 'World').toString();
    final price = (activity['price'] ?? '₹1').toString();
    final imageUrl = activity['image_url']?.toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsPage(activity: activity),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image at top with rounded edges
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 120,
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image, color: Colors.white70),
                    ),
            ),

            // 📄 Info Panel
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐ Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 📝 Description
                  Text(
                    desc.isEmpty
                        ? "Discover breathtaking destinations, hidden gems, and unforgettable experiences curated just for you."
                        : desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 📍 Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(location.isEmpty ? "World" : location,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 📅 Date placeholder
                  Row(
                    children: const [
                      Icon(Icons.calendar_month,
                          size: 18, color: Colors.black54),
                      SizedBox(width: 6),
                      Text("N/A - N/A", style: TextStyle(fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ⏰ Time placeholder
                  Row(
                    children: const [
                      Icon(Icons.access_time, size: 18, color: Colors.black54),
                      SizedBox(width: 6),
                      Text("Start Time: N/A", style: TextStyle(fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 💰 Price
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee,
                          size: 18, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ❤️ Fav + Book button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ❤️ Favourite
                      FutureBuilder<bool>(
                        future: isFavourite(activityId),
                        builder: (context, snapshot) {
                          final isFav = snapshot.data ?? false;
                          return GestureDetector(
                            onTap: () => toggleFavourite(activityId),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 22,
                            ),
                          );
                        },
                      ),

                      // 🟦 Book Now Button
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String activityId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Activity"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('activities').delete().eq('id', activityId);
        setState(() {
          activities.removeWhere((a) => a['id'].toString() == activityId);
          filteredActivities
              .removeWhere((a) => a['id'].toString() == activityId);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to delete: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String aestheticFont = 'Montserrat';
    final double topPadding = MediaQuery.of(context).padding.top;

    final List<String> categories = [
      'All',
      'adventure',
      'food and drinks',
      'recreation',
      'fun and games',
      'educational',
      'services',
      'misc',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFDEDDC4), // Softer background

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 HEADER — Title + Count Badge
          // 🌄 HERO SECTION — Background Image + Glassmorphic Search Bar
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                // 🖼️ Background Image
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/hero_static.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
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
                ),

                // 🧊 GLASSMORPHIC SEARCH BAR — now at the TOP on the image
                Positioned(
                  top: topPadding + 10,
                  left: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) => _filterActivities(),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Search activities...",
                            hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.85)),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.white),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.white70),
                                    onPressed: () {
                                      searchController.clear();
                                      _filterActivities();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ✨ Title + Subtitle (now below search bar but still on image)
                Positioned(
                  bottom: 18,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        "Explore Activities",
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          fontFamily: GoogleFonts.waterfall().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Discover what’s happening around you",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          letterSpacing: 0.6,
                          fontFamily: GoogleFonts.inter().fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),

                      // 🧊 Glassmorphic border
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                        width: 1.4,
                      ),

                      // subtle translucent fill
                      color: Colors.white.withOpacity(0.20),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _openCreateActivitySheet,
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: const Text(
                        "Create New Activity",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.transparent, // keep glass visible
                        foregroundColor: Colors.black87,
                        elevation: 0, // no material shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 📜 ACTIVITIES LIST — Smooth Scroll
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
                : RefreshIndicator(
                    onRefresh: loadActivities,
                    color: const Color(0xFF1E88E5),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: filteredActivities.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 30),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sentiment_dissatisfied,
                                        size: 45, color: Colors.grey.shade500),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "No activities match your search.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredActivities.length,
                              itemBuilder: (context, index) => AnimatedOpacity(
                                opacity: 1,
                                duration: const Duration(milliseconds: 500),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _buildActivityCard(
                                      filteredActivities[index]),
                                ),
                              ),
                            ),
                    ),
                  ),
          ),
        ],
      ),

      // ➕ Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateActivitySheet,
        backgroundColor: Colors.blueAccent,
        elevation: 6,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      floatingActionButtonLocation: TopCenterFabLocation(),
    );
  }
}

//garbage value protection
class TopCenterFabLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry g) {
    const double margin = 16.0;

    final double topInset = g.minInsets.top;

    return Offset(
      // Right aligned
      g.scaffoldSize.width - g.floatingActionButtonSize!.width - margin,

      // Below status bar
      topInset + margin,
    );
  }
}
