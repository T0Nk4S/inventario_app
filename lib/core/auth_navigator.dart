import 'package:flutter/material.dart';
import '../features/auth/login.dart';
import 'backend/backend.dart';

/// Helper que realiza el sign out y navega a la pantalla de login.
Future<void> signOutAndGoLogin(BuildContext context) async {
  await backendService.signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
}
