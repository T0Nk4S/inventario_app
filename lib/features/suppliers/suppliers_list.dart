import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';

class SuppliersList extends StatefulWidget {
  const SuppliersList({super.key});

  @override
  State<SuppliersList> createState() => _SuppliersListState();
}

class _SuppliersListState extends State<SuppliersList> {
  final BackendService _svc = backendService;
  bool _loading = true;
  List suppliers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _svc.fetchSuppliers();
    setState(() {
      suppliers = list;
      _loading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController();
    final telefono = TextEditingController();
    final contacto = TextEditingController();

    final ok = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Proveedor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
                TextFormField(controller: contacto, decoration: const InputDecoration(labelText: 'Contacto')),
                TextFormField(controller: telefono, decoration: const InputDecoration(labelText: 'Teléfono')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'nombre': nombre.text.trim(),
                'contacto': contacto.text.trim(),
                'telefono': telefono.text.trim(),
                'email': '',
                'direccion': ''
              };
              final nav = Navigator.of(context);
              await _svc.createSupplier(data);
              if (!mounted) return;
              nav.pop(true);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Proveedores', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Recargar'),
                  FloatingActionButton.small(onPressed: _showAddDialog, backgroundColor: Colors.teal, child: const Icon(Icons.add)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: suppliers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = suppliers[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: CircleAvatar(backgroundColor: Colors.indigo.shade400, child: const Icon(Icons.store, color: Colors.white)),
                            title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(p.telefono, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  await _showEditDialog(p);
                                  await _load();
                                } else if (v == 'delete') {
                                  await _svc.deleteSupplier(p.id);
                                  await _load();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Editar')),
                                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                              ],
                            ),
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

  Future<void> _showEditDialog(dynamic p) async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: p.nombre);
    final contacto = TextEditingController(text: p.contacto);
    final telefono = TextEditingController(text: p.telefono);

    final ok = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Proveedor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(children: [
              TextFormField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
              TextFormField(controller: contacto, decoration: const InputDecoration(labelText: 'Contacto')),
              TextFormField(controller: telefono, decoration: const InputDecoration(labelText: 'Teléfono')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final data = {'nombre': nombre.text.trim(), 'contacto': contacto.text.trim(), 'telefono': telefono.text.trim()};
            final nav = Navigator.of(context);
            await _svc.updateSupplier(p.id, data);
            if (!mounted) return;
            nav.pop(true);
          }, child: const Text('Guardar'))
        ],
      ),
    );
    if (ok == true) await _load();
  }
}
