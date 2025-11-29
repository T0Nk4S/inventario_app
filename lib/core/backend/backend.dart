import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

// Backend service: intenta usar Firestore si está disponible, sino usa un stub en memoria.
class BackendService {
  BackendService._internal();
  static final BackendService instance = BackendService._internal();

  // Firestore reference (null si no inicializado)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simulated storage fallback
  final Map<String, UserModel> _profiles = {};
  final Map<String, ProductModel> _productos = {};
  final List<MovementModel> _movimientos = [];

  // Auth simulation
  String? _signedInUserId;

  Future<void> initialize() async {
    // Si Firestore está disponible (Firebase inicializado) intentamos crear colecciones y admin
    try {
      // Verificar si la colección 'usuarios' tiene documentos
      final usuariosSnap = await _firestore.collection('Usuarios').limit(1).get();
      if (usuariosSnap.docs.isEmpty) {
        // Crear admin temporal
        final adminDoc = {
          'nombre': 'Admin Temporal',
          'email': 'admin@local',
          'contraseñaHash': '',
          'rol': 'temp'
        };
        await _firestore.collection('Usuarios').add(adminDoc);
      }
    } catch (e) {
      // cualquier error -> fallback in-memory
      if (_profiles.isEmpty) {
        final admin = UserModel(id: 'admin-1', email: 'admin@local', rol: 'admin');
        _profiles[admin.id] = admin;
      }
    }
  }

  /// Asegura que las colecciones necesarias existen en Firestore.
  /// Devuelve true si creó estructuras nuevas, false si ya existían.
  Future<bool> ensureSchema() async {
    try {
      // Revisar si al menos una colección tiene documento
      final usuarios = await _firestore.collection('Usuarios').limit(1).get();
      final proveedores = await _firestore.collection('Proveedores').limit(1).get();
      final productos = await _firestore.collection('Productos').limit(1).get();
      final movimientos = await _firestore.collection('Movimientos').limit(1).get();
      final ventas = await _firestore.collection('Ventas').limit(1).get();

      final created = usuarios.docs.isEmpty || proveedores.docs.isEmpty || productos.docs.isEmpty || movimientos.docs.isEmpty || ventas.docs.isEmpty;

      if (created) {
        // Crear documentos iniciales (vacíos / ejemplo) si hace falta
        if (usuarios.docs.isEmpty) {
          await _firestore.collection('Usuarios').add({
            'nombre': 'Admin Temporal',
            'email': 'admin@local',
            'contraseñaHash': '',
            'rol': 'temp',
          });
        }
        if (proveedores.docs.isEmpty) {
          await _firestore.collection('Proveedores').add({
            'nombre': 'Proveedor Ejemplo',
            'contacto': '',
            'telefono': '',
            'email': '',
            'direccion': ''
          });
        }
        if (productos.docs.isEmpty) {
          await _firestore.collection('Productos').add({
            'codProducto': 'EJ-001',
            'marca': 'MarcaEj',
            'modelo': 'ModeloEj',
            'categoria': 'CategoriaEj',
            'proveedor': '',
            'precio': 0,
            'imei1': '',
            'imei2': '',
            'color': ''
          });
        }
        // Movimientos y Ventas pueden quedar vacíos inicialmente
      }
      return created;
    } catch (e) {
      // En caso de fallo, suponer que no se pudieron crear estructuras (fallback in-memory)
      return false;
    }
  }

