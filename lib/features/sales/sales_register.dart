import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';
import '../../core/models/models.dart';

// Inicializamos el servicio backend (local stub)
final BackendService _backendService = backendService;

class SalesRegister extends StatefulWidget {
  final ProductModel product;

  // Recibe el producto seleccionado desde la pantalla de Inventario
  const SalesRegister({super.key, required this.product});

  @override
  State<SalesRegister> createState() => _SalesRegisterState();
}

class _SalesRegisterState extends State<SalesRegister> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  
  @override
  void dispose() {
    _ciController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- LÓGICA PRINCIPAL DE REGISTRO DE VENTA ---
  Future<void> _registerSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _backendService.registerSale(
        productId: widget.product.id.toString(),
        totalVenta: widget.product.precio, // Usamos el precio del producto
        ciCliente: _ciController.text.trim(),
        nombreCliente: _nameController.text.trim(),
        apellidosCliente: _lastNameController.text.trim(),
        telefonoCliente: _phoneController.text.trim(),
      );

      // Mostrar confirmación y volver al inventario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta de ${widget.product.marca} ${widget.product.modelo} registrada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Regresar a la pantalla anterior (Inventario) informando éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar la venta: ${e.toString()}'),
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
        title: const Text('Registro de Venta'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- Detalles del Producto ---
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                child: ListTile(
                  leading: const Icon(Icons.sell, color: Colors.red),
                  title: Text(
                    '${widget.product.marca} ${widget.product.modelo}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('IMEI: ${widget.product.imei1} | Código: ${widget.product.codProducto}'),
                  trailing: Text(
                    '\$${widget.product.precio.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              
              const Text(
                'Datos del Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // --- Campo CI / NIT ---
              TextFormField(
                controller: _ciController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'C.I. / NIT',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El C.I. o NIT es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // --- Campo Nombre ---
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Nombre(s) del Cliente',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // --- Campo Apellidos ---
              TextFormField(
                controller: _lastNameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Apellidos del Cliente',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Los apellidos son obligatorios.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // --- Campo Teléfono ---
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono / Celular',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El teléfono es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- Botón de Confirmar Venta ---
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : ElevatedButton.icon(
                        onPressed: _registerSale,
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text(
                          'Confirmar Venta y Finalizar',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
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