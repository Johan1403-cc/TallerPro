const state = { view:'dashboard', data:{}, catalogs:{}, search:'', reportQuery:'' };

// Permisos de interfaz. El backend repite estas reglas, por lo que ocultar
// opciones aquí es solo una mejora visual y no la única protección.
const CURRENT_USER = window.TALLERPRO_USER || { roles: [] };
let CURRENT_PERMISSIONS = new Set(
  (window.TALLERPRO_PERMISSIONS || []).map(p => String(p.codigo || p).toUpperCase())
);
const VIEW_PERMISSIONS = {
  dashboard:'DASHBOARD_CONSULTAR',
  clientes:'CLIENTES_CONSULTAR',
  vehiculos:'VEHICULOS_CONSULTAR',
  'admin-vehiculos':'CATALOGOS_CONSULTAR',
  citas:'CITAS_CONSULTAR',
  recepciones:'RECEPCIONES_CONSULTAR',
  diagnosticos:'DIAGNOSTICOS_CONSULTAR',
  cotizaciones:'COTIZACIONES_CONSULTAR',
  ordenes:'ORDENES_CONSULTAR',
  empleados:'EMPLEADOS_CONSULTAR',
  servicios:'SERVICIOS_CONSULTAR',
  inventario:'INVENTARIO_CONSULTAR',
  proveedores:'PROVEEDORES_CONSULTAR',
  compras:'COMPRAS_CONSULTAR',
  ventas:'VENTAS_CONSULTAR',
  garantias:'GARANTIAS_CONSULTAR',
  facturas:'FACTURAS_CONSULTAR',
  usuarios:'USUARIOS_CONSULTAR',
  roles:'ROLES_CONSULTAR',
  permisos:'PERMISOS_CONSULTAR',
  reportes:'REPORTES_CONSULTAR',
  configuracion:'CONFIGURACION_CONSULTAR'
};
function canAccessView(view){
  const required = VIEW_PERMISSIONS[view];
  return required ? CURRENT_PERMISSIONS.has(required) : false;
}
function applyMenuPermissions(){
  document.querySelectorAll('#nav [data-view]').forEach(a=>{
    if(!canAccessView(a.dataset.view)) a.remove();
  });
}

