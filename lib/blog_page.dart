import 'package:flutter/material.dart';

class BlogPagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Blog'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Text(
                    'Blog Image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Blog title
            Text(
              'Welcome to My Blog!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),

            // Author & date info
            Text(
              'By Flutter Dev • November 25, 2025',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),

            // Blog content placeholder
            Text(
              'This is a placeholder for your blog post content. '
              'Replace this text with your article, stories, tutorials, or updates. '
              'Flutter makes it easy to build beautiful, responsive UIs for any platform!',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 30),

            // Optional: Tags or categories
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Flutter')),
                Chip(label: Text('Mobile Dev')),
                Chip(label: Text('UI/UX')),
              ],
            ),
            SizedBox(height: 40),

            // Call-to-action or comment prompt
            Text(
              'What do you think? Leave a comment below!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
