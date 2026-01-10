import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_details_page.dart';
import 'package:intl/intl.dart';

class PostsFeed extends StatefulWidget {
  const PostsFeed({super.key});

  @override
  State<PostsFeed> createState() => _PostsFeedState();
}

class _PostsFeedState extends State<PostsFeed> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    try {
      final data = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        posts = List<Map<String, dynamic>>.from(data as List);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading posts: $e");
      setState(() => isLoading = false);
    }
  }

  // 🧱 WHITE TILE CARD
  Widget _buildPostTile(Map<String, dynamic> post) {
    final title = post['title'] ?? "Untitled";
    final description = post['description'] ?? "";
    final price = post['price']?.toString() ?? "N/A";
    final imageUrl = post['image_url'] ?? "";

    final createdAt = DateTime.tryParse(post['created_at'] ?? '');
    final date =
        createdAt != null ? DateFormat.yMMMd().format(createdAt) : "Date N/A";

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailsPage(post: post),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 IMAGE AT TOP
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 110,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_outlined,
                          size: 36, color: Colors.white70),
                    ),
            ),

            // 📄 DETAILS BELOW IMAGE
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷 TITLE
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101316),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 📝 DESCRIPTION
                  Text(
                    description.isEmpty ? "No description" : description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A8A9A),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 💸 PRICE + DATE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹ $price",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7A8A9A),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return const Center(child: Text("No posts available"));
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: posts.length,
        itemBuilder: (context, i) => _buildPostTile(posts[i]),
      ),
    );
  }
}
