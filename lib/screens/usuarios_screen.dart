import 'package:flutter/material.dart';
import '../models/perfil_usuario.dart';
import '../services/auth_service.dart';
import '../state/auth_state.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<PerfilUsuario> _usuarios = [];
  List<Map<String, dynamic>> _invitaciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final results = await Future.wait([authService.obtenerUsuarios(), authService.obtenerInvitaciones()]);
      if (!mounted) return;
      setState(() { _usuarios = results[0] as List<PerfilUsuario>; _invitaciones = results[1] as List<Map<String, dynamic>>; });
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _cargando = false); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Usuarios y permisos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Invitaciones, roles y estado de acceso.') ])),
        FilledButton.icon(onPressed: _invitar, icon: const Icon(Icons.person_add), label: const Text('Invitar usuario')),
        const SizedBox(width: 8),
        IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
      ]),
      const SizedBox(height: 16),
      if (_cargando) const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (_error != null) Expanded(child: Center(child: Text(_error!)))
      else Expanded(child: ListView(children: [
        Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('Usuario')), DataColumn(label: Text('Correo')), DataColumn(label: Text('Rol')), DataColumn(label: Text('Estado')), DataColumn(label: Text('Acciones'))], rows: _usuarios.map(_filaUsuario).toList()))),
        const SizedBox(height: 18),
        const Text('Invitaciones pendientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(child: _invitaciones.isEmpty ? const Padding(padding: EdgeInsets.all(18), child: Text('No hay invitaciones.')) : Column(children: _invitaciones.map((i) => ListTile(leading: const Icon(Icons.mail_outline), title: Text(i['nombre']?.toString() ?? ''), subtitle: Text('${i['email']} · ${i['rol']}'), trailing: Text(i['estado']?.toString() ?? 'PENDIENTE'))).toList())),
      ])),
    ]),
  );

  DataRow _filaUsuario(PerfilUsuario u) => DataRow(cells: [
    DataCell(Text(u.nombre.isEmpty ? '-' : u.nombre)),
    DataCell(Text(u.email)),
    DataCell(Text(u.rol.etiqueta)),
    DataCell(Chip(label: Text(u.activo ? 'Activo' : 'Inactivo'))),
    DataCell(IconButton(icon: const Icon(Icons.edit), tooltip: 'Editar acceso', onPressed: u.id == sessionState.perfil?.id ? null : () => _editar(u))),
  ]);

  Future<void> _invitar() async {
    final email = TextEditingController(); final nombre = TextEditingController(); var rol = RolUsuario.operador;
    final data = await showDialog<Map<String, dynamic>>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(title: const Text('Invitar usuario'), content: SizedBox(width: 430, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())), const SizedBox(height: 12),
      TextField(controller: email, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())), const SizedBox(height: 12),
      DropdownButtonFormField<RolUsuario>(value: rol, decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()), items: RolUsuario.values.where((r) => sessionState.perfil?.rol == RolUsuario.owner || r != RolUsuario.owner).map((r) => DropdownMenuItem(value: r, child: Text(r.etiqueta))).toList(), onChanged: (v) => setLocal(() => rol = v ?? rol)),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, {'email': email.text, 'nombre': nombre.text, 'rol': rol}), child: const Text('Crear invitación'))])));
    email.dispose(); nombre.dispose();
    if (data == null) return;
    try { await authService.crearInvitacion(email: data['email'], nombre: data['nombre'], rol: data['rol']); await _cargar(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo invitar: $e'))); }
  }

  Future<void> _editar(PerfilUsuario u) async {
    var rol = u.rol; var activo = u.activo;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(title: Text('Editar ${u.nombre}'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<RolUsuario>(value: rol, decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()), items: RolUsuario.values.where((r) => sessionState.perfil?.rol == RolUsuario.owner || r != RolUsuario.owner).map((r) => DropdownMenuItem(value: r, child: Text(r.etiqueta))).toList(), onChanged: (v) => setLocal(() => rol = v ?? rol)),
      SwitchListTile(value: activo, onChanged: (v) => setLocal(() => activo = v), title: const Text('Usuario activo')),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar'))])));
    if (ok != true) return;
    try { await authService.actualizarUsuario(id: u.id, rol: rol, activo: activo); await _cargar(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e'))); }
  }
}