const resources = {
  vehiculosCatalogo:{title:'Administrar Vehículos',singular:'vehículo',endpoint:'vehiculos-catalogo',fields:[
    ['id_marca','Marca','select',true],['id_modelo','Modelo','select',true],
    ['id_tipo_combustible','Tipo de combustible','select',true],
    ['id_categoria_vehiculo','Categoría','select',true],['activo','Activo','select']
  ]},
  marcasAdmin:{title:'Marcas de vehículos',singular:'marca',endpoint:'marcas',fields:[
    ['nombre','Nombre','text',true],['activo','Activo','select']
  ]},
  modelosAdmin:{title:'Modelos de vehículos',singular:'modelo',endpoint:'modelos',fields:[
    ['id_marca','Marca','select',true],['nombre','Nombre','text',true],['activo','Activo','select']
  ]},
  tiposCombustibleAdmin:{title:'Tipos de combustible',singular:'tipo de combustible',endpoint:'tipos-combustible',fields:[
    ['nombre','Nombre','text',true],['activo','Activo','select']
  ]},
  categoriasVehiculoAdmin:{title:'Categorías de vehículos',singular:'categoría',endpoint:'categorias-vehiculo',fields:[
    ['nombre','Nombre','text',true],['activo','Activo','select']
  ]},
  clientes:{title:'Clientes',singular:'cliente',endpoint:'clientes',fields:[
    ['nombre','Nombre','text',true],['telefono','Teléfono','text'],['email','Correo','email'],
    ['identificacion','Identificación','text'],['tipo_cliente','Tipo cliente','select'],
    ['direccion','Dirección','text'],['activo','Activo','select']
  ]},
  vehiculos:{title:'Vehículos de Clientes',singular:'vehículo',endpoint:'vehiculos',fields:[
    ['id_cliente','Cliente','select',true],['id_vehiculo_catalogo','Vehículo del catálogo','select',true],['placa','Placa','text',true],['vin','VIN','text'],
    ['id_marca','Marca','select'],['id_modelo','Modelo','select'],['anio','Año','number'],
    ['id_tipo_combustible','Combustible','select'],
    ['id_categoria_vehiculo','Categoría','select'],['color','Color','text'],['cilindraje','Cilindraje','text'],
    ['kilometraje','Kilometraje','number'],['fecha_ingreso','Fecha de ingreso','datetime-local'],
    ['observaciones','Observaciones','textarea'],['activo','Activo','select']
  ]},
  empleados:{title:'Empleados',singular:'empleado',endpoint:'empleados',fields:[
    ['nombre','Nombre','text',true],['cargo','Cargo','text'],['identificacion','Identificación','text'],
    ['telefono','Teléfono','text'],['email','Correo','email'],['direccion','Dirección','text'],
    ['fecha_contratacion','Contratación','date'],['especialidad','Especialidad','text'],
    ['estado_laboral','Estado laboral','select'],['id_usuario','Usuario','select']
  ]},
  servicios:{title:'Servicios',singular:'servicio',endpoint:'servicios',fields:[
    ['nombre','Nombre','text',true],['precio_base','Precio base','number',true],
    ['codigo','Código','text'],
    ['tiempo_estimado_min','Tiempo estimado (min)','number'],['estado','Estado','select'],
    ['porcentaje_impuesto','Impuesto %','number']
  ]},
  proveedores:{title:'Proveedores',singular:'proveedor',endpoint:'proveedores',fields:[
    ['nombre_empresa','Razón social','text',true],['identificacion','Identificación','text'],
    ['telefono','Teléfono','text'],['email','Correo','email'],['direccion','Dirección','text'],
    ['contacto_principal','Contacto principal','text'],['condiciones_pago','Condiciones de pago','text'],
    ['estado','Estado','select']
  ]},
  inventario:{title:'Inventario',singular:'repuesto',endpoint:'inventario',fields:[
    ['id_categoria','Categoría','select'],['id_proveedor','Proveedor','select'],['nombre','Nombre','text',true],
    ['codigo_interno','Código interno','text'],['codigo_barras','Código barras','text'],['marca','Marca','text'],
    ['unidad_medida','Unidad','text'],['stock_actual','Existencia','number'],['precio_compra','Precio compra','number'],
    ['precio_venta','Precio venta','number',true],['porcentaje_impuesto','Impuesto %','number'],
    ['existencia_minima','Existencia mínima','number'],['existencia_maxima','Existencia máxima','number'],
    ['ubicacion_bodega','Ubicación','text'],['estado','Estado','select'],['tipo_producto','Tipo producto','select']
  ]},
  citas:{title:'Citas',singular:'cita',endpoint:'citas',fields:[
    ['id_cliente','Cliente','select',true],['id_vehiculo','Vehículo','select',true],['id_servicio','Servicio','select'],
    ['id_empleado','Empleado','select'],['fecha_hora','Fecha y hora','datetime-local',true],
    ['duracion_estimada_min','Duración (min)','number',true],['estado','Estado','select'],['observaciones','Observaciones','text']
  ]},
  recepciones:{title:'Recepciones',singular:'recepción',endpoint:'recepciones',fields:[
    ['numero_consecutivo','Consecutivo','number',true],['id_cliente','Cliente','select',true],['id_vehiculo','Vehículo','select',true],
    ['id_empleado_recibe','Empleado que recibe','select'],['kilometraje_actual','Kilometraje','number'],
    ['nivel_combustible','Nivel combustible','select'],['motivo_visita','Motivo','text'],['descripcion_problema','Problema','textarea'],
    ['accesorios_entregados','Accesorios entregados','text'],['danos_visibles','Daños visibles','text'],
    ['fecha_estimada_entrega','Entrega estimada','datetime-local'],['observaciones','Observaciones','textarea']
  ]},
  diagnosticos:{title:'Diagnósticos',singular:'diagnóstico',endpoint:'diagnosticos',fields:[
    ['id_recepcion','Recepción','select',true],['id_empleado','Mecánico','select',true],
    ['problemas_encontrados','Problemas encontrados','textarea'],['pruebas_realizadas','Pruebas realizadas','textarea'],
    ['posibles_causas','Posibles causas','textarea'],['recomendaciones','Recomendaciones','textarea'],
    ['mano_obra_estimada','Mano de obra estimada','number'],['tiempo_estimado_horas','Horas estimadas','number'],
    ['costo_estimado','Costo estimado','number'],['estado','Estado','select']
  ]},
  cotizaciones:{title:'Cotizaciones',singular:'cotización',endpoint:'cotizaciones',fields:[
    ['id_diagnostico','Diagnóstico','select',true],['id_cliente','Cliente','select',true],['id_vehiculo','Vehículo','select',true],
    ['fecha_vencimiento','Vencimiento','datetime-local'],['subtotal','Subtotal','number'],
    ['impuestos','Impuestos','number'],['descuentos','Descuentos','number'],
    ['total','Total','number',true],['condiciones','Condiciones','textarea'],['estado','Estado','select']
  ]},
  ordenes:{title:'Órdenes de trabajo',singular:'orden',endpoint:'ordenes',fields:[
    ['id_vehiculo','Vehículo','select',true],['id_empleado','Responsable','select'],
    ['estado','Estado','select',true]
  ]},
  compras:{title:'Compras',singular:'compra',endpoint:'compras',fields:[
    ['id_proveedor','Proveedor','select',true],['numero_factura_proveedor','Factura proveedor','text'],
    ['subtotal','Subtotal','number'],['impuestos','Impuestos','number'],['descuentos','Descuentos','number'],
    ['total','Total','number',true],['forma_pago','Forma de pago','select',true],
    ['estado','Estado','select',true],['id_usuario','Usuario','select',true]
  ]},
  ventas:{title:'Ventas',singular:'venta',endpoint:'ventas',fields:[
    ['id_cliente','Cliente','select'],['id_empleado','Vendedor','select',true]
  ]},
  facturas:{title:'Facturación',singular:'factura',endpoint:'facturas',fields:[
    ['numero_consecutivo','Consecutivo','number',true],['tipo_factura','Tipo','select',true],
    ['id_orden','Orden','number'],['id_venta','Venta','number'],['id_cliente','Cliente','select'],
    ['subtotal','Subtotal','number'],['impuestos','Impuestos','number'],['descuentos','Descuentos','number'],
    ['total','Total','number',true],['forma_pago','Forma de pago','select',true],['estado','Estado','select',true],
    ['id_usuario_emite','Usuario emite','select',true]
  ]},
  usuarios:{title:'Usuarios',singular:'usuario',endpoint:'usuarios',fields:[
    ['nombre_usuario','Usuario','text',true],['email','Correo','email',true],
    ['password','Contraseña','password'],['activo','Activo','select'],
    ['role_ids','Roles','multiselect',true]
  ]},
  roles:{title:'Roles',singular:'rol',endpoint:'roles',fields:[
    ['nombre','Nombre','text',true],['descripcion','Descripción','textarea'],
    ['activo','Activo','select']
  ]},
  permisos:{title:'Permisos',singular:'permiso',endpoint:'permisos',fields:[
    ['codigo','Código','text',true],['nombre','Nombre','text',true],
    ['modulo','Módulo','text',true],['descripcion','Descripción','textarea'],
    ['role_ids','Roles asignados','multiselect']
  ]},
  garantias:{title:'Garantías',singular:'garantía',endpoint:'garantias',fields:[
    ['tipo_garantia','Tipo','select',true],['id_orden','Orden','number'],['id_venta','Venta','number'],
    ['descripcion_cubierto','Qué cubre','textarea'],['fecha_inicio','Inicio','date',true],
    ['fecha_vencimiento','Vencimiento','date',true],['condiciones','Condiciones','textarea'],
    ['estado','Estado','select',true],['observaciones','Observaciones','textarea']
  ]}
};

