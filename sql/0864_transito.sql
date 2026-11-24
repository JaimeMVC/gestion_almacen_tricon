begin;
create table public.transitos_directos (
 id uuid primary key,
 empresa_id uuid not null references public.empresas(id),
 usuario_id uuid not null,
 solicitud jsonb not null,
 remito_id uuid references public.remitos(id) on delete restrict
);
alter table public.transitos_directos enable row level security;
revoke all on public.transitos_directos from public, anon, authenticated;
create function public.registrar_transito_directo(p_id uuid, p_datos jsonb)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
 e uuid := public.empresa_actual_id();
 a uuid := (p_datos->>'almacen_id')::uuid;
 m uuid := (p_datos->>'material_id')::uuid;
 p uuid := (p_datos->>'proveedor_id')::uuid;
 r uuid := (p_datos->>'region_id')::uuid;
 q numeric := (p_datos->>'cantidad')::numeric;
 c numeric := (p_datos->>'costo_unitario')::numeric;
 moneda text := p_datos->>'moneda';
 destino text := btrim(coalesce(p_datos->>'destino',''));
 responsable text := coalesce(p_datos->>'usuario','');
 obs text := '[TRANSITO DIRECTO] ' || coalesce(p_datos->>'observacion','');
 u uuid; rem uuid; anterior public.transitos_directos%rowtype;
begin
 if e is null or auth.uid() is null or not public.usuario_tiene_permiso('recepcionar') or not public.usuario_tiene_permiso('despachar') then raise exception 'Sin permiso para tránsito directo'; end if;
 if p_id is null or q is null or q <= 0 or q::text in ('NaN','Infinity','-Infinity') or c is null or c < 0 or c::text in ('NaN','Infinity','-Infinity') or moneda is null or moneda not in ('ARS','BRL','USD','BOB','EUR') or destino = '' then raise exception 'Datos de tránsito inválidos'; end if;
 insert into public.transitos_directos(id,empresa_id,usuario_id,solicitud) values(p_id,e,auth.uid(),p_datos) on conflict(id) do nothing;
 select * into anterior from public.transitos_directos where id=p_id for update;
 if anterior.empresa_id <> e or anterior.usuario_id <> auth.uid() or anterior.solicitud <> p_datos then raise exception 'Identificador de operación ya utilizado'; end if;
 if anterior.remito_id is not null then return anterior.remito_id; end if;
 if not exists(select 1 from public.almacenes where id=a and empresa_id=e and activo) or not exists(select 1 from public.materiales where id=m and empresa_id=e and activo) or not exists(select 1 from public.proveedores where id=p and empresa_id=e and activo) or (r is not null and not exists(select 1 from public.regiones where id=r and empresa_id=e and activa)) then raise exception 'Maestros inválidos o de otra empresa'; end if;
 insert into public.ubicaciones(almacen_id,codigo,descripcion,activa,observacion,empresa_id) values(a,'TRANSITO','Tránsito directo',true,'TRICON_TRANSITO_DIRECTO',e) on conflict(almacen_id,codigo) do nothing;
 select id into u from public.ubicaciones where almacen_id=a and codigo='TRANSITO' and empresa_id=e and activa and observacion='TRICON_TRANSITO_DIRECTO' for update;
 if u is null then raise exception 'Ubicación TRANSITO existente incompatible o inactiva'; end if;
 if exists(select 1 from public.stock where ubicacion_id=u and cantidad<>0) then raise exception 'La ubicación de tránsito contiene stock'; end if;
 insert into public.remitos(numero,tipo,almacen_origen_id,destino_externo,responsable,observacion,estado,emitido_at,empresa_id) values(public.siguiente_numero_remito_consumo(),'SALIDA_CONSUMO',a,destino,responsable,obs,'EMITIDO',now(),e) returning id into rem;
 insert into public.remito_items(remito_id,material_id,ubicacion_origen_id,cantidad,costo_unitario,moneda,empresa_id) values(rem,m,u,q,c,moneda,e);
 insert into public.movimientos(tipo,material_id,cantidad,almacen_destino_id,ubicacion_destino_id,proveedor_id,region_id,costo_unitario,moneda,orden_compra,factura,fecha_compra,usuario,observacion,remito_id,empresa_id) values('INGRESO',m,q,a,u,p,r,c,moneda,coalesce(p_datos->>'orden_compra',''),coalesce(p_datos->>'factura',''),(p_datos->>'fecha_compra')::date,responsable,obs,rem,e);
 insert into public.movimientos(tipo,material_id,cantidad,almacen_origen_id,ubicacion_origen_id,costo_unitario,moneda,remito_id,usuario,destino_externo,observacion,empresa_id) values('SALIDA_CONSUMO',m,q,a,u,c,moneda,rem,responsable,destino,obs,e);
 update public.transitos_directos set remito_id=rem where id=p_id;
 return rem;
end; $$;
revoke all on function public.registrar_transito_directo(uuid,jsonb) from public, anon;
grant execute on function public.registrar_transito_directo(uuid,jsonb) to authenticated;
commit;
