import 'package:flutter/material.dart';

class ToursPage extends StatelessWidget {
  const ToursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tours"),
        backgroundColor: Color(0xfff2f2f2),
      ),
      body: const Center(
        child: Text("List of tours will be displayed here"),
      ),
    );
  }
}
