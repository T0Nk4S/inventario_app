import 'package:flutter/material.dart';
import '../../core/backend/backend.dart';
import '../../core/models/models.dart';

// Inicializamos el servicio de backend (local stub)
final BackendService _backendService = backendService;

class Users extends StatefulWidget {
  const Users({super.key});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Carga la lista de usuarios/empleados
  void _fetchUsers() {
    setState(() {
      _usersFuture = _backendService.fetchUsers();
    });
  }

  // Abre el formulario modal para invitar o registrar un nuevo usuario
  void _showAddUserDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddUserForm(
            onUserAdded: _fetchUsers, // Función de callback para refrescar la lista
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Empleados'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar empleados: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay empleados registrados.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isAdmin = user.rol == 'admin';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.red.shade400 : Colors.blueGrey,
                    child: Text(
                      user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    user.email,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('ID: ${user.id}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAdmin ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAdmin ? 'ADMIN' : 'VENDEDOR',
                      style: TextStyle(
                        color: isAdmin ? Colors.red.shade900 : Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Invitar Empleado', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }
}

// ====================================================================
// FORMULARIO MODAL PARA AÑADIR NUEVO USUARIO
// ====================================================================

class AddUserForm extends StatefulWidget {
  final VoidCallback onUserAdded;

  const AddUserForm({super.key, required this.onUserAdded});

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE REGISTRO DE NUEVO USUARIO ---
  Future<void> _signUpUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _backendService.signUpNewUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitación enviada y usuario registrado: ${_emailController.text}.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUserAdded(); // Refresca la lista de usuarios
        Navigator.pop(context); // Cierra el modal
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar usuario: ${e.toString()}'),
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invitar Nuevo Empleado',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 15),

            // --- Campo Email ---
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico (Será su usuario)',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Introduce un correo válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // --- Campo Contraseña Temporal ---
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña Temporal',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // --- Botón de Registro ---
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : ElevatedButton.icon(
                      onPressed: _signUpUser,
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                      label: const Text(
                        'Registrar Empleado',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}