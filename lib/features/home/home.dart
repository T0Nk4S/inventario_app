import 'package:flutter/material.dart';

class HomeOverview extends StatelessWidget {
  const HomeOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 24),
          Text('Inicio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Resumen rápido del inventario y accesos rápidos.'),
        ],
      ),
    );
  }
}
