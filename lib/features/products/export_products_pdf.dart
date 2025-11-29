import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Exportador de productos a PDF.
///
/// Exports a styled PDF grouped by category (Telefonos, Tablets, Audifonos, Accesorios)
/// and inside each category grouped by brand (marca). The function espera que cada
/// producto sea un map/objeto con campos: 'codProducto','marca','modelo','precio',
/// 'categoria','imei1','imei2','proveedor'.
class ProductsPdfExporter {
  static const List<String> orderedCategories = ['Telefonos', 'Tablets', 'Audifonos', 'Accesorios'];

  /// Generates the PDF bytes and opens the platform share sheet.
  /// [products] can be a list of dynamic objects (Maps or objects with dot fields).
  static Future<void> exportAndShare(BuildContext context, List products, double usdRate) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    // Helper to safely read property from dynamic product
    String readStr(dynamic p, String key) {
      if (p == null) return '';
      if (p is Map) {
        final v = p[key] ?? p[key.toLowerCase()] ?? p[key.toString()];
        return v?.toString() ?? '';
      }

      try {
        switch (key) {
          case 'codProducto':
            return (p.codProducto ?? p.code ?? p.id ?? '').toString();
          case 'marca':
            return (p.marca ?? p.brand ?? '').toString();
          case 'modelo':
            return (p.modelo ?? p.model ?? '').toString();
          case 'precio':
            return (p.precio ?? p.price ?? '').toString();
          case 'categoria':
            return (p.categoria ?? p.category ?? '').toString();
          case 'imei1':
            return (p.imei1 ?? p.imei ?? '').toString();
          case 'imei2':
            return (p.imei2 ?? '').toString();
          case 'proveedor':
            return (p.proveedor ?? p.supplier ?? '').toString();
          default:
            return '';
        }
      } catch (_) {
        return '';
      }
    }

    // Convert products into normalized maps for easier grouping
    final normalized = products.map((p) {
      final precioParsed = double.tryParse(readStr(p, 'precio')) ?? (p is Map && p['precio'] is num ? (p['precio'] as num).toDouble() : 0.0);
      final marcaVal = readStr(p, 'marca');
      final categoriaVal = readStr(p, 'categoria');

      return {
        'codProducto': readStr(p, 'codProducto'),
        'marca': marcaVal.isEmpty ? 'Sin marca' : marcaVal,
        'modelo': readStr(p, 'modelo'),
        'precio': precioParsed,
        'categoria': categoriaVal.isEmpty ? 'Sin categoria' : categoriaVal,
        'imei1': readStr(p, 'imei1'),
        'imei2': readStr(p, 'imei2'),
        'proveedor': readStr(p, 'proveedor'),
      };
    }).toList();

    // Build the PDF document
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(24),
      build: (pw.Context pdfContext) {
        final List<pw.Widget> widgets = [];

        widgets.add(pw.Header(
          level: 0,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Listado de Productos', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Generado: ${dateFormatter.format(now)}', style: pw.TextStyle(color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.Text('Resumen por categoría y marca', style: pw.TextStyle(fontSize: 12)),
          ]),
        ));

        if (normalized.isEmpty) {
          widgets.add(pw.Center(child: pw.Text('No hay productos para exportar')));
          return widgets;
        }

        for (final category in orderedCategories) {
          final catItems = normalized.where((m) => (m['categoria'] as String).toLowerCase() == category.toLowerCase()).toList();
          if (catItems.isEmpty) continue;

          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Text(category, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)));
          widgets.add(pw.SizedBox(height: 8));

          // Group by marca
          final brands = <String, List<Map<String, dynamic>>>{};
          for (final it in catItems) {
            final b = (it['marca'] ?? 'Sin marca') as String;
            brands.putIfAbsent(b, () => []).add(it);
          }

          for (final entry in brands.entries) {
            widgets.add(pw.Text(entry.key, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)));
            widgets.add(pw.SizedBox(height: 6));

            final table = pw.TableHelper.fromTextArray(
              headers: ['Código', 'Modelo', 'Precio (\$)', 'Precio (Bs)', 'IMEI1', 'IMEI2'],
              data: entry.value.map((row) {
                final precio = (row['precio'] as num).toDouble();
                final precioBs = precio * usdRate;
                return [
                  row['codProducto'] ?? '',
                  row['modelo'] ?? '',
                  precio.toStringAsFixed(2),
                  precioBs.toStringAsFixed(2),
                  row['imei1'] ?? '',
                  row['imei2'] ?? '',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blue900),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              columnWidths: {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(1.5),
                5: pw.FlexColumnWidth(1.5),
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            );

            widgets.add(table);
            widgets.add(pw.SizedBox(height: 8));
          }
        }

        return widgets;
      },
    ));

    try {
      final bytes = await doc.save();
      final name = 'productos_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generando PDF: $e')));
      }
    }
  }
}
