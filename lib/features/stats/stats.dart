import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final BackendService _svc = backendService;
  bool _loading = true;

  // Metrics
  int salesToday = 0;
  int salesMonth = 0;
  int salesYear = 0;

  double salesEarningsToday = 0.0;
  double salesEarningsMonth = 0.0;
  double salesEarningsYear = 0.0;

  double purchasesToday = 0.0;
  double purchasesMonth = 0.0;
  double purchasesYear = 0.0;

  double totalProductsValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
  bool _isSameYear(DateTime a, DateTime b) => a.year == b.year;

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final now = DateTime.now();

    // fetch sales
    final sales = await _svc.fetchSales();
    salesToday = 0;
    salesMonth = 0;
    salesYear = 0;
    salesEarningsToday = 0.0;
    salesEarningsMonth = 0.0;
    salesEarningsYear = 0.0;
    for (final s in sales) {
      final DateTime? d = s['fechaVenta'] as DateTime?;
      final double total = (s['totalVenta'] as double?) ?? 0.0;
      if (d == null) continue;
      if (_isSameDay(d, now)) {
        salesToday += 1;
        salesEarningsToday += total;
      }
      if (_isSameMonth(d, now)) {
        salesMonth += 1;
        salesEarningsMonth += total;
      }
      if (_isSameYear(d, now)) {
        salesYear += 1;
        salesEarningsYear += total;
      }
    }

    // fetch movements (for purchases/spendings)
    final movements = await _svc.fetchMovementsHistory();
    purchasesToday = 0.0;
    purchasesMonth = 0.0;
    purchasesYear = 0.0;
    for (final m in movements) {
      final d = m.fecha;
      // consider 'ENTRADA' as purchase (gasto)
      if (m.tipo.toUpperCase() == 'ENTRADA') {
        final double v = m.precioTransaccion;
        if (_isSameDay(d, now)) purchasesToday += v;
        if (_isSameMonth(d, now)) purchasesMonth += v;
        if (_isSameYear(d, now)) purchasesYear += v;
      }
    }

    // total products value
    final prods = await _svc.fetchProducts();
    totalProductsValue = 0.0;
    for (final p in prods) {
      totalProductsValue += p.precio;
    }

    if (mounted) setState(() => _loading = false);
  }

  Widget _metricCard(String title, String today, String month, String year, {Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Hoy', style: TextStyle(fontSize: 12, color: Colors.grey)), Text(today, style: const TextStyle(fontWeight: FontWeight.w600))])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Mes', style: TextStyle(fontSize: 12, color: Colors.grey)), Text(month, style: const TextStyle(fontWeight: FontWeight.w600))])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Año', style: TextStyle(fontSize: 12, color: Colors.grey)), Text(year, style: const TextStyle(fontWeight: FontWeight.w600))])),
          ])
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  const SizedBox(height: 6),
                  Row(children: [
                    const Expanded(child: Text('Estadísticas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh)),
                  ]),
                  const SizedBox(height: 12),
                  // Grid of metrics
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 1,
                      childAspectRatio: 3.2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        _metricCard('Ventas (cantidad)', salesToday.toString(), salesMonth.toString(), salesYear.toString(), color: Colors.indigo),
                        _metricCard('Ganancias por ventas', '\$${salesEarningsToday.toStringAsFixed(2)}', '\$${salesEarningsMonth.toStringAsFixed(2)}', '\$${salesEarningsYear.toStringAsFixed(2)}', color: Colors.green.shade700),
                        _metricCard('Gasto en compras', '\$${purchasesToday.toStringAsFixed(2)}', '\$${purchasesMonth.toStringAsFixed(2)}', '\$${purchasesYear.toStringAsFixed(2)}', color: Colors.red.shade700),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Valor total productos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('\$${totalProductsValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  )
                ]),
              ),
      ),
    );
  }
}
