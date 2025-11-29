Guía rápida para conectar este proyecto a Firebase Firestore

1) Firebase Console
   - Proyecto: bdagenda-8392a (ID: bdagenda-8392a, número: 185480174541)
   - Añadiste la app Android con package name: com.example.inventario_app
   - Descargaste `google-services.json` y lo colocaste en `android/app/google-services.json`

2) Dependencias Flutter
   - Ya instaladas: firebase_core, cloud_firestore, firebase_auth (ajustadas en pubspec)
   - Ejecuta: `flutter pub get` desde la raíz del proyecto (ya se ejecutó aquí).

3) Rules de seguridad
   - Archivo con reglas: `firestore.rules`
   - Para aplicarlas desde Firebase CLI:
     firebase deploy --only firestore:rules --project bdagenda-8392a

4) SHA / Firma
   - Si usas Google Sign-In o Dynamic Links, añade el SHA-1 de tu keystore a Firebase Console > Configuración del proyecto > tus apps Android.

5) Flujo admin temporal
   - En el primer inicio, el app creará un documento `Usuarios` con email `admin@local` y rol `temp` si no hay usuarios.
   - La pantalla de creación de admin (`CreateAdminForm`) llama a `backendService.createAdminUser(...)`.
   - Esto crea un usuario en Firebase Auth y un documento en `Usuarios` con rol `admin`, y elimina cualquier admin temporal.

6) Probar localmente
   - Ejecuta la app en un emulador o dispositivo: `flutter run -d <device>`
   - Usa el formulario para crear el admin y luego inicia sesión.

7) Siguientes mejoras
   - Implementar UI de gestión de proveedores/productos/ventas que use las colecciones.
   - Añadir validaciones y manejo de errores más detallado.
