import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String appVersion = '1.4.0';
  static const String buildNumber = '6';
  static const String githubUrl =
      'https://github.com/Princelad/ganesh-auto-parts';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ganesh Auto Parts',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete ERP Solution',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version $appVersion ($buildNumber)',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Description Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'About This App',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A comprehensive offline-first ERP application designed specifically '
                    'for auto parts businesses. Manage inventory, customers, invoicing, '
                    'and get detailed business insights - all without internet dependency.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Features Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_outline, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Key Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.inventory_2,
                    'Inventory Management',
                    'Complete stock tracking with alerts',
                  ),
                  _buildFeatureItem(
                    Icons.people,
                    'Customer Management',
                    'Track customers and balances',
                  ),
                  _buildFeatureItem(
                    Icons.receipt_long,
                    'Invoicing & GST',
                    'Professional invoices with tax support',
                  ),
                  _buildFeatureItem(
                    Icons.analytics,
                    'Business Reports',
                    '8+ comprehensive analytics reports',
                  ),
                  _buildFeatureItem(
                    Icons.picture_as_pdf,
                    'PDF Generation',
                    'Share invoices as PDF',
                  ),
                  _buildFeatureItem(
                    Icons.backup,
                    'Data Backup',
                    'Export/import with CSV and JSON',
                  ),
                  _buildFeatureItem(
                    Icons.security,
                    'PIN Security',
                    'Secure app with PIN protection',
                  ),
                  _buildFeatureItem(
                    Icons.offline_bolt,
                    '100% Offline',
                    'Works without internet connection',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Technology Stack Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Built With',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTechItem('Flutter', '3.27.1'),
                  _buildTechItem('Dart', '3.9.2'),
                  _buildTechItem('Riverpod', '3.0.3'),
                  _buildTechItem('SQLite', 'Database v2'),
                  _buildTechItem('Material Design', '3'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Developer Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Developer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Developed by Princelad',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl(githubUrl),
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View on GitHub',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // License Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'License',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Private License',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This software is proprietary and confidential. '
                    'Unauthorized copying, distribution, or modification is prohibited.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Release Info Card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.new_releases, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Latest Release',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'v1.3.0 - Comprehensive Reports Suite',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Stock Valuation Report\n'
                    '• Top Selling Items Report\n'
                    '• Sales by Period Report\n'
                    '• Customer Insights Report\n'
                    '• Enhanced analytics capabilities',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Copyright
          Center(
            child: Text(
              '© 2024-2025 Ganesh Auto Parts\nAll rights reserved',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(String name, String version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 14)),
          Text(
            version,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // If launch fails, try with default mode
        await launchUrl(uri);
      }
    } catch (e) {
      // Silently fail - url_launcher will show system error if needed
      debugPrint('Error opening link: $e');
    }
  }
}