  /// Crea un usuario administrador usando Firebase Auth y la colección Usuarios.
  /// Devuelve true si se creó correctamente. Si hay un admin temporal, lo elimina.
  Future<bool> createAdminUser({required String email, required String password, String nombre = ''}) async {
    // Crear cuenta en Firebase Auth y propagar cualquier excepción para que la UI la muestre.
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    final uid = userCredential.user?.uid ?? '';
    // Guardar perfil en Firestore
    await _firestore.collection('Usuarios').doc(uid).set({
      'nombre': nombre,
      'email': email,
      'contraseñaHash': '',
      'rol': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Eliminar admin temporal (email admin@local)
    final tempSnap = await _firestore.collection('Usuarios').where('email', isEqualTo: 'admin@local').get();
    for (final d in tempSnap.docs) {
      await d.reference.delete();
    }

    return true;
  }

  Future<void> signIn(String email, String password) async {
    // Intentar autenticar con FirebaseAuth si está disponible
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final uid = cred.user?.uid;
      if (uid == null) throw Exception('No se obtuvo uid');
      _signedInUserId = uid;
      return;
    } catch (e) {
      // Fallback in-memory: buscar por email en _profiles
      final found = _profiles.values.firstWhere((p) => p.email == email, orElse: () => UserModel(id: '', email: '', rol: ''));
      if (found.id.isEmpty) throw Exception('Usuario no encontrado');
      _signedInUserId = found.id;
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _signedInUserId = null;
  }

  Future<UserModel?> getCurrentUserProfile() async {
    // Si hay usuario autenticado en Firebase, obtener su perfil desde Firestore
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      final uid = current.uid;
      try {
        final doc = await _firestore.collection('Usuarios').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          return UserModel(id: uid, email: data['email'] ?? current.email ?? '', rol: data['rol'] ?? 'vendedor');
        } else {
          // Si no existe perfil, crear uno básico
      final base = {'email': current.email ?? '', 'rol': 'vendedor'};
      await _firestore.collection('Usuarios').doc(uid).set(base);
          final String emailVal = (base['email'] != null) ? base['email'].toString() : '';
          final String rolVal = (base['rol'] != null) ? base['rol'].toString() : 'vendedor';
          return UserModel(id: uid, email: emailVal, rol: rolVal);
        }
      } catch (e) {
        return null;
      }
    }

    if (_signedInUserId == null) return null;
    return _profiles[_signedInUserId!];
  }

  Future<bool> checkSchemaReady() async {
    try {
      // Comprobar varias colecciones principales para determinar si el esquema/colecciones
      // ya contienen datos. Firestore no tiene "tablas" explícitas; existe una colección
      // cuando al menos un documento fue creado. Consideramos listo si alguna colección
      // principal contiene documentos.
      final usuarios = await _firestore.collection('Usuarios').limit(1).get();
      final proveedores = await _firestore.collection('Proveedores').limit(1).get();
      final productos = await _firestore.collection('Productos').limit(1).get();
      final movimientos = await _firestore.collection('Movimientos').limit(1).get();
      final ventas = await _firestore.collection('Ventas').limit(1).get();

      return usuarios.docs.isNotEmpty || proveedores.docs.isNotEmpty || productos.docs.isNotEmpty || movimientos.docs.isNotEmpty || ventas.docs.isNotEmpty;
    } catch (e) {
      // fallback in-memory
      return _profiles.isNotEmpty;
    }
  }

  Future<bool> requestRemoteProvision(String url) async {
    // not supported in stub
    return false;
  }

  Future<bool> requestCreateAdmin(String url, Map<String, dynamic> body) async {
    // Mantener compatibilidad: crear admin local
    final email = body['email'] as String? ?? '';
    final id = 'u-${_profiles.length + 1}';
    _profiles[id] = UserModel(id: id, email: email, rol: 'admin');
    return true;
  }

