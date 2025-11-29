// Este archivo consolida todos los modelos de datos de la aplicación.

// ====================================================================
// 1. MODELO DE PRODUCTO (PRODUCTOS)
// ====================================================================

class ProductModel {
  final String id;
  final String codProducto;
  final String marca;
  final String modelo;
  final String imei1;
  final String? imei2;
  final String? color;
  final String categoria;
  final double precio; // Precio de Venta
  final String estado; // 'DISPONIBLE' o 'VENDIDO'
  
  ProductModel({
    required this.id,
    required this.codProducto,
    required this.marca,
    required this.modelo,
    required this.imei1,
    this.imei2,
    this.color,
    required this.categoria,
    required this.precio,
    required this.estado,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? '').toString(),
      codProducto: json['cod_producto'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      imei1: json['imei1'] as String,
      imei2: json['imei2'] as String?,
      color: json['color'] as String?,
      categoria: json['categoria'] as String,
      precio: (json['precio'] as num).toDouble(),
      estado: json['estado'] as String,
    );
  }
}

// ====================================================================
// 2. MODELO DE PROVEEDOR (PROVEEDORES)
// ====================================================================

class SupplierModel {
  final String id;
  final String nombre;
  final String telefono;
  final String contacto;

  SupplierModel({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.contacto,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: (json['id'] ?? '').toString(),
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      contacto: json['contacto'] as String,
    );
  }
}

// ====================================================================
// 3. MODELO DE MOVIMIENTO/HISTORIAL (Ventas y Movimientos)
// Este modelo combina datos de la tabla de Ventas y Movimientos
// para el historial unificado.
// ====================================================================

class MovementModel {
  final String id;
  final DateTime fecha;
  final String tipo; // 'ENTRADA' o 'SALIDA'
  final double precioTransaccion;
  final String productoMarcaModelo;
  final String? clienteNombre; // Solo para tipo SALIDA
  final String? proveedorNombre; // Solo para tipo ENTRADA
  
  MovementModel({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.precioTransaccion,
    required this.productoMarcaModelo,
    this.clienteNombre,
    this.proveedorNombre,
  });

  // Constructor para manejar los datos combinados de la DB
  factory MovementModel.fromJson(Map<String, dynamic> json) {
    // Determinar el nombre del producto de forma unificada
    String marca = json['products']?['marca'] ?? 'Desconocido';
    String modelo = json['products']?['modelo'] ?? 'N/A';
    String producto = '$marca $modelo';

    // Determinar el tipo de movimiento basado en qué campos existen
    String tipo = json.containsKey('proveedor_id') ? 'ENTRADA' : 'SALIDA';

    // Extraer nombres de cliente/proveedor si existen
    String? cliente = json['client_data']?['nombre_cliente'] != null ? 
                      '${json['client_data']['nombre_cliente']} ${json['client_data']['apellidos_cliente']}' : null;

    String? proveedor = json['suppliers']?['nombre'];

    return MovementModel(
      id: (json['id'] ?? '').toString(),
      fecha: DateTime.parse(json['created_at'] as String),
      tipo: tipo,
      precioTransaccion: (json['total_transaction'] as num).toDouble(), // Usamos un campo unificado
      productoMarcaModelo: producto,
      clienteNombre: cliente,
      proveedorNombre: proveedor,
    );
  }
}

// ====================================================================
// 4. MODELO DE USUARIO (AUTH.USERS)
// ====================================================================

class UserModel {
  final String id;
  final String email;
  final String rol;

  UserModel({
    required this.id,
    required this.email,
    required this.rol,
  });

  // Constructor para manejar la estructura de auth.users y profiles
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Asumimos que los datos vienen de la unión de auth.users y profiles
    final userJson = json['users'] ?? json; // Puede venir directo o anidado

    // Determinar rol: puede venir anidado en 'profiles', o en el objeto principal (cuando consultamos la tabla profiles)
    String rol;
    if (json['profiles'] != null && json['profiles']['rol'] != null) {
      rol = json['profiles']['rol'] as String;
    } else if (userJson['rol'] != null) {
      rol = userJson['rol'] as String;
    } else {
      rol = 'vendedor';
    }

    return UserModel(
      id: userJson['id']?.toString() ?? '',
      email: userJson['email']?.toString() ?? 'desconocido',
      rol: rol,
    );
  }
}