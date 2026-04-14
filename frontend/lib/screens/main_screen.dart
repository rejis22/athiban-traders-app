import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'dashboard_metrics_screen.dart';
import 'inventory_screen.dart';
import 'customers_screen.dart';
import 'billing_screen.dart';
import 'audit_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardMetricsScreen(),
    BillingScreen(),
    InventoryScreen(),
    CustomersScreen(),
    AuditScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Sale Invoices',
    'Items / Inventory',
    'Parties',
    'Reports / Audit',
  ];

  void _logout() async {
    final box = Hive.box('settings');
    await box.delete('token');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onMenuSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset('assets/images/logo.jpg', height: 50, errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.white, size: 50)),
                  const SizedBox(height: 12),
                  const Text(
                    'Athiban Traders',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(icon: Icons.dashboard, title: 'Dashboard', index: 0),
            _buildDrawerItem(icon: Icons.receipt_long, title: 'Sale', index: 1),
            _buildDrawerItem(icon: Icons.inventory_2, title: 'Items', index: 2),
            _buildDrawerItem(icon: Icons.people, title: 'Parties', index: 3),
            _buildDrawerItem(icon: Icons.analytics, title: 'Reports', index: 4),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Settings'),
              onTap: () {
                // Future Implementation for Settings
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings coming soon')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _screens[_currentIndex],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1 ? FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _currentIndex = 1; // Go to billing screen to create bill
          });
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Add Sale'),
      ) : null,
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required int index}) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      onTap: () => _onMenuSelected(index),
    );
  }
}
