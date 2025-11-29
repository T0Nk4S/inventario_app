import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'export_products_pdf.dart';
import '../sales/sales_register.dart';
import '../common/barcode_scanner.dart';

class ProductsList extends StatefulWidget {
  const ProductsList({super.key});

  @override
  State<ProductsList> createState() => _ProductsListState();
}

class _ProductsListState extends State<ProductsList> {
  final BackendService _svc = backendService;
  bool _loading = true;
  List products = [];
  List suppliers = [];
  double _usdRate = 1.0; // tasa USD -> BOB

  @override
  void initState() {
    super.initState();
    _load();
    _loadSuppliers();
    _loadUsdRate();
  }

  Future<void> _loadSuppliers() async {
    final list = await _svc.fetchSuppliers();
    setState(() {
      suppliers = list;
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _svc.fetchProducts();
    setState(() {
      products = list;
      _loading = false;
    });
  }

  Future<void> _loadUsdRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rate = prefs.getDouble('usd_to_bob_rate') ?? 1.0;
      setState(() => _usdRate = rate);
    } catch (e) {
      // ignore errors, keep default
    }
  }

  // Search and filter state
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String? _selectedBrand;
  final List<String> _categories = ['Todos', 'Telefonos', 'Tablets', 'Audifonos', 'Accesorios'];

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final cod = TextEditingController();
    final marca = TextEditingController();
    final modelo = TextEditingController();
    final precio = TextEditingController();
    final imei1 = TextEditingController();
    final imei2 = TextEditingController();
    final color = TextEditingController();
    String? proveedorId;
    // tipos disponibles para el producto
    final List<String> tipos = ['Telefonos', 'Tablets', 'Audifonos', 'Accesorios'];
    String tipoSelected = 'Telefonos';

