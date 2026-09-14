import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil_usuario.dart';
import '../services/auth_service.dart';

class SessionState extends ChangeNotifier {
  PerfilUsuario? _perfil;
  bool _inicializando = true;
  String? _error;
  StreamSubscription<AuthState>? _subscription;

  PerfilUsuario? get perfil => _perfil;
  bool get inicializando => _inicializando;
  bool get autenticado => authService.usuarioActual != null && _perfil != null && _perfil!.activo;
  String? get error => _error;

  Future<void> inicializar() async {
    _subscription ??= authService.cambiosAuth.listen((_) => recargarPerfil());
    await recargarPerfil();
  }

  Future<void> recargarPerfil() async {
    _inicializando = true;
    _error = null;
    notifyListeners();
    try {
      _perfil = await authService.obtenerPerfilActual();
      if (authService.usuarioActual != null && _perfil == null) {
        _error = 'Tu cuenta todavía no tiene un perfil habilitado.';
      } else if (_perfil != null && !_perfil!.activo) {
        _error = 'Tu usuario está inactivo. Contactá a un administrador.';
      }
    } catch (e) {
      _perfil = null;
      _error = e.toString();
    } finally {
      _inicializando = false;
      notifyListeners();
    }
  }

  bool puede(String permiso) {
    final p = _perfil;
    if (p == null || !p.activo) return false;
    final override = p.permisosPersonalizados[permiso];
    if (override != null) return override;
    return Permisos.porRol(p.rol).contains(permiso);
  }

  Future<void> cerrarSesion() async {
    await authService.cerrarSesion();
    _perfil = null;
    notifyListeners();
  }
}

final sessionState = SessionState();