const options = {
  citas:{estado:['PROGRAMADA','CONFIRMADA','ATENDIDA','CANCELADA','REPROGRAMADA','AUSENTE']},
  recepciones:{nivel_combustible:['VACIO','1/4','1/2','3/4','LLENO']},
  diagnosticos:{estado:['PENDIENTE','EN_REVISION','FINALIZADO','APROBADO','RECHAZADO']},
  cotizaciones:{estado:['ENVIADA','APROBADA','APROBADA_PARCIAL','RECHAZADA','MODIFICADA','CONVERTIDA']},
  ordenes:{estado:['REGISTRADA','EN_DIAGNOSTICO','ESPERANDO_APROBACION','APROBADA','EN_REPARACION','EN_ESPERA_REPUESTOS','SUSPENDIDA','LISTA','FINALIZADA','FACTURADA','ENTREGADA','CANCELADA']},
  compras:{forma_pago:['CONTADO','CREDITO','PARCIAL'],estado:['REGISTRADA','CONFIRMADA','ANULADA']},
  facturas:{tipo_factura:['ORDEN','VENTA','SERVICIO','MIXTA'],forma_pago:['EFECTIVO','TARJETA','TRANSFERENCIA','SINPE','CREDITO','COMBINADO'],estado:['PENDIENTE','PAGADA','PARCIAL','ANULADA','REEMBOLSADA']},
  garantias:{tipo_garantia:['SERVICIO','MANO_OBRA','REPUESTO','PRODUCTO'],estado:['VIGENTE','VENCIDA','RECLAMADA','ANULADA']}
};

