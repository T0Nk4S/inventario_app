import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/login.dart'; // Pantalla de inicio de sesión (canónica)
import 'app_shell.dart';
import 'core/backend/backend.dart'; // Servicio backend local (BackendService)
import 'core/models/models.dart';

// ====================================================================
// CONFIGURACIÓN E INICIALIZACIÓN DEL BACKEND
// ====================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar Firebase si está disponible
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Si falla (desconectado o sin configuración), seguimos con backend local
  }

  // Si se solicita usar emuladores locales (por ejemplo para pruebas en AVD sin Google Play),
  // pasa --dart-define=USE_FIREBASE_EMULATOR=true al ejecutar.
  const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
  if (useEmulator) {
    try {
      // En emulador Android el host de la máquina es 10.0.2.2
      FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
      FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    } catch (e) {
      // ignorar si no aplicable
    }
  }

  // Inicializamos el backend (puede usar Firestore internamente si Firebase ok)
  await backendService.initialize();
  // Intentar asegurar esquema/colecciones en Firestore si es posible
  try {
    await backendService.ensureSchema();
  } catch (_) {}

  runApp(const MainApp());
}

// ====================================================================
// WIDGET PRINCIPAL DE LA APLICACIÓN
// ====================================================================

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.teal,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const AuthGuard(),
    );
  }
}

// ====================================================================
// GUARDIÁN DE AUTENTICACIÓN (AUTH GUARD)
// Maneja la navegación entre Login e Inventory
// ====================================================================

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool? _schemaReady;
  final BackendService _svc = backendService;
  UserModel? _currentProfile;
  final String _provisionUrl = const String.fromEnvironment('PROVISION_URL', defaultValue: '');

  @override
  void initState() {
    super.initState();
    _checkSchema();
  }

  Future<void> _checkSchema() async {
    final ok = await _svc.checkSchemaReady();
    final profile = await _svc.getCurrentUserProfile();
    if (mounted) setState(() => _schemaReady = ok);
    if (mounted) setState(() => _currentProfile = profile);
  }

  @override
  Widget build(BuildContext context) {
    // Mientras comprobamos el esquema
    if (_schemaReady == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    if (_schemaReady == false) {
      // Mostrar guía simple si la BD no contiene las tablas/vistas necesarias
      return Scaffold(
        appBar: AppBar(title: const Text('Inicializar Base de Datos')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('La base de datos no está inicializada.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  // Intentar crear las colecciones/ documentos iniciales
                  final created = await _svc.ensureSchema();
                  final msg = created ? 'Inicialización completada.' : 'No fue necesario crear estructuras o ocurrió un error.';
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(msg)));
                  _checkSchema();
                },
                icon: const Icon(Icons.playlist_add),
                label: const Text('Inicializar base de datos'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              const Text('Ejecute el script SQL de configuración con su herramienta de base de datos (psql, pgAdmin, etc.) para crear las tablas necesarias.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  // Mostrar instrucciones (SQL) en un diálogo
                  if (!mounted) return;
                  final BuildContext dialogCtx = context;
                  await showDialog<void>(
                    context: dialogCtx,
                    builder: (context) => AlertDialog(
                      title: const Text('Instrucciones'),
                      content: SingleChildScrollView(child: Text('El proyecto incluye un backend local para desarrollo. Si necesitas una BD externa, restaura el script SQL y usa tu herramienta preferida para ejecutarlo.')),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
                      ],
                    ),
                  );
                },
                child: const Text('Mostrar instrucciones'),
              ),

              const SizedBox(height: 12),
              if (_currentProfile?.rol == 'admin' && _provisionUrl.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    // Llamar al endpoint remoto de provisioning
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await _svc.requestRemoteProvision(_provisionUrl);
                    final msg = ok ? 'Provisionamiento ejecutado correctamente.' : 'Error al ejecutar el provisionamiento.';
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text(msg)));
                    if (ok) _checkSchema();
                  },
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Provisionar BD (remote)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                )
              else if (_currentProfile?.rol == 'admin')
                const Text('PROVISION_URL no configurada. Pasa --dart-define=PROVISION_URL=https://tu.endpoint/provision'),
            ],
          ),
        ),
      );
    }

    // Lógica simplificada basada en FutureBuilder: usamos el backend local
    return FutureBuilder<UserModel?>(
      future: _svc.getCurrentUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.teal)));
        }
        final profile = snapshot.data;
        if (profile == null) return const LoginScreen();
        final bool looksTemp = (profile.email.isEmpty) || (profile.email == 'admin@local') || (profile.rol == 'temp');
        if (looksTemp && _provisionUrl.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Configurar administrador')),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CreateAdminForm(provisionUrl: _provisionUrl, svc: _svc),
            ),
          );
        }
        return const AppShell();
      },
    );
  }
}

class CreateAdminForm extends StatefulWidget {
  final String provisionUrl;
  final BackendService svc;
  const CreateAdminForm({required this.provisionUrl, required this.svc, super.key});

  @override
  State<CreateAdminForm> createState() => _CreateAdminFormState();
}

class _CreateAdminFormState extends State<CreateAdminForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final payload = {
      'email': _email.text.trim(),
      'password': _password.text,
      'nombre': _nombre.text.trim(),
      'telefono': _telefono.text.trim(),
      // temp_email can be inferred from current user
    };
    // Intentar crear admin en Firestore + FirebaseAuth
    try {
      final ok = await widget.svc.createAdminUser(email: payload['email'] as String, password: payload['password'] as String, nombre: payload['nombre'] as String);
      setState(() => _loading = false);
      if (ok) {
        // logout current (temporary) user and show login
        await widget.svc.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin creado. Inicia sesión con el nuevo usuario.')));
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creando admin: $msg')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email del nuevo admin'), validator: (v) => v != null && v.contains('@') ? null : 'Email inválido'),
          TextFormField(controller: _password, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true, validator: (v) => v != null && v.length >= 8 ? null : 'Mínimo 8 caracteres'),
          TextFormField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre')),
          TextFormField(controller: _telefono, decoration: const InputDecoration(labelText: 'Teléfono')),
          const SizedBox(height: 20),
          _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submit, child: const Text('Crear admin')),
        ],
      ),
    );
  }
}