    final ok = await showDialog<bool?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setStateDialog) => AlertDialog(
          title: const Text('Nuevo Producto'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                TextFormField(
                  controller: cod,
                  decoration: InputDecoration(
                    labelText: 'Código',
                      suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final nav = Navigator.of(innerContext);
                        final res = await nav.push<String?>(MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
                        if (res != null && res.isNotEmpty) cod.text = res;
                      },
                    ),
                  ),
                ),
                TextFormField(controller: marca, decoration: const InputDecoration(labelText: 'Marca')),
                TextFormField(controller: modelo, decoration: const InputDecoration(labelText: 'Modelo')),
                TextFormField(controller: precio, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number),
                TextFormField(
                  controller: imei1,
                  decoration: InputDecoration(
                    labelText: 'IMEI 1 (obligatorio)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final nav = Navigator.of(innerContext);
                        final res = await nav.push<String?>(MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
                        if (res != null && res.isNotEmpty) imei1.text = res;
                      },
                    ),
                  ),
                ),
                TextFormField(
                  controller: imei2,
                  decoration: InputDecoration(
                    labelText: 'IMEI 2 (opcional)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final nav = Navigator.of(innerContext);
                        final res = await nav.push<String?>(MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
                        if (res != null && res.isNotEmpty) imei2.text = res;
                      },
                    ),
                  ),
                ),
                TextFormField(controller: color, decoration: const InputDecoration(labelText: 'Color (opcional)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tipoSelected,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) {
                    if (v != null) setStateDialog(() => tipoSelected = v);
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Seleccione un tipo' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: proveedorId,
                  decoration: const InputDecoration(labelText: 'Proveedor'),
                  items: suppliers.map<DropdownMenuItem<String>>((s) {
                    return DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.nombre),
                    );
                  }).toList(),
                  onChanged: (v) => setStateDialog(() => proveedorId = v),
                  validator: (v) => v == null || v.isEmpty ? 'Seleccione un proveedor' : null,
                ),
              ],
            ),
          ),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.of(innerContext).pop(false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final data = {
                      'codProducto': cod.text.trim(),
                      'marca': marca.text.trim(),
                      'modelo': modelo.text.trim(),
                      'precio': double.tryParse(precio.text) ?? 0,
                      'categoria': tipoSelected,
                      'imei1': imei1.text.trim(),
                      'imei2': imei2.text.trim(),
                      'color': color.text.trim(),
                      'proveedor': proveedorId ?? '',
                    };
                    try {
                      await _svc.createProduct(data);
                      if (!innerContext.mounted) return;
                      Navigator.of(innerContext).pop(true);
                    } catch (e) {
                      // ignore: avoid_print
                      print('Error creating product: $e');
                      if (innerContext.mounted) {
                        ScaffoldMessenger.of(innerContext).showSnackBar(
                          SnackBar(content: Text('Error creando producto: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Crear'),
                ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto creado correctamente')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // derive list of brands
    final brands = <String>{for (var p in products) (p.marca ?? 'Sin marca')}.toList();
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : Column(
                children: [
                  const SizedBox(height: 8),
                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Productos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                      ],
                    ),
                  ),
                  // Search box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Buscar producto, código, IMEI...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                    ),
                  ),
                  // Tabs
                  Material(
                    color: Colors.transparent,
                    child: TabBar(
                      isScrollable: true,
                      tabs: _categories.map((c) => Tab(text: c)).toList(),
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                    ),
                  ),
                  // Brands chips
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: [
                        ChoiceChip(
                          label: const Text('Todas'),
                          selected: _selectedBrand == null,
                          onSelected: (_) => setState(() => _selectedBrand = null),
                        ),
                        ...brands.map((b) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ChoiceChip(
                                label: Text(b),
                                selected: _selectedBrand == b,
                                onSelected: (_) => setState(() => _selectedBrand = b),
                              ),
                            )),
                      ],
                    ),
                  ),
                  // Tab views for categories
                  Expanded(
                    child: TabBarView(
                      children: _categories.map((cat) {
                        // filter products by search, brand and category
                        final list = products.where((p) {
                          final matchesSearch = _search.isEmpty || ('${p.codProducto ?? ''} ${p.marca ?? ''} ${p.modelo ?? ''} ${p.imei1 ?? ''}').toLowerCase().contains(_search);
                          final matchesBrand = _selectedBrand == null || (p.marca == _selectedBrand);
                          final matchesCategory = cat == 'Todos' || (p.categoria ?? '').toString().toLowerCase() == cat.toLowerCase();
                          return matchesSearch && matchesBrand && matchesCategory;
                        }).toList();

                        if (list.isEmpty) {
                          return const Center(child: Text('No hay dispositivos que mostrar'));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final p = list[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                title: Text('${p.marca} ${p.modelo}'),
                                subtitle: Text('Código: ${p.codProducto} • Precio: \$${p.precio} • Bs ${(p.precio * _usdRate).toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.point_of_sale, color: Colors.orange),
                                      tooltip: 'Vender',
                                      onPressed: () async {
                                        try {
                                          final nav = Navigator.of(context);
                                          final result = await nav.push<bool?>(
                                            MaterialPageRoute(builder: (_) => SalesRegister(product: p)),
                                          );
                                          if (result == true) await _load();
                                        } catch (e, st) {
                                          // Log the error and show feedback to the user
                                          // ignore: avoid_print
                                          print('Error opening SalesRegister: $e\n$st');
                                          if (!mounted) return;
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('No se pudo abrir la pantalla de venta: $e')),
                                            );
                                          });
                                        }
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          await _showEditDialog(p);
                                          await _load();
                                        } else if (v == 'delete') {
                                          await _svc.deleteProduct(p.id);
                                          await _load();
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                        const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'export_pdf',
              mini: true,
              onPressed: () async {
                // show simple progress while generating
                showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  await ProductsPdfExporter.exportAndShare(context, products, _usdRate);
                } catch (e) {
                  // ignore: avoid_print
                  print('Error exporting PDF: $e');
                }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  });
              },
              backgroundColor: Colors.redAccent,
              tooltip: 'Exportar productos a PDF',
              child: const Icon(Icons.picture_as_pdf),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'usd_rate',
              mini: true,
              onPressed: _showUsdRateDialog,
              backgroundColor: Colors.indigo,
              tooltip: 'Actualizar tipo de cambio',
              child: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'add_product',
              onPressed: _showAddDialog,
              backgroundColor: Colors.teal,
              tooltip: 'Agregar producto',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUsdRateDialog() async {
  final controller = TextEditingController(text: _usdRate.toString());
    final ok = await showDialog<bool?>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tipo de cambio USD → BOB'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Precio actual del dólar: \$${_usdRate.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ingrese la tasa (ej: 6.96)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            final val = double.tryParse(controller.text.replaceAll(',', '.'));
            if (val == null || val <= 0) {
              if (dialogCtx.mounted) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(content: Text('Ingrese un número válido')));
              }
              return;
            }
            try {
              final dialogNav = Navigator.of(dialogCtx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('usd_to_bob_rate', val);
              if (!mounted) return;
              setState(() => _usdRate = val);
              dialogNav.pop(true);
              if (!mounted) return;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tasa actualizada a Bs ${val.toStringAsFixed(2)}')));
              });
            } catch (e) {
              if (dialogCtx.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!dialogCtx.mounted) return;
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(content: Text('Error guardando tasa: $e')));
                });
              }
            }
          }, child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      // recargar lista para refrescar UI si es necesario
      await _load();
    }
  }

  Future<void> _showEditDialog(dynamic p) async {
    final formKey = GlobalKey<FormState>();
    final cod = TextEditingController(text: p.codProducto);
    final marca = TextEditingController(text: p.marca);
    final modelo = TextEditingController(text: p.modelo);
    final precio = TextEditingController(text: p.precio.toString());

    final ok = await showDialog<bool?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Producto'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(children: [
              TextFormField(controller: cod, decoration: const InputDecoration(labelText: 'Código')),
              TextFormField(controller: marca, decoration: const InputDecoration(labelText: 'Marca')),
              TextFormField(controller: modelo, decoration: const InputDecoration(labelText: 'Modelo')),
              TextFormField(controller: precio, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: TextInputType.number),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final data = {
              'codProducto': cod.text.trim(),
              'marca': marca.text.trim(),
              'modelo': modelo.text.trim(),
              'precio': double.tryParse(precio.text) ?? 0,
            };
            await _svc.updateProduct(p.id, data);
            if (!mounted) return;
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop(true);
          }, child: const Text('Guardar'))
        ],
      ),
    );
    if (ok == true) await _load();
  }
}
