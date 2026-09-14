import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil_usuario.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;
  User? get usuarioActual => _client.auth.currentUser;
  Stream<AuthState> get cambiosAuth => _client.auth.onAuthStateChange;

  Future<void> iniciarSesion(String email, String password) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> crearCuenta({required String email, required String password, required String nombre}) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nombre': nombre.trim()},
    );
  }

  Future<void> cerrarSesion() => _client.auth.signOut();

  Future<PerfilUsuario?> obtenerPerfilActual() async {
    final user = usuarioActual;
    if (user == null) return null;
    final row = await _client
        .from('perfiles_usuario')
        .select('id, empresa_id, email, nombre, rol, activo, permisos_personalizados')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return PerfilUsuario.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<PerfilUsuario>> obtenerUsuarios() async {
    final rows = await _client
        .from('perfiles_usuario')
        .select('id, empresa_id, email, nombre, rol, activo, permisos_personalizados')
        .order('nombre');
    return rows.map<PerfilUsuario>((e) => PerfilUsuario.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Map<String, dynamic>>> obtenerInvitaciones() async {
    final rows = await _client
        .from('invitaciones_usuario')
        .select('id, email, nombre, rol, estado, created_at')
        .order('created_at', ascending: false);
    return rows.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> crearInvitacion({required String email, required String nombre, required RolUsuario rol}) async {
    await _client.from('invitaciones_usuario').insert({
      'email': email.trim().toLowerCase(),
      'nombre': nombre.trim(),
      'rol': rol.codigo,
      'empresa_id': (await obtenerPerfilActual())!.empresaId,
      'invitado_por': usuarioActual!.id,
    });
  }

  Future<void> actualizarUsuario({required String id, required RolUsuario rol, required bool activo}) async {
    await _client.from('perfiles_usuario').update({'rol': rol.codigo, 'activo': activo}).eq('id', id);
  }
}

final authService = AuthService();
