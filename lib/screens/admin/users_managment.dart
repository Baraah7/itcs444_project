import 'package:flutter/material.dart';

class UsersManagement extends StatelessWidget {
  const UsersManagement({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Management'),
      ),
      body: const Center(
        child: Text('Users Management Screen'),
      ),
    );
  }
}