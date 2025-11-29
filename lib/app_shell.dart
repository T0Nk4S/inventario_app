import 'package:flutter/material.dart';
import 'widgets/bottom_nav.dart';

// Importar páginas desde sus respectivos módulos (cada screen es independiente)
import 'features/home/home.dart';
import 'features/products/products_list.dart';
import 'features/suppliers/suppliers_list.dart';
import 'features/sales/sales_list.dart';
import 'features/stats/stats.dart';
import 'features/profile/profile.dart';
import 'core/auth_navigator.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _onSelect(int idx) => setState(() => _selectedIndex = idx);

  Future<void> _signOut() async {
    await signOutAndGoLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeOverview(),
      const ProductsList(),
      const SuppliersList(),
      const SalesList(),
      const StatsPage(),
      ProfilePage(onSignOut: _signOut),
    ];

    return Scaffold(
      // Barra superior eliminada por ocupar espacio innecesario.
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNav(currentIndex: _selectedIndex, onSelect: _onSelect),
    );
  }
}
