import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const BottomNav({required this.currentIndex, required this.onSelect, super.key});

  Widget _item(BuildContext context, int idx, IconData icon, String label) {
    final selected = currentIndex == idx;
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.grey[600];
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: () => onSelect(idx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  // withOpacity está deprecado; usar withAlpha para evitar pérdida de precisión
                  color: selected
                      ? Theme.of(context).colorScheme.primary.withAlpha((0.12 * 255).round())
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _item(context, 0, Icons.home, 'Inicio'),
              _item(context, 1, Icons.inventory_2, 'Productos'),
              _item(context, 2, Icons.local_shipping, 'Proveedores'),
              _item(context, 3, Icons.swap_horiz, 'Ventas'),
              _item(context, 4, Icons.bar_chart, 'Stats'),
              _item(context, 5, Icons.person, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}
