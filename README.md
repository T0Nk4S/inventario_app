# inventario_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Notas sobre el backend y provisión

Esta versión del proyecto fue adaptada para funcionar sin un proveedor externo específico. Se incluye un backend local (stub) en `lib/core/backend/backend.dart` que simula las operaciones necesarias para que la app funcione durante desarrollo y pruebas.

Si en el futuro quieres volver a integrar una base de datos externa (Postgres u otro servicio), los pasos generales son:

- Añadir la dependencia del cliente correspondiente (p.ej. un cliente Postgres o una librería de tu proveedor elegido) en `pubspec.yaml`.
- Implementar o restaurar un servicio de backend que exponga las mismas funciones usadas por la UI (signIn, signOut, fetchSuppliers, registerNewProductAndMovement, fetchMovementsHistory, fetchUsers, getCurrentUserProfile, checkSchemaReady, requestRemoteProvision, requestCreateAdmin).
- Proveer un script SQL para crear las tablas requeridas: `profiles`, `Productos`, `Proveedores`, `Movimientos`, `Ventas`.

Si quieres que te ayude a integrar otro proveedor de backend (Firebase, SQLite local, o rest API), dímelo y adapto el código.

## Datos actualizados de conexión (proporcionados)
Has proporcionado nuevas credenciales de conexión:

<!-- Credenciales removidas del README por seguridad. Si necesitas restaurarlas, configúralas mediante variables de entorno o en tu entorno de despliegue. -->

> Nota: por seguridad evita dejar estas claves en el código; usa variables de entorno en producción.

## Tablas que se crearán al provisionar
El script `scripts/setup.sql` (o el endpoint remoto) crea las siguientes tablas en `public`:

- `profiles` — perfiles de los usuarios vinculados a `auth.users` (id, email, rol, nombre, telefono, created_at)
- `Productos` — inventario: id, cod_producto, marca, modelo, imei1, imei2, color, categoria, precio, proveedor_id, disponible, created_at
- `Proveedores` — proveedores: id, nombre, telefono, contacto, created_at
- `Movimientos` — entradas/salidas de stock: id, producto_id, usuario_id, tipo_movimiento, fecha_movimiento, cantidad, observacion
- `Ventas` — ventas registradas: id, id_producto, usuario_id, ci_cliente, nombre_cliente, apellidos_cliente, telefono_cliente, fecha_venta, total_venta

Puedes provisionar ahora la base de datos ejecutando el script de provisionamiento local (si lo tienes) o aplicando el archivo `scripts/schema.sql` con una herramienta segura (psql, pgAdmin, etc.).

Ejemplo genérico con psql (no incluyas credenciales en el repo):

```powershell
# Establece DATABASE_URL en tu entorno y luego ejecuta el script SQL con psql
# $env:DATABASE_URL='postgresql://user:password@host:5432/dbname'
# psql $env:DATABASE_URL -f scripts/schema.sql
```
