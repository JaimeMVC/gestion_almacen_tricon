import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/almacen.dart';
import '../models/documento.dart';
import '../models/equipo.dart';
import '../models/material_item.dart';
import '../models/movimiento.dart';
import '../models/proveedor.dart';
import '../models/proyecto.dart';
import '../models/region_compra.dart';
import '../models/stock_item.dart';
import '../models/ubicacion.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MaterialItem>> obtenerMateriales() async {
    final response = await _client
        .from('materiales')
        .select()
        .eq('activo', true)
        .order('codigo');

    return response.map<MaterialItem>((row) {
      return MaterialItem(
        id: row['id']?.toString() ?? '',
        codigo: row['codigo'] ?? '',
        nombre: row['nombre'] ?? '',
        familia: row['familia'] ?? '',
        observacion: row['observacion'] ?? '',
      );
    }).toList();
  }

  Future<void> guardarMaterial(MaterialItem material) async {
    await _client.from('materiales').upsert(
      {
        'codigo': material.codigo,
        'nombre': material.nombre,
        'familia': material.familia,
        'observacion': material.observacion,
        'activo': true,
      },
      onConflict: 'codigo',
    );
  }

  Future<List<Proyecto>> obtenerProyectos({bool incluirInactivos = true}) async {
    var query = _client.from('proyectos').select();
    if (!incluirInactivos) query = query.eq('activo', true);
    final response = await query
        .order('activo', ascending: false)
        .order('codigo');
    return response
        .map<Proyecto>((row) => Proyecto.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> guardarProyecto(Proyecto proyecto) async {
    final datos = proyecto.toMap();
    if (proyecto.id.isEmpty) {
      await _client.from('proyectos').insert(datos);
    } else {
      await _client.from('proyectos').update(datos).eq('id', proyecto.id);
    }
  }

  Future<void> cambiarEstadoProyecto({
    required String id,
    required bool activo,
  }) async {
    await _client.from('proyectos').update({
      'activo': activo,
      'fecha_cierre': activo
          ? null
          : DateTime.now().toIso8601String().split('T').first,
    }).eq('id', id);
  }

  Future<List<Almacen>> obtenerAlmacenes({bool incluirInactivos = true}) async {
    var query = _client.from('almacenes').select('*, proyectos(codigo, nombre)');

    if (!incluirInactivos) {
      query = query.eq('activo', true);
    }

    final response = await query.order('activo', ascending: false).order('codigo');

    return response
        .map<Almacen>((row) => Almacen.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> guardarAlmacen(Almacen almacen) async {
    final datos = almacen.toMap();

    if (almacen.id.isEmpty) {
      await _client.from('almacenes').insert(datos);
      return;
    }

    await _client.from('almacenes').update(datos).eq('id', almacen.id);
  }

  Future<void> cambiarEstadoAlmacen({
    required String id,
    required String estado,
  }) async {
    await _client.rpc(
      'cambiar_estado_almacen',
      params: {
        'p_almacen_id': id,
        'p_estado': estado,
      },
    );
  }

  Future<List<Ubicacion>> obtenerUbicaciones({bool incluirInactivas = true}) async {
    var query = _client.from('ubicaciones').select(
      'id, almacen_id, codigo, descripcion, observacion, activa, '
      'almacenes(codigo, nombre)',
    );

    if (!incluirInactivas) {
      query = query.eq('activa', true);
    }

    final response = await query
        .order('almacen_id')
        .order('activa', ascending: false)
        .order('codigo');

    return response
        .map<Ubicacion>((row) =>
            Ubicacion.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> guardarUbicacion(Ubicacion ubicacion) async {
    final datos = ubicacion.toMap();

    if (ubicacion.id.isEmpty) {
      await _client.from('ubicaciones').insert(datos);
      return;
    }

    await _client.from('ubicaciones').update(datos).eq('id', ubicacion.id);
  }

  Future<void> cambiarEstadoUbicacion({
    required String id,
    required bool activa,
  }) async {
    await _client.from('ubicaciones').update({
      'activa': activa,
    }).eq('id', id);
  }


  Future<List<StockItem>> obtenerStock() async {
    final response = await _client
        .from('vista_stock_detallado')
        .select()
        .gt('cantidad', 0)
        .order('almacen_nombre')
        .order('material_codigo')
        .order('ubicacion_codigo');

    return response
        .map<StockItem>((row) =>
            StockItem.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }


  Future<List<Equipo>> obtenerEquipos({bool soloActivos = false}) async {
    var query = _client.from('equipos').select();
    if (soloActivos) query = query.eq('activo', true);
    final response = await query
        .order('activo', ascending: false)
        .order('codigo');
    return response
        .map<Equipo>((row) => Equipo.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> guardarEquipo(Equipo equipo) async {
    final datos = equipo.toMap();
    if (equipo.id.isEmpty) {
      await _client.from('equipos').insert(datos);
    } else {
      await _client.from('equipos').update(datos).eq('id', equipo.id);
    }
  }

  Future<void> cambiarEstadoEquipo({
    required String id,
    required bool activo,
  }) async {
    await _client.from('equipos').update({'activo': activo}).eq('id', id);
  }

  Future<List<Proveedor>> obtenerProveedores({bool soloActivos = false}) async {
    var query = _client.from('proveedores').select(
      'id, codigo, razon_social, nombre_comercial, cuit, region_id, pais, '
      'contacto, email, telefono, observacion, activo, regiones(nombre, pais)',
    );
    if (soloActivos) query = query.eq('activo', true);
    final response = await query
        .order('activo', ascending: false)
        .order('razon_social');
    return response
        .map<Proveedor>((row) =>
            Proveedor.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> guardarProveedor(Proveedor proveedor) async {
    final datos = proveedor.toMap();
    if (proveedor.id.isEmpty) {
      await _client.from('proveedores').insert(datos);
    } else {
      await _client.from('proveedores').update(datos).eq('id', proveedor.id);
    }
  }

  Future<void> cambiarEstadoProveedor({
    required String id,
    required bool activo,
  }) async {
    await _client.from('proveedores').update({'activo': activo}).eq('id', id);
  }

  Future<List<RegionCompra>> obtenerRegiones({bool soloActivas = false}) async {
    var query = _client.from('regiones').select();
    if (soloActivas) query = query.eq('activa', true);
    final response = await query
        .order('activa', ascending: false)
        .order('pais')
        .order('nombre');
    return response
        .map<RegionCompra>((row) =>
            RegionCompra.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> guardarRegion(RegionCompra region) async {
    final datos = region.toMap();
    if (region.id.isEmpty) {
      await _client.from('regiones').insert(datos);
    } else {
      await _client.from('regiones').update(datos).eq('id', region.id);
    }
  }

  Future<void> cambiarEstadoRegion({
    required String id,
    required bool activa,
  }) async {
    await _client.from('regiones').update({'activa': activa}).eq('id', id);
  }

  Future<String> registrarRecepcion({
    required String materialId,
    required String almacenId,
    required String ubicacionId,
    required num cantidad,
    required num costoUnitario,
    required String moneda,
    String? proveedorId,
    String? regionId,
    String ordenCompra = '',
    String factura = '',
    DateTime? fechaCompra,
    String usuario = '',
    String observacion = '',
  }) async {
    final response = await _client.rpc(
      'registrar_recepcion',
      params: {
        'p_material_id': materialId,
        'p_almacen_id': almacenId,
        'p_ubicacion_id': ubicacionId,
        'p_cantidad': cantidad,
        'p_costo_unitario': costoUnitario,
        'p_moneda': moneda,
        'p_proveedor_id': proveedorId,
        'p_region_id': regionId,
        'p_orden_compra': ordenCompra.trim(),
        'p_factura': factura.trim(),
        'p_fecha_compra': fechaCompra?.toIso8601String().split('T').first,
        'p_usuario': usuario.trim(),
        'p_observacion': observacion.trim(),
      },
    );
    return response?.toString() ?? '';
  }

  Future<String> registrarTransferencia({
    required String materialId,
    required String almacenOrigenId,
    required String ubicacionOrigenId,
    required String almacenDestinoId,
    required String ubicacionDestinoId,
    required num cantidad,
    String usuario = '',
    String observacion = '',
  }) async {
    final response = await _client.rpc(
      'registrar_transferencia',
      params: {
        'p_material_id': materialId,
        'p_almacen_origen_id': almacenOrigenId,
        'p_ubicacion_origen_id': ubicacionOrigenId,
        'p_almacen_destino_id': almacenDestinoId,
        'p_ubicacion_destino_id': ubicacionDestinoId,
        'p_cantidad': cantidad,
        'p_usuario': usuario.trim(),
        'p_observacion': observacion.trim(),
      },
    );
    return response?.toString() ?? '';
  }


  Future<String> registrarSalidaConsumo({
    required String materialId,
    required String almacenOrigenId,
    required String ubicacionOrigenId,
    required num cantidad,
    required String destinoExterno,
    String? equipoId,
    String usuario = '',
    String observacion = '',
  }) async {
    final response = await _client.rpc(
      'registrar_salida_consumo',
      params: {
        'p_material_id': materialId,
        'p_almacen_origen_id': almacenOrigenId,
        'p_ubicacion_origen_id': ubicacionOrigenId,
        'p_cantidad': cantidad,
        'p_destino_externo': destinoExterno.trim(),
        'p_equipo_id': equipoId,
        'p_usuario': usuario.trim(),
        'p_observacion': observacion.trim(),
      },
    );
    return response?.toString() ?? '';
  }

  Future<String> registrarSalidaConsumoMultiple({
    required String almacenOrigenId,
    required List<Map<String, dynamic>> items,
    required String destinoExterno,
    String? equipoId,
    String usuario = '',
    String observacion = '',
  }) async {
    final response = await _client.rpc('registrar_salida_consumo_multiple', params: {
      'p_almacen_origen_id': almacenOrigenId,
      'p_items': items,
      'p_destino_externo': destinoExterno.trim(),
      'p_equipo_id': equipoId,
      'p_usuario': usuario.trim(),
      'p_observacion': observacion.trim(),
    });
    return response?.toString() ?? '';
  }

  /// Página filtrada en PostgreSQL: no descarga el historial completo.
  Future<PaginaMovimientos> obtenerPaginaMovimientos({
    required int pagina,
    required int tamanoPagina,
    String buscar = '',
    String almacenId = '',
    String proveedorId = '',
    String tipo = '',
    DateTime? desde,
    DateTime? hasta,
  }) async {
    if (pagina < 0 || tamanoPagina < 1) {
      throw ArgumentError('Página o tamaño de página inválidos');
    }
    var consulta = _client.from('vista_movimientos_detallados')
        .select('*');
    if (almacenId.isNotEmpty) {
      consulta = consulta.or('almacen_origen_id.eq.$almacenId,almacen_destino_id.eq.$almacenId');
    }
    if (proveedorId.isNotEmpty) consulta = consulta.eq('proveedor_id', proveedorId);
    if (tipo.isNotEmpty) consulta = consulta.eq('tipo', tipo);
    if (desde != null) {
      final inicio = DateTime(desde.year, desde.month, desde.day).toUtc();
      consulta = consulta.gte('fecha', inicio.toIso8601String());
    }
    if (hasta != null) {
      final finExclusivo = DateTime(hasta.year, hasta.month, hasta.day + 1).toUtc();
      consulta = consulta.lt('fecha', finExclusivo.toIso8601String());
    }
    // Limitar caracteres especiales evita alterar la sintaxis del filtro PostgREST.
    final termino = buscar.trim().replaceAll(RegExp(r'[^a-zA-Z0-9À-ÿ _-]'), ' ').trim();
    if (termino.isNotEmpty) {
      final patron = '*${termino.replaceAll(RegExp(r'\s+'), '*')}*';
      consulta = consulta.or([
        'material_codigo.ilike.$patron',
        'material_nombre.ilike.$patron',
        'usuario.ilike.$patron',
        'remito_numero.ilike.$patron',
        'factura.ilike.$patron',
        'orden_compra.ilike.$patron',
        'destino_externo.ilike.$patron',
      ].join(','));
    }
    final desdeFila = pagina * tamanoPagina;
    final respuesta = await consulta
        .order('fecha', ascending: false)
        .order('id', ascending: false)
        .range(desdeFila, desdeFila + tamanoPagina);
    final haySiguiente = respuesta.length > tamanoPagina;
    final filas = respuesta.take(tamanoPagina);
    return PaginaMovimientos(
      movimientos: filas.map<Movimiento>((fila) =>
          Movimiento.fromMap(Map<String, dynamic>.from(fila))).toList(),
      total: desdeFila + respuesta.length,
      haySiguiente: haySiguiente,
    );
  }

  Future<List<Movimiento>> obtenerMovimientos() async {
    final response = await _client
        .from('vista_movimientos_detallados')
        .select()
        .order('fecha', ascending: false);

    return response
        .map<Movimiento>((row) =>
            Movimiento.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<Documento>> obtenerDocumentos() async {
    final encabezados = await _client
        .from('vista_documentos')
        .select()
        .order('fecha', ascending: false);

    final itemsResponse = await _client
        .from('vista_documento_items')
        .select()
        .order('material_codigo');

    final itemsPorDocumento = <String, List<DocumentoItem>>{};
    for (final row in itemsResponse) {
      final map = Map<String, dynamic>.from(row);
      final documentoId = map['documento_id']?.toString() ?? '';
      itemsPorDocumento
          .putIfAbsent(documentoId, () => <DocumentoItem>[])
          .add(DocumentoItem.fromMap(map));
    }

    return encabezados.map<Documento>((row) {
      final map = Map<String, dynamic>.from(row);
      final id = map['id']?.toString() ?? '';
      return Documento.fromMap(map, itemsPorDocumento[id] ?? const []);
    }).toList();
  }

  Future<void> cambiarEstadoDocumento({
    required String id,
    required String estado,
  }) async {
    await _client.rpc(
      'cambiar_estado_documento',
      params: {'p_documento_id': id, 'p_estado': estado},
    );
  }

}

final supabaseService = SupabaseService();
/// Resultado paginado. El total es un mínimo conocido, no un conteo global.
class PaginaMovimientos {
  final List<Movimiento> movimientos;
  final int total;
  final bool haySiguiente;
  const PaginaMovimientos({required this.movimientos, required this.total, required this.haySiguiente});
}