const $=s=>document.querySelector(s);
const esc=v=>String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));
const money=v=>'₡'+Number(v||0).toLocaleString('es-CR',{minimumFractionDigits:2});
function toast(msg,type='ok'){let e=$('.toast');if(e)e.remove();e=document.createElement('div');e.className='toast '+type;e.textContent=msg;document.body.appendChild(e);setTimeout(()=>e.remove(),3000);}
async function api(url,opts={}){const r=await fetch('/api/'+url,{headers:{'Content-Type':'application/json',...(opts.headers||{})},...opts});const text=await r.text();let data={};try{data=text?JSON.parse(text):{}}catch{data={error:text}}if(r.status===401){window.location.href='/login';throw new Error('Sesión expirada');}if(!r.ok)throw new Error(data.error||'Error de servidor');return data;}
async function optionalApi(url, fallback=[]){
  try{return await api(url);}catch(e){
    if(/permiso/i.test(e.message)) return fallback;
    throw e;
  }
}
async function loadCatalogs(){
  const permData=await api('auth/permissions');
  CURRENT_PERMISSIONS=new Set((permData.permissions||[]).map(p=>String(p.codigo||'').toUpperCase()));
  applyMenuPermissions();
  state.catalogs=await optionalApi('catalogos',{});
  state.catalogs.vehiculosCatalogo=await optionalApi('vehiculos-catalogo');
  state.catalogs.categorias=await optionalApi('categorias');
  state.catalogs.roles=await optionalApi('roles');
  state.catalogs.categoriasServicio=await optionalApi('categorias-servicio');
  state.data.recepciones=await optionalApi('recepciones');
  state.data.diagnosticos=await optionalApi('diagnosticos');
}
function labelFor(field){return field[1];}
function selectOptions(name,view,value){
  if(name==='id_vehiculo_catalogo')return (state.catalogs.vehiculosCatalogo||[]).map(x=>{
    const label=[x.marca,x.modelo,x.tipo_vehiculo,x.tipo_combustible,x.categoria_vehiculo].filter(Boolean).join(' · ');
    return `<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(label)}</option>`;
  }).join('');
  if(name==='id_cliente')return (state.catalogs.clientes||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_vehiculo')return (state.catalogs.vehiculos||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.placa)} - ${esc(x.marca||'')} ${esc(x.modelo||'')}</option>`).join('');
  if(name==='id_marca')return (state.catalogs.marcas||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_modelo')return (state.catalogs.modelos||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_tipo_vehiculo')return (state.catalogs.tiposVehiculo||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_tipo_combustible')return (state.catalogs.tiposCombustible||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_categoria_vehiculo')return (state.catalogs.categoriasVehiculo||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_empleado'||name==='id_empleado_recibe')return (state.catalogs.empleados||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}${x.cargo?' — '+esc(x.cargo):''}</option>`).join('');
  if(name==='id_categoria_servicio')return (state.catalogs.categoriasServicio||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_servicio')return (state.catalogs.servicios||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_proveedor')return (state.catalogs.proveedores||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre_empresa)}</option>`).join('');
  if(name==='id_categoria')return (state.catalogs.categorias||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre)}</option>`).join('');
  if(name==='id_recepcion')return (state.data.recepciones||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>#${x.numero_consecutivo} — ${esc(x.placa||'')}</option>`).join('');
  if(name==='id_diagnostico')return (state.data.diagnosticos||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>#${x.id} — recepción ${x.numero_consecutivo||''}</option>`).join('');
  if(name==='id_usuario'||name==='id_usuario_emite')return (state.catalogs.usuarios||[]).map(x=>`<option value="${x.id}" ${String(x.id)===String(value)?'selected':''}>${esc(x.nombre_usuario)}</option>`).join('');
  if(name==='role_ids'){
    const selected=new Set(String(value||'').split(',').map(x=>x.trim()).filter(Boolean));
    return (state.catalogs.roles||[]).filter(x=>x.activo!==false&&x.activo!==0).map(x=>`<option value="${x.id}" ${selected.has(String(x.id))?'selected':''}>${esc(x.nombre)}</option>`).join('');
  }
  let fallback = options[view]?.[name]||[];
  if(name==='tipo_cliente') fallback=['FISICO','JURIDICO'];
  if(name==='estado_laboral') fallback=['ACTIVO','INACTIVO','VACACIONES'];
  if(name==='estado' && view==='servicios') fallback=['ACTIVO','INACTIVO'];
  if(name==='estado' && view==='proveedores') fallback=['ACTIVO','INACTIVO'];
  if(name==='estado' && view==='inventario') fallback=['ACTIVO','INACTIVO'];
  if(name==='tipo_producto') fallback=['REPUESTO','HERRAMIENTA','ACCESORIO','LUBRICANTE','OTRO'];
  if(name==='activo') return [['1','Sí'],['0','No']].map(([v,l])=>`<option value="${v}" ${String(value??'1')===v?'selected':''}>${l}</option>`).join('');
  return fallback.map(x=>`<option value="${esc(x)}" ${x===value?'selected':''}>${esc(x)}</option>`).join('');
}
function fieldHtml(view,f,value=''){
 const [name,label,type,req]=f;
 const required=req===true||req==='required'?'required':'';
 if(view==='inventario'&&name==='stock_actual')return `<div class="field"><label>${esc(label)}</label><input name="${name}" type="number" value="${esc(value||0)}" readonly><small>La existencia cambia únicamente mediante movimientos de inventario.</small></div>`;
 if(view==='permisos'&&name==='codigo'&&state.editing?.id){
   return `<div class="field"><label>${esc(label)}</label><input name="${name}" type="text" value="${esc(value)}" readonly><small>El código técnico no puede cambiarse porque controla la autorización del backend.</small></div>`;
 }
 if(type==='password'){
   const isEdit=Boolean(state.editing?.id);
   return `<div class="field full"><label>${esc(label)}${isEdit?' (opcional)':''}</label><input name="${name}" type="password" autocomplete="new-password" minlength="8" ${isEdit?'': 'required'} placeholder="${isEdit?'Déjala vacía para conservar la actual':'Mínimo 8 caracteres'}"><small>Debe incluir mayúscula, minúscula, número y carácter especial.</small></div>`;
 }
 if(type==='multiselect'){
   return `<div class="field full"><label>${esc(label)}</label><select name="${name}" multiple size="${Math.min(7,Math.max(4,(state.catalogs.roles||[]).length))}" ${required}>${selectOptions(name,view,value)}</select><small>Puedes seleccionar uno o varios roles. Los datos se cargan directamente desde ROLES en la base de datos.</small></div>`;
 }
 if(type==='select')return `<div class="field"><label>${esc(label)}</label><select name="${name}" ${required}><option value="">-- Seleccione --</option>${selectOptions(name,view,value)}</select></div>`;
 if(type==='textarea')return `<div class="field full"><label>${esc(label)}</label><textarea name="${name}" ${required}>${esc(value)}</textarea></div>`;
 return `<div class="field"><label>${esc(label)}</label><input name="${name}" type="${type}" value="${esc(formatInput(type,value))}" ${required}></div>`;
}
function formatInput(type,v){if(!v)return '';if((type==='date'||type==='datetime-local')&&typeof v==='string')return v.substring(0,type==='date'?10:16).replace(' ','T');return v;}
function status(v){if(!v)return '';let c=/FINAL|PAGADA|APROBADA|ENTREGADA|LISTA|CONFIRMADA|VIGENTE/i.test(v)?'b-green':/CANCEL|RECHAZ|ANUL|VENCIDA/i.test(v)?'b-red':'b-yellow';return `<span class="badge ${c}">${esc(v)}</span>`;}
// Mapa global: cada columna que guarda un ID de otra tabla se resuelve contra el
// nombre legible que el backend ya trae mediante JOIN (misma clave en todas las
// vistas: citas, vehiculos, recepciones, diagnosticos, cotizaciones, compras,
// facturas, usuarios, inventario, etc.)
const FK_DISPLAY_MAP={
  id_marca:'marca',
  id_modelo:'modelo',
  id_tipo_vehiculo:'tipo_vehiculo',
  id_tipo_combustible:'tipo_combustible',
  id_categoria_vehiculo:'categoria_vehiculo',
  id_vehiculo_catalogo:'vehiculo_catalogo',
  id_cliente:'cliente',
  id_vehiculo:'placa',
  id_servicio:'servicio',
  id_proveedor:'proveedor',
  id_categoria:'categoria',
  id_categoria_servicio:'categoria',
  id_empleado:'empleado',
  id_empleado_recibe:'empleado',
  id_usuario:'usuario',
  id_usuario_emite:'usuario_emite',
  id_usuario_decision:'usuario_decision'
};
function displayValue(k,row){
  if(k==='id_recepcion'&&row.numero_consecutivo!=null&&row.numero_consecutivo!=='')return `Recepción #${row.numero_consecutivo}`;
  if(k==='id_diagnostico'&&row.recepcion_consecutivo!=null&&row.recepcion_consecutivo!=='')return `Diagnóstico (Recepción #${row.recepcion_consecutivo})`;
  const mappedKey=FK_DISPLAY_MAP[k];
  if(mappedKey&&row[mappedKey]!=null&&row[mappedKey]!=='')return row[mappedKey];
  return row[k];
}
function tableFor(view,rows){
 if(view==='usuarios'){
   const headers=['Usuario','Correo','Activo','Roles','Intentos fallidos','Bloqueado hasta'];
   return `<div class="table-wrap"><table class="data-table"><thead><tr>${headers.map(x=>`<th>${esc(x)}</th>`).join('')}<th>Acciones</th></tr></thead><tbody>${rows.map(row=>`<tr>
     <td>${esc(row.nombre_usuario)}</td><td>${esc(row.email)}</td><td>${row.activo?'Sí':'No'}</td>
     <td>${esc(row.roles||'Sin rol')}</td><td>${esc(row.intentos_fallidos||0)}</td><td>${esc(row.bloqueado_hasta?new Date(row.bloqueado_hasta).toLocaleString('es-CR'):'—')}</td>
     <td class="actions"><button class="icon-btn" data-action="view" data-id="${row.id}">Ver</button><button class="icon-btn" data-action="edit" data-id="${row.id}">Editar</button><button class="icon-btn" data-action="delete" data-id="${row.id}">Desactivar</button></td>
   </tr>`).join('')}</tbody></table></div>`;
 }
 if(view==='roles'){
   const headers=['Nombre','Descripción','Activo','Usuarios','Permisos'];
   return `<div class="table-wrap"><table class="data-table"><thead><tr>${headers.map(x=>`<th>${esc(x)}</th>`).join('')}<th>Acciones</th></tr></thead><tbody>${rows.map(row=>`<tr>
     <td>${esc(row.nombre)}</td><td>${esc(row.descripcion||'')}</td><td>${row.activo?'Sí':'No'}</td><td>${esc(row.usuarios||0)}</td><td>${esc(row.permisos||0)}</td>
     <td class="actions"><button class="icon-btn" data-action="role-permissions" data-id="${row.id}">Permisos</button><button class="icon-btn" data-action="edit" data-id="${row.id}">Editar</button><button class="icon-btn" data-action="delete" data-id="${row.id}">Eliminar</button></td>
   </tr>`).join('')}</tbody></table></div>`;
 }
 if(view==='permisos'){
   const headers=['Código','Nombre','Módulo','Descripción','Roles'];
   return `<div class="table-wrap"><table class="data-table"><thead><tr>${headers.map(x=>`<th>${esc(x)}</th>`).join('')}<th>Acciones</th></tr></thead><tbody>${rows.map(row=>`<tr>
     <td>${esc(row.codigo)}</td><td>${esc(row.nombre)}</td><td>${esc(row.modulo||'')}</td><td>${esc(row.descripcion||'')}</td><td>${esc(row.roles||'Sin asignar')}</td>
     <td class="actions"><button class="icon-btn" data-action="edit" data-id="${row.id}">Editar</button><button class="icon-btn" data-action="delete" data-id="${row.id}">Eliminar</button></td>
   </tr>`).join('')}</tbody></table></div>`;
 }
 const r=resources[view], cols=r.fields.map(f=>f[0]);const headers=r.fields.map(f=>f[1]);
 return `<div class="table-wrap"><table class="data-table"><thead><tr>${headers.map(esc).map(x=>`<th>${x}</th>`).join('')}<th>Acciones</th></tr></thead><tbody>${rows.map((row,i)=>`<tr>${cols.map(k=>{const display=displayValue(k,row);return `<td>${k==='estado'?status(display):esc(k==='precio_base'?money(display):k==='precio_venta'?money(display):display)}</td>`}).join('')}<td class="actions"><button class="icon-btn" data-action="view" data-id="${row.id}">Ver</button><button class="icon-btn" data-action="edit" data-id="${row.id}">Editar</button><button class="icon-btn" data-action="delete" data-id="${row.id}">Eliminar</button></td></tr>`).join('')}</tbody></table></div>`;
}
function detailHtml(view,row){
 const normalizedView=view==='role'?'roles':view==='usuario_roles'?'usuarios':view;
 if(normalizedView==='usuarios'){
   return `<div class="detail-list">
     <div><small>Usuario</small><b>${esc(row.nombre_usuario)}</b></div>
     <div><small>Correo</small><b>${esc(row.email)}</b></div>
     <div><small>Activo</small><b>${row.activo?'Sí':'No'}</b></div>
     <div><small>Roles</small><b>${esc(row.roles||'Sin rol')}</b></div>
     <div><small>Último acceso</small><b>${esc(row.ultimo_acceso?new Date(row.ultimo_acceso).toLocaleString('es-CR'):'—')}</b></div>
     <div><small>Intentos fallidos</small><b>${esc(row.intentos_fallidos||0)}</b></div>
   </div>`;
 }
 const r=resources[normalizedView];
 if(!r)return '<div class="detail-list">'+Object.entries(row).map(([k,v])=>`<div><small>${esc(k)}</small><b>${esc(v)}</b></div>`).join('')+'</div>';
 return '<div class="detail-list">'+r.fields.filter(f=>f[2]!=='password').map(f=>{
   const [name,label]=f;
   let val=displayValue(name,row);
   if(name==='role_ids') val=row.roles||'Sin rol';
   if(name==='precio_base'||name==='precio_venta')val=money(val);
   if(name==='estado')return `<div><small>${esc(label)}</small><b>${status(val)}</b></div>`;
   return `<div><small>${esc(label)}</small><b>${esc(val)}</b></div>`;
 }).join('')+'</div>';
}
async function findRow(view,id){
 const normalizedView=view==='role'?'roles':view==='usuario_roles'?'usuarios':view;
 const r=resources[normalizedView];
 let rows=state.data[view];
 if(!rows||!rows.length){rows=await api(r.endpoint);state.data[view]=rows;}
 let row=rows.find(x=>String(x.id)===String(id));
 if(!row){rows=await api(r.endpoint);state.data[view]=rows;row=rows.find(x=>String(x.id)===String(id));}
 return row||await api(`${r.endpoint}/${id}`);
}
function head(title,desc,button=true){return `<div class="page-head"><div><h1>${title}</h1><p>${desc}</p></div>${button?`<button class="btn primary" data-action="new">+ Nuevo ${resources[state.view]?.singular||'registro'}</button>`:''}</div>`;}
async function renderDashboard(){
 const d=await api('dashboard'),s=d.stats||{};
 const card=(key,label,icon,fmt=v=>v)=>s[key]===undefined?'':`<div class="stat"><div><small>${label}</small><h3>${fmt(s[key])}</h3></div><div class="icon"><i class="${icon}"></i></div></div>`;
 return head('Dashboard','Información visible según los permisos del usuario.',false)+
 `<div class="stats">
 ${card('vehiculos','Vehículos','fa-solid fa-car')}
 ${card('ordenes','Órdenes activas','fa-solid fa-screwdriver-wrench')}
 ${card('diagnosticos','Diagnósticos pendientes','fa-solid fa-stethoscope')}
 ${card('cotizaciones','Cotizaciones pendientes','fa-solid fa-file-invoice-dollar')}
 ${card('citas_hoy','Citas de hoy','fa-solid fa-calendar-check')}
 ${card('inventario_bajo','Stock mínimo','fa-solid fa-boxes-stacked')}
 ${card('por_cobrar','Por cobrar','fa-solid fa-file-invoice',money)}
 ${card('ventas_hoy','Ventas hoy','fa-solid fa-cash-register',money)}
 ${card('ingresos_mes','Ingresos del mes','fa-solid fa-chart-line',money)}
 </div>
 ${d.recientes?.length?`<div class="card"><div class="card-head"><h3>Órdenes recientes</h3></div>${table(['Orden','Estado','Fecha','Placa','Cliente'],d.recientes.map(x=>[x.id,status(x.estado),x.fecha_ingreso,x.placa,x.cliente]))}</div>`:''}`;
}
async function renderResource(view){
 const normalizedView = view === 'role' ? 'roles' : view === 'usuario_roles' ? 'usuarios' : view;
 const r=resources[normalizedView];
 if(!r || !r.endpoint) throw new Error(`No existe configuración para el módulo "${view}".`);
 let rows=await api(r.endpoint);state.data[view]=rows;
 const q=state.search.toLowerCase();if(q)rows=rows.filter(x=>JSON.stringify(x).toLowerCase().includes(q));
 return head(r.title,desc(view))+`<div class="toolbar"><div class="search"><i class="fa-solid fa-magnifying-glass"></i><input id="searchInput" value="${esc(state.search)}" placeholder="Buscar..."></div><button class="filter" data-action="refresh">Actualizar</button></div>${rows.length?tableFor(view,rows):`<div class="card"><div class="empty-state"><h3>No hay ${r.title.toLowerCase()} registrados</h3><p>Usa el botón Nuevo para comenzar.</p></div></div>`}`;
}
function desc(v){return ({clientes:'Clientes del taller y sus datos de contacto.',vehiculos:'Vehículos de Clientes: unidades asociadas a clientes y basadas en el catálogo administrativo.',empleados:'Personal y responsables del taller.',servicios:'Catálogo de servicios y mano de obra.',proveedores:'Proveedores de repuestos e insumos.',inventario:'Existencias y precios de repuestos.',citas:'Agenda de atención y mantenimiento.',recepciones:'Ingreso y condición inicial del vehículo.',diagnosticos:'Evaluación técnica y hallazgos.',cotizaciones:'Presupuestos derivados de diagnósticos.',ordenes:'Ciclo completo de reparación.',compras:'Compras y entradas de inventario.',ventas:'Ventas de repuestos.',facturas:'Facturación, pagos y estados.',garantias:'Garantías y seguimiento.',usuarios:'Usuarios del sistema, correo, estado y roles.',roles:'Administración de roles y sus permisos.',permisos:'Catálogo de permisos almacenado en la base de datos.'}[v]||'Gestión del taller.');}
async function renderAdminVehiculos(){
  const catalogRows=await api('vehiculos-catalogo');
  const marcas=await api('marcas');
  const modelos=await api('modelos');
  const combustibles=await api('tipos-combustible');
  const categorias=await api('categorias-vehiculo');
  state.data.vehiculosCatalogo=catalogRows;
  state.data.marcasAdmin=marcas;
  state.data.modelosAdmin=modelos;
  state.data.tiposCombustibleAdmin=combustibles;
  state.data.categoriasVehiculoAdmin=categorias;

  const catalogTable=adminTableFor('vehiculosCatalogo',catalogRows);
  const mini=(resource,rows)=>`
    <div class="card admin-mini-card">
      <div class="card-head"><div><h3>${esc(resource.title)}</h3><p>Catálogo general independiente de los clientes.</p></div>
      <button class="btn primary" data-admin-action data-action="new" data-resource="${resource===resources.marcasAdmin?'marcasAdmin':resource===resources.modelosAdmin?'modelosAdmin':resource===resources.tiposCombustibleAdmin?'tiposCombustibleAdmin':'categoriasVehiculoAdmin'}">+ Nuevo</button></div>
      ${rows.length?adminTableFor(resource===resources.marcasAdmin?'marcasAdmin':resource===resources.modelosAdmin?'modelosAdmin':resource===resources.tiposCombustibleAdmin?'tiposCombustibleAdmin':'categoriasVehiculoAdmin',rows):empty('Sin registros')}
    </div>`;

  return `
    <div class="page-head">
      <div><h1>Administrar Vehículos</h1><p>Catálogo maestro de vehículos, marcas, modelos, combustibles y categorías. Estos registros no pertenecen a clientes.</p></div>
      <button class="btn primary" data-admin-action data-action="new" data-resource="vehiculosCatalogo">+ Nuevo vehículo</button>
    </div>
    <div class="card">
      <div class="card-head"><div><h3>Vehículos del catálogo</h3><p>Estos datos alimentan la selección de la vista “Vehículos de Clientes”.</p></div></div>
      ${catalogRows.length?catalogTable:empty('No hay vehículos en el catálogo')}
    </div>
    <div class="admin-grid">
      ${mini(resources.marcasAdmin,marcas)}
      ${mini(resources.modelosAdmin,modelos)}
      ${mini(resources.tiposCombustibleAdmin,combustibles)}
      ${mini(resources.categoriasVehiculoAdmin,categorias)}
    </div>`;
}

async function openRolePermissions(id){
  const data=await api(`permisos/rol/${id}`);
  const groups={};
  (data.permisos||[]).forEach(p=>{const key=p.modulo||'OTROS';(groups[key] ||= []).push(p);});
  state.rolePermissionEditing={id,rol:data.rol};
  $('#modalTitle').textContent=`Permisos del rol: ${data.rol.nombre}`;
  $('#modalBody').innerHTML=`<form id="rolePermissionsForm"><p class="permission-help">Marca o desmarca los permisos que tendrá este rol. Los cambios se guardan en ROL_PERMISO.</p>
    <div class="permission-groups">${Object.entries(groups).map(([module,items])=>`<section class="permission-group"><h3>${esc(module)}</h3>
      ${items.map(p=>`<label class="permission-check"><input type="checkbox" name="id_permisos" value="${p.id}" ${p.asignado?'checked':''}><span><b>${esc(p.nombre)}</b><small>${esc(p.codigo)}</small></span></label>`).join('')}
    </section>`).join('')}</div></form>`;
  const saveButton=document.querySelector('#modal [data-action]');
  if(saveButton)saveButton.dataset.action='save-role-permissions';
  $('#modal').classList.add('show');
}

async function saveRolePermissions(){
  const form=$('#rolePermissionsForm');
  if(!form||!state.rolePermissionEditing)throw new Error('No hay un rol seleccionado.');
  const id_permisos=new FormData(form).getAll('id_permisos').map(Number);
  await api(`permisos/rol/${state.rolePermissionEditing.id}`,{method:'PUT',body:JSON.stringify({id_permisos})});
  state.catalogs.roles=await api('roles');
  $('#modal').classList.remove('show');
  toast('Permisos del rol actualizados');
  state.rolePermissionEditing=null;
  render();
}

async function renderSpecial(view){
 if(view==='admin-vehiculos')return renderAdminVehiculos();
 if(view==='reportes'){
   const d=await api(`reportes${state.reportQuery?'?'+state.reportQuery:''}`);
   const section=(title,headers,rows)=>`<div class="card report-section"><h3>${esc(title)}</h3>${rows?.length?table(headers,rows):empty('Sin datos')}</div>`;
   const bars=(title,items,labelKey,valueKey)=>`<div class="card report-chart"><h3>${esc(title)}</h3>${barChart(items,labelKey,valueKey)}</div>`;
   return head('Reportes','Reportes operativos obtenidos directamente de SQL Server.',false)+
     `<div class="report-filters"><label>Desde <input id="reportDesde" type="date"></label><label>Hasta <input id="reportHasta" type="date"></label><button class="btn secondary" data-action="report-filter">Aplicar filtros</button></div>`+
     `<div class="grid">${bars('Gráfico: ventas por período',d.ventasPeriodo,'periodo','total')}${bars('Gráfico: servicios más solicitados',d.serviciosTop,'nombre','cantidad')}${bars('Gráfico: órdenes por estado',d.ordenesEstado,'estado','cantidad')}</div>`+
     section('Trabajos realizados por período',['Período','Trabajos'],d.trabajosPeriodo.map(x=>[x.periodo,x.trabajos]))+
     section('Trabajos por mecánico',['Mecánico','Trabajos','Horas'],d.trabajosMecanico.map(x=>[x.mecanico,x.trabajos,Number(x.horas||0).toFixed(2)]))+
     section('Horas trabajadas por empleado',['Empleado','Horas','Costo'],d.horasEmpleado.map(x=>[x.empleado,Number(x.horas||0).toFixed(2),money(x.costo_mano_obra)]))+
     section('Vehículos por marca y modelo',['Marca','Modelo','Cantidad'],d.vehiculosMarcaModelo.map(x=>[x.marca,x.modelo,x.cantidad]))+
     section('Clientes con más visitas',['Cliente','Visitas'],d.clientesVisitas.map(x=>[x.nombre,x.visitas]))+
     section('Clientes con mayor facturación',['Cliente','Facturación'],d.clientesFacturacion.map(x=>[x.nombre,money(x.facturacion)]))+
     section('Ventas por vendedor',['Vendedor','Ventas','Facturación'],d.ventasVendedor.map(x=>[x.vendedor,x.ventas,money(x.facturacion)]))+
     section('Ventas por categoría',['Categoría','Cantidad','Total'],d.ventasCategoria.map(x=>[x.categoria,x.cantidad,money(x.total)]))+
     section('Productos más vendidos',['Producto','Cantidad','Total'],d.productosVendidos.map(x=>[x.nombre,x.cantidad,money(x.total)]))+
     section('Productos con poca existencia',['Producto','Existencia','Mínimo','Máximo'],d.bajoStock.map(x=>[x.nombre,x.stock_actual,x.existencia_minima,x.existencia_maxima]))+
     section('Productos sin movimiento',['Producto','Existencia','Último movimiento'],d.sinMovimiento.map(x=>[x.nombre,x.stock_actual,x.ultimo_movimiento||'Sin movimientos']))+
     section('Compras por proveedor',['Proveedor','Compras','Total'],d.comprasProveedor.map(x=>[x.proveedor,x.compras,money(x.total)]))+
     section('Ingresos por servicios',['Servicio','Cantidad','Ingreso'],d.ingresosServicios.map(x=>[x.nombre,x.cantidad,money(x.ingreso)]))+
     section('Ingresos por productos',['Producto','Cantidad','Ingreso'],d.ingresosProductos.map(x=>[x.nombre,x.cantidad,money(x.ingreso)]))+
     section('Facturas pendientes',['Factura','Cliente','Total','Estado','Saldo'],d.facturasPendientes.map(x=>[x.numero_consecutivo,x.cliente||'',money(x.total),status(x.estado),money(x.saldo)]))+
     section('Utilidad estimada por producto',['Producto','Unidades','Venta','Costo','Utilidad'],d.utilidadProductos.map(x=>[x.nombre,x.unidades,money(x.venta),money(x.costo),money(x.utilidad)]))+
     section('Utilidad/resumen por orden',['Orden','Total'],d.utilidadOrdenes.map(x=>[x.id_orden,money(x.total_orden)]))+
     section('Situación de órdenes',['Pendientes','Atrasadas','Finalizadas'],[[d.ordenesSituacion.pendientes||0,d.ordenesSituacion.atrasadas||0,d.ordenesSituacion.finalizadas||0]]);
 }
 if(view==='configuracion'){const rows=await api('configuracion');return head('Configuración','Parámetros generales guardados en CONFIGURACION_GENERAL.',false)+`<div class="form-card"><form id="configForm"><div class="form-grid">${rows.map(x=>`<div class="field"><label>${esc(x.clave)}</label><input name="${esc(x.clave)}" value="${esc(x.valor||'')}"><small>${esc(x.descripcion||'')}</small></div>`).join('')}</div><div class="modal-actions"><button class="btn primary">Guardar configuración</button></div></form></div>`;}
 if(view==='ordenes'){return renderResource('ordenes');}
 return renderResource(view);
}
function adminTableFor(resource,rows){
  return tableFor(resource,rows).replace(/data-action="(view|edit|delete)"/g, 'data-admin-action data-action="$1" data-resource="'+resource+'"');
}

function barChart(items,labelKey,valueKey){
 const rows=(items||[]).slice(0,10);
 if(!rows.length)return empty('Sin datos');
 const max=Math.max(...rows.map(x=>Number(x[valueKey]||0)),1);
 return `<div class="bar-chart">${rows.map(x=>{const v=Number(x[valueKey]||0);const pct=Math.max(2,Math.round(v/max*100));return `<div class="bar-row"><span>${esc(x[labelKey])}</span><div class="bar-track"><div class="bar-fill" style="width:${pct}%"></div></div><b>${esc(v.toLocaleString('es-CR'))}</b></div>`}).join('')}</div>`;
}
function table(headers,rows){return `<div class="table-wrap"><table class="data-table"><thead><tr>${headers.map(h=>`<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr>${r.map(x=>`<td>${x??''}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;}
function empty(m){return `<div class="empty-state"><h3>${m}</h3></div>`;}
async function openForm(view,id=null){
 const saveButton=document.querySelector('#modal [data-action]');
 if(saveButton)saveButton.dataset.action='save';
 const normalizedView = view === 'role' ? 'roles' : view === 'usuario_roles' ? 'usuarios' : view;
 const r=resources[normalizedView];
 if(!r || !r.endpoint) throw new Error(`No existe configuración para el módulo "${view}".`);
 const data=id?(await api(`${r.endpoint}/${id}`)):{};
 state.editing={view,id,original:data};
 $('#modalTitle').textContent=id?`Editar ${r.singular}`:`Nuevo ${r.singular}`;
 $('#modalBody').innerHTML=`<form id="entityForm">${r.fields.map(f=>fieldHtml(view,f,data[f[0]])).join('')}</form>`;
 $('#modal').classList.add('show');
}
async function saveForm(){
 const f=$('#entityForm'), view=state.editing.view,r=resources[view];
 if(!r || !r.endpoint) throw new Error(`No existe configuración para el módulo "${view}".`);
 const data=Object.fromEntries(new FormData(f).entries());
 if(view==='usuarios'){
   data.role_ids=new FormData(f).getAll('role_ids').map(Number);
   if(!data.password)delete data.password;
 }
 if(view==='permisos'){
   data.role_ids=new FormData(f).getAll('role_ids').map(Number);
 }
 const desiredOrderState=view==='ordenes'?data.estado:null;
 if(view==='ordenes') delete data.estado;
 if(view==='vehiculos' && data.id_vehiculo_catalogo){
   const catalogo=await api(`vehiculos-catalogo/${data.id_vehiculo_catalogo}`);
   data.id_marca=catalogo.id_marca;
   data.id_modelo=catalogo.id_modelo;
   data.id_tipo_combustible=catalogo.id_tipo_combustible;
   data.id_categoria_vehiculo=catalogo.id_categoria_vehiculo;
 }
 r.fields.forEach(x=>{
   if(x[2]==='number'&&data[x[0]]!=='')data[x[0]]=Number(data[x[0]]);
   if(x[2]==='select'&&data[x[0]]!=='')data[x[0]]=Number.isNaN(Number(data[x[0]]))?data[x[0]]:Number(data[x[0]]);
   if((x[2]==='datetime-local'||x[2]==='date')&&data[x[0]]){
     // El input del navegador manda "YYYY-MM-DDTHH:mm" (sin segundos) para
     // datetime-local, formato que SQL Server no siempre convierte bien de
     // forma implícita. Se completa a "YYYY-MM-DDTHH:mm:ss" para que sea
     // un formato ISO 8601 completo, independiente del idioma de la sesión.
     if(x[2]==='datetime-local' && data[x[0]].length===16) data[x[0]]+=':00';
   }
 });
 if(state.editing.id){
   await api(`${r.endpoint}/${state.editing.id}`,{method:'PUT',body:JSON.stringify(data)});
   if(view==='ordenes'&&desiredOrderState&&desiredOrderState!==state.editing.original?.estado){
     await api(`ordenes/${state.editing.id}/estado`,{method:'POST',body:JSON.stringify({estado:desiredOrderState,observacion:'Cambio de estado desde la interfaz'})});
   }
 }else{
   await api(r.endpoint,{method:'POST',body:JSON.stringify(data)});
 }
 if(view==='roles')state.catalogs.roles=await api('roles');
 $('#modal').classList.remove('show');toast('Guardado correctamente');await applyMenuPermissions();
render();
}
async function render(){
 const app=$('#app');app.innerHTML='<div class="card"><div class="empty-state"><h3>Cargando...</h3></div></div>';
 try{
   state.catalogs.clientes ||= []; if(!state.catalogs.clientes.length)await loadCatalogs();
   let html=state.view==='dashboard'?await renderDashboard():resources[state.view]?await renderResource(state.view):await renderSpecial(state.view);
   app.innerHTML=html;$('#crumb').textContent=(resources[state.view]?.title||(state.view==='admin-vehiculos'?'Administrar Vehículos':state.view)).replace('Dashboard','Dashboard');
 }catch(e){app.innerHTML=`<div class="card"><div class="empty-state"><h3>Error</h3><p>${esc(e.message)}</p><p>Revisa la conexión de SQL Server y el archivo .env.</p></div></div>`;}
}
document.addEventListener('click',async e=>{
 const adminAction=e.target.closest('[data-admin-action]');
 if(adminAction){
   e.preventDefault();
   const resource=adminAction.dataset.resource;
   try{
     if(adminAction.dataset.action==='new') return openForm(resource);
     const action=adminAction.dataset.action;
     const id=Number(adminAction.dataset.id);
     if(action==='edit') return openForm(resource,id);
     if(action==='view'){
       const d=await findRow(resource,id);
       $('#modalTitle').textContent='Detalle';
       $('#modalBody').innerHTML=detailHtml(resource,d);
       return $('#modal').classList.add('show');
     }
     if(action==='delete'){
       if(!confirm('¿Eliminar este registro?'))return;
       await api(`${resources[resource].endpoint}/${id}`,{method:'DELETE'});
       toast('Registro eliminado'); return render();
     }
   }catch(err){toast(err.message,'error');}
 }
 const a=e.target.closest('[data-view]');if(a){e.preventDefault();if(!canAccessView(a.dataset.view))return toast('No tienes permisos para acceder a este módulo.','error');state.view=a.dataset.view;state.search='';document.querySelectorAll('#nav a').forEach(x=>x.classList.toggle('active',x===a));return render();}
 const action=e.target.closest('[data-action]')?.dataset.action;if(!action)return;
 try{
  if(action==='role-permissions'){
    const id=Number(e.target.closest('[data-action]').dataset.id);
    return openRolePermissions(id);
  }
  if(action==='save-role-permissions'){
    return saveRolePermissions();
  }
  if(action==='report-filter'){
    const desde=$('#reportDesde')?.value||'',hasta=$('#reportHasta')?.value||'';
    state.reportQuery=`desde=${encodeURIComponent(desde)}&hasta=${encodeURIComponent(hasta)}`;
    return render();
  }
  if(action==='new')return openForm(state.view);
  if(action==='save'){try{await saveForm();}catch(err){toast(err.message,'error');}return;}
  if(action==='refresh'){state.search='';return render();}
  if(action==='edit')return openForm(state.view,Number(e.target.closest('[data-action]').dataset.id));
  if(action==='view'){const id=Number(e.target.closest('[data-action]').dataset.id);const d=await findRow(state.view,id);$('#modalTitle').textContent='Detalle';$('#modalBody').innerHTML=detailHtml(state.view,d);return $('#modal').classList.add('show');}
  if(action==='delete'){const id=Number(e.target.closest('[data-action]').dataset.id);if(!confirm('¿Eliminar este registro?'))return;await api(`${resources[state.view].endpoint}/${id}`,{method:'DELETE'});toast('Registro eliminado');return render();}
 }catch(err){toast(err.message,'error');}
});
document.addEventListener('submit',async e=>{
 if(e.target.id==='entityForm'){e.preventDefault();try{await saveForm();}catch(err){toast(err.message,'error');}}
 if(e.target.id==='configForm'){e.preventDefault();try{const d=Object.fromEntries(new FormData(e.target).entries());await api('configuracion',{method:'PUT',body:JSON.stringify(d)});toast('Configuración guardada');}catch(err){toast(err.message,'error');}}
});
document.addEventListener('input',e=>{if(e.target.id==='searchInput'){state.search=e.target.value;render();}});
document.addEventListener('click',e=>{if(e.target.closest('.close-modal')||e.target===$('#modal'))$('#modal').classList.remove('show');});
applyMenuPermissions();
render();
