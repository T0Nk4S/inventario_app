import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';

class HomeOverview extends StatefulWidget {
  const HomeOverview({super.key});

  @override
  State<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<HomeOverview> {
  final BackendService _svc = backendService;
  bool _loading = true;

  String mostBoughtProduct = 'N/A';
  String dayWithMostSales = 'N/A';
  String topSupplier = 'N/A';

  @override
  void initState() {
    super.initState();
    _computeOverview();
  }

  Future<void> _computeOverview() async {
    setState(() => _loading = true);

    final sales = await _svc.fetchSales();
    final products = await _svc.fetchProducts();
    final suppliers = await _svc.fetchSuppliers();
    final prodToProv = await _svc.fetchProductSupplierMap();

    // Map productId -> ProductModel
    final Map<String, dynamic> prodMap = {for (var p in products) p.id: p};

    // 1) Producto más comprado (por cantidad de ventas)
    final Map<String, int> productCounts = {};
    for (final s in sales) {
      final pid = s['productoId'] as String?;
      if (pid == null) continue;
      productCounts[pid] = (productCounts[pid] ?? 0) + 1;
    }
    if (productCounts.isNotEmpty) {
      final topEntry = productCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final prod = prodMap[topEntry.key];
      if (prod != null) {
        setState(() => mostBoughtProduct = '${prod.marca} ${prod.modelo} (${topEntry.value} ventas)');
      } else {
        setState(() => mostBoughtProduct = '${topEntry.key} (${topEntry.value} ventas)');
      }
    }

    // 2) Día con más ventas
    final Map<String, int> dayCounts = {};
    for (final s in sales) {
      final DateTime? d = s['fechaVenta'] as DateTime?;
      if (d == null) continue;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dayCounts[key] = (dayCounts[key] ?? 0) + 1;
    }
    if (dayCounts.isNotEmpty) {
      final topDay = dayCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      setState(() => dayWithMostSales = '${topDay.key} (${topDay.value} ventas)');
    }

    // 3) Proveedor cuyos productos se vendieron más
    final Map<String, int> supplierCounts = {};
    for (final s in sales) {
      final pid = s['productoId'] as String?;
      if (pid == null) continue;
      final provId = prodToProv[pid];
      if (provId == null || provId.isEmpty) continue;
      supplierCounts[provId] = (supplierCounts[provId] ?? 0) + 1;
    }
    if (supplierCounts.isNotEmpty) {
      final topProv = supplierCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final provIndex = suppliers.indexWhere((p) => p.id == topProv.key);
      if (provIndex >= 0) {
        final prov = suppliers[provIndex];
        setState(() => topSupplier = '${prov.nombre} (${topProv.value} ventas)');
      } else {
        setState(() => topSupplier = '${topProv.key} (${topProv.value} ventas)');
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 6),
              const Text('Inicio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.indigo),
                  title: const Text('Producto más comprado'),
                  subtitle: Text(mostBoughtProduct),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.orange),
                  title: const Text('Día con más ventas'),
                  subtitle: Text(dayWithMostSales),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.green),
                  title: const Text('Proveedor top en ventas'),
                  subtitle: Text(topSupplier),
                ),
              ),
            ]),
    );
  }
}
