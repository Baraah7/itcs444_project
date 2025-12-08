import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class HelpAndSupport extends StatelessWidget {
  const HelpAndSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: _buildHelpBody(context),
    );
  }

// ============ HELP BODY ============
  Widget _buildHelpBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Help & Support",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          _helpSection(
            icon: Icons.phone,
            title: "24/7 Support Line",
            subtitle: "Call us anytime at 1-800-MED-HELP",
            onTap: () => _callSupport(),
          ),
          _helpSection(
            icon: Icons.email,
            title: "Email Support",
            subtitle: "support@medequipment.com",
            onTap: () => _emailSupport(),
          ),
          _helpSection(
            icon: Icons.question_answer,
            title: "FAQ",
            subtitle: "Frequently asked questions",
            onTap: () => _openFAQ(),
          ),
          _helpSection(
            icon: Icons.book,
            title: "User Guides",
            subtitle: "Equipment usage instructions",
            onTap: () => _openGuides(),
          ),
        ],
      ),
    );
  }

  Widget _helpSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _callSupport() {
    // Implement call support
  }

  void _emailSupport() {
    // Implement email support
  }

  void _openFAQ() {
    // Implement FAQ
  }

  void _openGuides() {
    // Implement guides
  }
}