  // --- Proveedores (CRUD) ---
  Future<List<SupplierModel>> fetchSuppliers() async {
    try {
      final snap = await _firestore.collection('Proveedores').get();
      return snap.docs.map((d) => SupplierModel.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      return _profiles.isNotEmpty ? [] : [];
    }
  }

  Future<String> createSupplier(Map<String, dynamic> data) async {
    final doc = await _firestore.collection('Proveedores').add(data);
    return doc.id;
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    await _firestore.collection('Proveedores').doc(id).update(data);
  }

  Future<void> deleteSupplier(String id) async {
    await _firestore.collection('Proveedores').doc(id).delete();
  }

  // --- Productos ---
  Future<List<ProductModel>> fetchProducts() async {
    try {
      final snap = await _firestore.collection('Productos').get();
      return snap.docs.map((d) {
        final m = d.data();
          double safePrecio(dynamic v) {
            if (v == null) return 0.0;
            if (v is double) return v;
            if (v is int) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? 0.0;
            return 0.0;
          }
          return ProductModel(
            id: d.id,
            codProducto: m['codProducto'] ?? m['cod_producto'] ?? '',
            marca: m['marca'] ?? '',
            modelo: m['modelo'] ?? '',
            imei1: m['imei1'] ?? '',
            imei2: m['imei2'],
            color: m['color'],
            categoria: m['categoria'] ?? '',
            precio: safePrecio(m['precio']),
            estado: m['estado'] ?? 'DISPONIBLE',
          );
      }).toList();
    } catch (e) {
      return _productos.values.toList();
    }
  }

  Future<String> createProduct(Map<String, dynamic> data) async {
    final doc = await _firestore.collection('Productos').add(data);
    return doc.id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _firestore.collection('Productos').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection('Productos').doc(id).delete();
  }

  // Data operations (simplified)
  // Nota: implementación real de fetchSuppliers más abajo.

  Future<void> registerNewProductAndMovement({
    required String codProducto,
    required String marca,
    required String modelo,
    required String imei1,
    String? imei2,
    String? color,
    required String categoria,
    required double precioVenta,
    required String proveedorId,
  }) async {
    try {
      final prodDoc = await _firestore.collection('Productos').add({
        'codProducto': codProducto,
        'marca': marca,
        'modelo': modelo,
        'imei1': imei1,
        'imei2': imei2,
        'color': color,
        'categoria': categoria,
        'precio': precioVenta,
        'estado': 'DISPONIBLE',
        'proveedor': proveedorId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('Movimientos').add({
        'productoId': prodDoc.id,
        'tipoMovimiento': 'ENTRADA',
        'fechaMovimiento': FieldValue.serverTimestamp(),
        'cantidad': 1,
        'observacion': 'Nuevo producto registrado',
      });
    } catch (e) {
      // Fallback in-memory
      final id = 'p-${_productos.length + 1}';
      _productos[id] = ProductModel(id: id, codProducto: codProducto, marca: marca, modelo: modelo, imei1: imei1, imei2: imei2, color: color, categoria: categoria, precio: precioVenta, estado: 'DISPONIBLE');
      _movimientos.add(MovementModel(id: 'm-${_movimientos.length + 1}', fecha: DateTime.now(), tipo: 'ENTRADA', precioTransaccion: 0.0, productoMarcaModelo: '$marca $modelo'));
    }
  }

  Future<void> registerSale({required String productId, required double totalVenta, required String ciCliente, required String nombreCliente, required String apellidosCliente, required String telefonoCliente}) async {
    try {
      // Obtener info del vendedor (usuario autenticado) si está disponible
      final currentUser = FirebaseAuth.instance.currentUser;
      final vendedorId = currentUser?.uid ?? _signedInUserId;
      final vendedorEmail = currentUser?.email ?? '';

      // Crear registro en Ventas con info del vendedor
      await _firestore.collection('Ventas').add({
        'productoId': productId,
        'ciCliente': ciCliente,
        'nombreCliente': nombreCliente,
        'apellidosCliente': apellidosCliente,
        'telefonoCliente': telefonoCliente,
        'fechaVenta': FieldValue.serverTimestamp(),
        'totalVenta': totalVenta,
        'vendedorId': vendedorId,
        'vendedorEmail': vendedorEmail,
      });

      // Crear movimiento de salida
      await _firestore.collection('Movimientos').add({
        'productoId': productId,
        'tipoMovimiento': 'SALIDA',
        'fechaMovimiento': FieldValue.serverTimestamp(),
        'cantidad': 1,
        'observacion': 'Venta',
        'cliente': {
          'ci': ciCliente,
          'nombre': nombreCliente,
          'apellidos': apellidosCliente,
          'telefono': telefonoCliente,
        }
        ,
        'vendedor': {
          'id': vendedorId,
          'email': vendedorEmail,
        }
      });

      // Actualizar estado del producto
      await _firestore.collection('Productos').doc(productId).update({'estado': 'VENDIDO'});
    } catch (e) {
      // Fallback in-memory
      _movimientos.add(MovementModel(id: 's-${_movimientos.length + 1}', fecha: DateTime.now(), tipo: 'SALIDA', precioTransaccion: totalVenta, productoMarcaModelo: _productos[productId]?.marca ?? 'Desconocido', clienteNombre: nombreCliente));
      if (_productos.containsKey(productId)) {
        final p = _productos[productId]!;
        _productos[productId] = ProductModel(id: p.id, codProducto: p.codProducto, marca: p.marca, modelo: p.modelo, imei1: p.imei1, imei2: p.imei2, color: p.color, categoria: p.categoria, precio: p.precio, estado: 'VENDIDO');
      }
    }
  }

  /// Elimina todos los documentos de colecciones de datos excepto la colección `Usuarios`.
  /// Esto borra `Productos`, `Proveedores`, `Movimientos`, `Ventas` y otros datos definidos.
  Future<void> clearDatabaseExceptUsers() async {
    try {
      final collectionsToClear = ['Productos', 'Proveedores', 'Movimientos', 'Ventas'];
      for (final coll in collectionsToClear) {
        final snap = await _firestore.collection(coll).get();
        for (final doc in snap.docs) {
          await _firestore.collection(coll).doc(doc.id).delete();
        }
      }
    } catch (e) {
      // Fallback in-memory: limpiar mapas/lists pero preservar _profiles
      _productos.clear();
      _movimientos.clear();
    }
  }

  Future<List<MovementModel>> fetchMovementsHistory() async {
    try {
      final snap = await _firestore.collection('Movimientos').orderBy('fechaMovimiento', descending: true).get();
      return snap.docs.map((d) {
        final m = d.data();
        double safePrecio(dynamic v) {
          if (v == null) return 0.0;
          if (v is double) return v;
          if (v is int) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? 0.0;
          return 0.0;
        }
        return MovementModel(
          id: d.id,
          fecha: (m['fechaMovimiento'] as Timestamp?)?.toDate() ?? DateTime.now(),
          tipo: m['tipoMovimiento'] ?? 'N/A',
          precioTransaccion: safePrecio(m['total_transaction'] ?? m['precioTransaccion']),
          productoMarcaModelo: m['productoMarcaModelo'] ?? '',
          clienteNombre: m['cliente'] != null ? m['cliente']['nombre'] : null,
          proveedorNombre: m['proveedorNombre'] as String?,
        );
      }).toList();
    } catch (e) {
      return _movimientos.reversed.toList();
    }
  }

  // --- Ventas ---
  Future<List<Map<String, dynamic>>> fetchSales() async {
    try {
      final snap = await _firestore.collection('Ventas').orderBy('fechaVenta', descending: true).get();
      return snap.docs.map((d) {
        final m = d.data();
        double safeTotal(dynamic v) {
          if (v == null) return 0.0;
          if (v is double) return v;
          if (v is int) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? 0.0;
          return 0.0;
        }
        return {
          'id': d.id,
          'productoId': m['productoId'],
          'ciCliente': m['ciCliente'],
          'nombreCliente': m['nombreCliente'],
          'apellidosCliente': m['apellidosCliente'],
          'telefonoCliente': m['telefonoCliente'],
          'fechaVenta': (m['fechaVenta'] as Timestamp?)?.toDate(),
          'totalVenta': safeTotal(m['totalVenta']),
          // información del vendedor (si está presente en el documento)
          'vendedorId': m['vendedorId'],
          'vendedorEmail': m['vendedorEmail'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Devuelve un ProductModel por id o null si no existe / falla.
  Future<ProductModel?> fetchProductById(String id) async {
    try {
      final doc = await _firestore.collection('Productos').doc(id).get();
      if (!doc.exists) return null;
      final m = doc.data()!;
      double safePrecio(dynamic v) {
        if (v == null) return 0.0;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0.0;
        return 0.0;
      }
      return ProductModel(
        id: doc.id,
        codProducto: m['codProducto'] ?? m['cod_producto'] ?? '',
        marca: m['marca'] ?? '',
        modelo: m['modelo'] ?? '',
        imei1: m['imei1'] ?? '',
        imei2: m['imei2'],
        color: m['color'],
        categoria: m['categoria'] ?? '',
        precio: safePrecio(m['precio']),
        estado: m['estado'] ?? 'DESCONOCIDO',
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> fetchUniqueBrands() async { return _productos.values.map((p) => p.marca.toUpperCase()).toSet().toList(); }

  Future<List<UserModel>> fetchUsers() async { return _profiles.values.toList(); }

  Future<void> signUpNewUser(String email, String password) async {
    final id = 'u-${_profiles.length + 1}';
    _profiles[id] = UserModel(id: id, email: email, rol: 'vendedor');
  }
}

// Convenience constructor
BackendService get backendService => BackendService.instance;
