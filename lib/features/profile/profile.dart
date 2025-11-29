import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final Future<void> Function()? onSignOut;
  const ProfilePage({this.onSignOut, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('Perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Información de la cuenta.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              if (onSignOut != null) await onSignOut!();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
