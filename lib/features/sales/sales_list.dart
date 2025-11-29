// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';

class SalesList extends StatefulWidget {
  const SalesList({super.key});

  @override
  State<SalesList> createState() => _SalesListState();
}

class _SalesListState extends State<SalesList> {
  final BackendService _svc = backendService;
  bool _loading = true;
  List sales = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _svc.fetchSales();
    setState(() {
      sales = list;
      _loading = false;
    });
  }

  Future<void> _showCreateSale() async {
    final formKey = GlobalKey<FormState>();
    final productId = TextEditingController();
    final nombre = TextEditingController();
    final apellidos = TextEditingController();
    final ci = TextEditingController();
    final telefono = TextEditingController();
    final total = TextEditingController();

    final ok = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Venta'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(children: [
              TextFormField(controller: productId, decoration: const InputDecoration(labelText: 'ID Producto')),
              TextFormField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre Cliente')),
              TextFormField(controller: apellidos, decoration: const InputDecoration(labelText: 'Apellidos')),
              TextFormField(controller: ci, decoration: const InputDecoration(labelText: 'CI')),
              TextFormField(controller: telefono, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextFormField(controller: total, decoration: const InputDecoration(labelText: 'Total'), keyboardType: TextInputType.number),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final t = double.tryParse(total.text) ?? 0;
            final nav = Navigator.of(context);
            await _svc.registerSale(productId: productId.text.trim(), totalVenta: t, ciCliente: ci.text.trim(), nombreCliente: nombre.text.trim(), apellidosCliente: apellidos.text.trim(), telefonoCliente: telefono.text.trim());
            if (!mounted) return;
            nav.pop(true);
          }, child: const Text('Registrar'))
        ],
      ),
    );

    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cabecera compacta integrada en el body para ahorrar espacio
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Ventas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Recargar'),
                  FloatingActionButton.small(onPressed: _showCreateSale, backgroundColor: Colors.teal, child: const Icon(Icons.add_shopping_cart)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: sales.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final s = sales[index];
                        final total = s['totalVenta'] ?? 0;
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: CircleAvatar(backgroundColor: Colors.orange.shade600, child: const Icon(Icons.receipt_long, color: Colors.white)),
                            title: Text('${s['nombreCliente']} ${s['apellidosCliente']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Producto: ${s['productoId']} • CI: ${s['ciCliente']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${total.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(s['fechaVenta'] != null ? (s['fechaVenta'].toString()) : '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            onTap: () async {
                              final product = await _svc.fetchProductById(s['productoId'] ?? '');
                              final DateTime? fecha = s['fechaVenta'] as DateTime?;
                              final fechaStr = fecha != null ? fecha.toLocal().toString() : 'Desconocida';
                              if (!mounted) return;
                              await showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Detalle de venta'),
                                  content: SingleChildScrollView(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('--- Producto ---', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('ID: ${s['productoId']}'),
                                      if (product != null) ...[
                                        Text('Código: ${product.codProducto}'),
                                        Text('Marca: ${product.marca}'),
                                        Text('Modelo: ${product.modelo}'),
                                        Text('IMEI1: ${product.imei1}'),
                                        Text('IMEI2: ${product.imei2 ?? ''}'),
                                        Text('Color: ${product.color ?? ''}'),
                                      ],
                                      const SizedBox(height: 12),
                                      const Text('--- Cliente ---', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Nombre: ${s['nombreCliente']} ${s['apellidosCliente']}'),
                                      Text('CI: ${s['ciCliente']}'),
                                      Text('Teléfono: ${s['telefonoCliente'] ?? ''}'),
                                      const SizedBox(height: 12),
                                      const Text('--- Venta ---', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Total: ${s['totalVenta'] ?? 0}'),
                                      Text('Fecha: $fechaStr'),
                                      const SizedBox(height: 12),
                                      const Text('--- Vendedor ---', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text('ID: ${s['vendedorId'] ?? 'N/A'}'),
                                      Text('Email: ${s['vendedorEmail'] ?? 'N/A'}'),
                                    ]),
                                  ),
                                  actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar'))],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
