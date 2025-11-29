import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';
import '../../core/models/models.dart';

// Servicio backend local (stub)
final BackendService _backendService = backendService;

class StockEntry extends StatefulWidget {
  const StockEntry({super.key});

  @override
  State<StockEntry> createState() => _StockEntryState();
}

class _StockEntryState extends State<StockEntry> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos del producto
  final TextEditingController _codProductoController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _imei1Controller = TextEditingController();
  final TextEditingController _imei2Controller = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _precioController = TextEditingController(); // Precio de Venta
  
  // Estado y listas para la interfaz
  bool _isLoading = false;
  List<SupplierModel> _suppliers = [];
  SupplierModel? _selectedSupplier;
  
  // Opciones de categorías fijas (ejemplo)
  final List<String> _categories = [
    'Teléfonos',
    'Tablets',
    'Audífonos',
    'Accesorios'
  ];
  String? _selectedCategory;


  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  @override
  void dispose() {
    _codProductoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    _colorController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // Carga la lista de proveedores desde el backend local
  Future<void> _fetchSuppliers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedSuppliers = await _backendService.fetchSuppliers();
      setState(() {
        _suppliers = fetchedSuppliers;
        // Si ya había uno seleccionado y sigue en la lista, lo mantiene
        if (_selectedSupplier != null && !_suppliers.any((s) => s.id == _selectedSupplier!.id)) {
            _selectedSupplier = null;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar proveedores: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- LÓGICA DE REGISTRO DE PRODUCTO Y MOVIMIENTO ---
  Future<void> _registerProduct() async {
    if (!_formKey.currentState!.validate() || _selectedSupplier == null) {
      if (_selectedSupplier == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona un proveedor.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _backendService.registerNewProductAndMovement(
        codProducto: _codProductoController.text.trim(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        imei1: _imei1Controller.text.trim(),
        imei2: _imei2Controller.text.trim().isEmpty ? null : _imei2Controller.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        categoria: _selectedCategory!,
        precioVenta: double.parse(_precioController.text.trim()),
        proveedorId: _selectedSupplier!.id.toString(),
      );

      // Mostrar confirmación y limpiar formulario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto ${_marcaController.text} ${_modeloController.text} registrado con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Regresar y notificar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar la entrada: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada de Stock (Nuevo Producto)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- SELECCIÓN DE PROVEEDOR ---
              _isLoading && _suppliers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<SupplierModel>(
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        prefixIcon: Icon(Icons.local_shipping),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedSupplier,
                      hint: const Text('Selecciona el proveedor'),
                      items: _suppliers.map((SupplierModel supplier) {
                        return DropdownMenuItem<SupplierModel>(
                          value: supplier,
                          child: Text(supplier.nombre),
                        );
                      }).toList(),
                      onChanged: (SupplierModel? newValue) {
                        setState(() {
                          _selectedSupplier = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Selecciona un proveedor.' : null,
                    ),
              const SizedBox(height: 20),

              const Text(
                'Datos del Producto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // --- Campo CÓDIGO DE PRODUCTO ---
              TextFormField(
                controller: _codProductoController,
                decoration: const InputDecoration(
                  labelText: 'Código de Producto',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio.' : null,
              ),
              const SizedBox(height: 15),

              // --- Campo MARCA ---
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca (Ej: Samsung, Xiaomi)',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio.' : null,
              ),
              const SizedBox(height: 15),

              // --- Campo MODELO ---
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  labelText: 'Modelo (Ej: Galaxy S23, Redmi Note 12)',
                  prefixIcon: Icon(Icons.devices),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio.' : null,
              ),
              const SizedBox(height: 15),

              // --- Campo CATEGORÍA ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Selecciona una categoría.' : null,
              ),
              const SizedBox(height: 15),


              // --- Campo IMEI 1 ---
              TextFormField(
                controller: _imei1Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'IMEI 1',
                  prefixIcon: Icon(Icons.featured_play_list),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'IMEI 1 es obligatorio.' : null,
              ),
              const SizedBox(height: 15),

              // --- Campo IMEI 2 (Opcional) ---
              TextFormField(
                controller: _imei2Controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'IMEI 2 (Opcional)',
                  prefixIcon: Icon(Icons.featured_play_list_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // --- Campo COLOR (Opcional) ---
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color (Opcional)',
                  prefixIcon: Icon(Icons.color_lens),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),


              // --- Campo PRECIO DE VENTA ---
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio de Venta (Público)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'El precio es obligatorio.';
                  if (double.tryParse(value) == null) return 'Introduce un número válido.';
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- Botón de Registrar Entrada ---
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                    : ElevatedButton.icon(
                        onPressed: _registerProduct,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Registrar Entrada de Stock',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}