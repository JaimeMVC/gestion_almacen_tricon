enum RolUsuario { owner, administrador, operador, consulta }

extension RolUsuarioX on RolUsuario {
  String get codigo => switch (this) {
    RolUsuario.owner => 'OWNER',
    RolUsuario.administrador => 'ADMINISTRADOR',
    RolUsuario.operador => 'OPERADOR',
    RolUsuario.consulta => 'CONSULTA',
  };

  String get etiqueta => switch (this) {
    RolUsuario.owner => 'Super Administrador',
    RolUsuario.administrador => 'Administrador',
    RolUsuario.operador => 'Operador',
    RolUsuario.consulta => 'Consulta',
  };

  static RolUsuario desdeCodigo(String? value) => switch (value?.toUpperCase()) {
    'OWNER' => RolUsuario.owner,
    'ADMINISTRADOR' => RolUsuario.administrador,
    'OPERADOR' => RolUsuario.operador,
    _ => RolUsuario.consulta,
  };
}

class PerfilUsuario {
  final String id;
  final String empresaId;
  final String email;
  final String nombre;
  final RolUsuario rol;
  final bool activo;
  final Map<String, bool> permisosPersonalizados;

  const PerfilUsuario({
    required this.id,
    required this.empresaId,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.activo,
    this.permisosPersonalizados = const {},
  });

  factory PerfilUsuario.fromMap(Map<String, dynamic> map) {
    final overrides = <String, bool>{};
    final raw = map['permisos_personalizados'];
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is bool) overrides[entry.key.toString()] = entry.value as bool;
      }
    }
    return PerfilUsuario(
      id: map['id']?.toString() ?? '',
      empresaId: map['empresa_id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      rol: RolUsuarioX.desdeCodigo(map['rol']?.toString()),
      activo: map['activo'] != false,
      permisosPersonalizados: overrides,
    );
  }
}

class Permisos {
  static const verInicio = 'ver_inicio';
  static const verStock = 'ver_stock';
  static const verMovimientos = 'ver_movimientos';
  static const recepcionar = 'recepcionar';
  static const transferir = 'transferir';
  static const despachar = 'despachar';
  static const verMaestros = 'ver_maestros';
  static const gestionarMaestros = 'gestionar_maestros';
  static const verDocumentos = 'ver_documentos';
  static const imprimirRemitos = 'imprimir_remitos';
  static const firmarRemitos = 'firmar_remitos';
  static const anularRemitos = 'anular_remitos';
  static const cargaMasiva = 'carga_masiva';
  static const exportarDatos = 'exportar_datos';
  static const verReportes = 'ver_reportes';
  static const gestionarUsuarios = 'gestionar_usuarios';
  static const gestionarOwners = 'gestionar_owners';
  static const verAuditoria = 'ver_auditoria';

  static const todos = <String>{
    verInicio, verStock, verMovimientos, recepcionar, transferir, despachar,
    verMaestros, gestionarMaestros, verDocumentos, imprimirRemitos,
    firmarRemitos, anularRemitos, cargaMasiva, exportarDatos, verReportes,
    gestionarUsuarios, gestionarOwners, verAuditoria,
  };

  static Set<String> porRol(RolUsuario rol) => switch (rol) {
    RolUsuario.owner => {...todos},
    RolUsuario.administrador => {
      verInicio, verStock, verMovimientos, recepcionar, transferir, despachar,
      verMaestros, gestionarMaestros, verDocumentos, imprimirRemitos,
      firmarRemitos, anularRemitos, cargaMasiva, exportarDatos, verReportes,
      gestionarUsuarios, verAuditoria,
    },
    RolUsuario.operador => {
      verInicio, verStock, verMovimientos, recepcionar, transferir, despachar,
      verDocumentos, imprimirRemitos, firmarRemitos, exportarDatos, verReportes,
    },
    RolUsuario.consulta => {
      verInicio, verStock, verMovimientos, verDocumentos, imprimirRemitos,
      exportarDatos, verReportes,
    },
  };
}
