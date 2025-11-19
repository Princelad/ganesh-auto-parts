import 'package:flutter/material.dart';
import 'items_list_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganesh Auto Parts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, '/about'),
            tooltip: 'About',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              icon: Icons.inventory_2,
              title: 'Items',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemsListScreen(),
                ),
              ),
            ),
            _buildMenuCard(
              context,
              icon: Icons.people,
              title: 'Customers',
              color: Colors.green,
              onTap: () {
                // TODO: Navigate to customers screen
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
              },
            ),
            _buildMenuCard(
              context,
              icon: Icons.receipt_long,
              title: 'Invoices',
              color: Colors.orange,
              onTap: () {
                // TODO: Navigate to invoices screen
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
              },
            ),
            _buildMenuCard(
              context,
              icon: Icons.bar_chart,
              title: 'Reports',
              color: Colors.purple,
              onTap: () {
                // TODO: Navigate to reports screen
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
