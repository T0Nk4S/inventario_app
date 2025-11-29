import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';
import '../../core/models/models.dart';
import 'package:intl/intl.dart'; // Necesario para formatear fechas y precios

// Inicializamos el servicio backend (local stub)
final BackendService _backendService = backendService;

class Movements extends StatefulWidget {
  const Movements({super.key});

  @override
  State<Movements> createState() => _MovementsState();
}

class _MovementsState extends State<Movements> {
  late Future<List<MovementModel>> _movementsFuture;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_BO', symbol: 'Bs.');

  @override
  void initState() {
    super.initState();
    _fetchMovements();
  }

  void _fetchMovements() {
    setState(() {
  _movementsFuture = _backendService.fetchMovementsHistory();
    });
  }

  // Helper para determinar el color de la transacción
  Color _getTypeColor(String type) {
    return type == 'ENTRADA' ? Colors.green.shade600 : Colors.red.shade600;
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
                  const Expanded(child: Text('Historial de Movimientos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMovements, tooltip: 'Recargar Historial'),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MovementModel>>(
        future: _movementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el historial: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron movimientos registrados.'));
          }

          final movements = snapshot.data!;

          return ListView.builder(
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];
              final typeColor = _getTypeColor(movement.tipo);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: typeColor,
                    child: Icon(movement.tipo == 'ENTRADA' ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.white),
                  ),
                  title: Text(movement.productoMarcaModelo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Tipo: ${movement.tipo}', style: TextStyle(color: typeColor, fontWeight: FontWeight.w600)),
                    Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(movement.fecha)}'),
                    if (movement.clienteNombre != null) Text('Cliente: ${movement.clienteNombre}'),
                    if (movement.proveedorNombre != null) Text('Proveedor: ${movement.proveedorNombre}'),
                  ]),
                  trailing: Text(_currencyFormat.format(movement.precioTransaccion), style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              );
            },
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