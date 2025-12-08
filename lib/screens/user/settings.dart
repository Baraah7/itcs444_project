import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final String? category;
  final String? searchQuery;

  const Settings({
    super.key,
    this.category,
    this.searchQuery,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Settings Screen'),
      ),
    );
  }
}