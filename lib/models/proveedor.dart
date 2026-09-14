class Proveedor {
  final String id;
  final String codigo;
  final String razonSocial;
  final String nombreComercial;
  final String cuit;
  final String regionId;
  final String regionNombre;
  final String pais;
  final String contacto;
  final String email;
  final String telefono;
  final String observacion;
  final bool activo;

  const Proveedor({
    this.id = '',
    required this.codigo,
    required this.razonSocial,
    this.nombreComercial = '',
    this.cuit = '',
    this.regionId = '',
    this.regionNombre = '',
    this.pais = '',
    this.contacto = '',
    this.email = '',
    this.telefono = '',
    this.observacion = '',
    this.activo = true,
  });

  factory Proveedor.fromMap(Map<String, dynamic> map) {
    final region = map['regiones'];
    return Proveedor(
      id: map['id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      razonSocial: map['razon_social']?.toString() ?? '',
      nombreComercial: map['nombre_comercial']?.toString() ?? '',
      cuit: map['cuit']?.toString() ?? '',
      regionId: map['region_id']?.toString() ?? '',
      regionNombre: region is Map
          ? region['nombre']?.toString() ?? ''
          : map['region_nombre']?.toString() ?? '',
      pais: map['pais']?.toString() ??
          (region is Map ? region['pais']?.toString() ?? '' : ''),
      contacto: map['contacto']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      telefono: map['telefono']?.toString() ?? '',
      observacion: map['observacion']?.toString() ?? '',
      activo: map['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'codigo': codigo.trim(),
        'razon_social': razonSocial.trim(),
        'nombre_comercial': nombreComercial.trim(),
        'cuit': cuit.trim(),
        'region_id': regionId.isEmpty ? null : regionId,
        'pais': pais.trim(),
        'contacto': contacto.trim(),
        'email': email.trim(),
        'telefono': telefono.trim(),
        'observacion': observacion.trim(),
        'activo': activo,
      };

  String get etiqueta {
    final nombre = nombreComercial.trim().isNotEmpty
        ? nombreComercial.trim()
        : razonSocial.trim();
    return codigo.trim().isEmpty ? nombre : '${codigo.trim()} - $nombre';
  }
}
