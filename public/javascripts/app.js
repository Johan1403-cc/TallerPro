const state = { view:'dashboard', data:{}, catalogs:{}, search:'' };

// Permisos de interfaz. El backend repite estas reglas, por lo que ocultar
// opciones aquí es solo una mejora visual y no la única protección.
const CURRENT_USER = window.TALLERPRO_USER || { roles: [] };
function normalizeRole(value){return String(value||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').trim().toLowerCase();}
const CURRENT_ROLES = (CURRENT_USER.roles||[]).map(r=>normalizeRole(r.nombre||r));
const VIEW_ROLES = {
  dashboard: [],
  clientes: ['Administrador','Supervisor','Recepcionista','Vendedor','Cajero'],
  vehiculos: ['Administrador','Supervisor','Recepcionista','Mecánico'],
  'admin-vehiculos': ['Administrador','Supervisor','Recepcionista'],
  citas: ['Administrador','Supervisor','Recepcionista'],
  recepciones: ['Administrador','Supervisor','Recepcionista','Mecánico'],
  diagnosticos: ['Administrador','Supervisor','Mecánico'],
  cotizaciones: ['Administrador','Supervisor','Recepcionista','Mecánico'],
  ordenes: ['Administrador','Supervisor','Mecánico'],
  empleados: ['Administrador'],
  servicios: ['Administrador','Supervisor','Mecánico'],
  inventario: ['Administrador','Supervisor','Encargado de inventario','Vendedor'],
  proveedores: ['Administrador','Supervisor','Encargado de inventario'],
  compras: ['Administrador','Supervisor','Encargado de inventario'],
  ventas: ['Administrador','Supervisor','Vendedor','Cajero'],
  garantias: ['Administrador','Supervisor','Recepcionista','Mecánico'],
  facturas: ['Administrador','Supervisor','Cajero'],
  usuarios: ['Administrador'],
  reportes: ['Administrador','Supervisor'],
  configuracion: ['Administrador']
};
function canAccessView(view){
  if(CURRENT_ROLES.includes('administrador')) return true;
  const allowed=(VIEW_ROLES[view]||[]).map(normalizeRole);
  return allowed.length===0 || allowed.some(r=>CURRENT_ROLES.includes(r));
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
  usuarios:{title:'Usuarios y roles',singular:'usuario',endpoint:'usuarios',fields:[
    ['nombre_usuario','Usuario','text',true],['email','Correo','email',true],
    ['id_cliente','Cliente','select'],['activo','Activo','select'],
    ['roles','Roles','text']
  ]},
  roles:{title:'Roles',singular:'rol',endpoint:'roles',fields:[
    ['nombre','Nombre','text',true],['descripcion','Descripción','textarea'],
    ['activo','Activo','select']
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
  ordenes:{estado:['REGISTRADA','EN_DIAGNOSTICO','ESPERANDO_APROBACION','APROBADA','EN_REPARACION','LISTA','ENTREGADA','FINALIZADA','CANCELADA']},
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
    if(/permisos/i.test(e.message)) return fallback;
    throw e;
  }
}
async function loadCatalogs(){
  state.catalogs=await api('catalogos');
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
 if(name==='roles') return `<div class="field full"><label>${esc(label)}</label><input type="text" value="${esc(value||'Sin rol')}" readonly><small>Los roles se administran desde la asignación de roles del usuario.</small></div>`;
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
 const r=resources[view], cols=r.fields.map(f=>f[0]);const headers=r.fields.map(f=>f[1]);
 return `<div class="table-wrap"><table class="data-table"><thead><tr>${headers.map(esc).map(x=>`<th>${x}</th>`).join('')}<th>Acciones</th></tr></thead><tbody>${rows.map((row,i)=>`<tr>${cols.map(k=>{const display=displayValue(k,row);return `<td>${k==='estado'?status(display):esc(k==='precio_base'?money(display):k==='precio_venta'?money(display):display)}</td>`}).join('')}<td class="actions"><button class="icon-btn" data-action="view" data-id="${row.id}">Ver</button><button class="icon-btn" data-action="edit" data-id="${row.id}">Editar</button><button class="icon-btn" data-action="delete" data-id="${row.id}">Eliminar</button></td></tr>`).join('')}</tbody></table></div>`;
}
function detailHtml(view,row){
 const normalizedView=view==='role'?'roles':view==='usuario_roles'?'usuarios':view;
 const r=resources[normalizedView];
 if(!r)return '<div class="detail-list">'+Object.entries(row).map(([k,v])=>`<div><small>${esc(k)}</small><b>${esc(v)}</b></div>`).join('')+'</div>';
 return '<div class="detail-list">'+r.fields.map(f=>{
   const [name,label]=f;
   let val=displayValue(name,row);
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
 const d=await api('dashboard');const s=d.stats;
 return head('Dashboard','Resumen general del taller automotriz.',false)+
 `<div class="stats">
 <div class="stat"><div><small>Vehículos</small><h3>${s.vehiculos}</h3></div><div class="icon"><i class="fa-solid fa-car"></i></div></div>
 <div class="stat"><div><small>Órdenes activas</small><h3>${s.ordenes}</h3></div><div class="icon green"><i class="fa-solid fa-screwdriver-wrench"></i></div></div>
 <div class="stat"><div><small>Diagnósticos pendientes</small><h3>${s.diagnosticos}</h3></div><div class="icon orange"><i class="fa-solid fa-stethoscope"></i></div></div>
 <div class="stat"><div><small>Cotizaciones pendientes</small><h3>${s.cotizaciones}</h3></div><div class="icon red"><i class="fa-solid fa-file-invoice-dollar"></i></div></div>
 <div class="stat"><div><small>Por cobrar</small><h3>${money(s.por_cobrar)}</h3></div><div class="icon"><i class="fa-solid fa-file-invoice"></i></div></div>
 <div class="stat"><div><small>Ventas hoy</small><h3>${money(s.ventas_hoy)}</h3></div><div class="icon green"><i class="fa-solid fa-cash-register"></i></div></div>
 <div class="stat"><div><small>Ingresos del mes</small><h3>${money(s.ingresos_mes)}</h3></div><div class="icon orange"><i class="fa-solid fa-chart-line"></i></div></div>
 </div>
 <div class="card"><div class="card-head"><h3>Órdenes recientes</h3></div>
 ${d.recientes.length?tableFor('ordenes',d.recientes):`<div class="empty-state"><h3>No hay órdenes todavía</h3></div>`}</div>`;
}
async function renderResource(view){
 const normalizedView = view === 'role' ? 'roles' : view === 'usuario_roles' ? 'usuarios' : view;
 const r=resources[normalizedView];
 if(!r || !r.endpoint) throw new Error(`No existe configuración para el módulo "${view}".`);
 let rows=await api(r.endpoint);state.data[view]=rows;
 const q=state.search.toLowerCase();if(q)rows=rows.filter(x=>JSON.stringify(x).toLowerCase().includes(q));
 return head(r.title,desc(view))+`<div class="toolbar"><div class="search"><i class="fa-solid fa-magnifying-glass"></i><input id="searchInput" value="${esc(state.search)}" placeholder="Buscar..."></div><button class="filter" data-action="refresh">Actualizar</button></div>${rows.length?tableFor(view,rows):`<div class="card"><div class="empty-state"><h3>No hay ${r.title.toLowerCase()} registrados</h3><p>Usa el botón Nuevo para comenzar.</p></div></div>`}`;
}
function desc(v){return ({clientes:'Clientes del taller y sus datos de contacto.',vehiculos:'Vehículos de Clientes: unidades asociadas a clientes y basadas en el catálogo administrativo.',empleados:'Personal y responsables del taller.',servicios:'Catálogo de servicios y mano de obra.',proveedores:'Proveedores de repuestos e insumos.',inventario:'Existencias y precios de repuestos.',citas:'Agenda de atención y mantenimiento.',recepciones:'Ingreso y condición inicial del vehículo.',diagnosticos:'Evaluación técnica y hallazgos.',cotizaciones:'Presupuestos derivados de diagnósticos.',ordenes:'Ciclo completo de reparación.',compras:'Compras y entradas de inventario.',ventas:'Ventas de repuestos.',facturas:'Facturación, pagos y estados.',garantias:'Garantías y seguimiento.',usuarios:'Usuarios, roles y permisos.'}[v]||'Gestión del taller.');}
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
async function renderSpecial(view){
 if(view==='admin-vehiculos')return renderAdminVehiculos();
 if(view==='reportes'){const d=await api('reportes');return head('Reportes','Indicadores obtenidos directamente de SQL Server.',false)+`<div class="grid"><div class="card"><h3>Ventas por mes</h3>${d.ventas.length?table(['Periodo','Total'],d.ventas.map(x=>[x.periodo,money(x.total)])):empty('Sin ventas pagadas')}</div><div class="card"><h3>Servicios más solicitados</h3>${d.servicios.length?table(['Servicio','Cantidad'],d.servicios.map(x=>[x.nombre,x.cantidad])):empty('Sin servicios usados')}</div></div><div class="card" style="margin-top:18px"><h3>Órdenes por estado</h3>${d.estados.length?table(['Estado','Cantidad'],d.estados.map(x=>[status(x.estado),x.cantidad])):empty()}</div>`;}
 if(view==='configuracion'){const rows=await api('configuracion');return head('Configuración','Parámetros generales guardados en CONFIGURACION_GENERAL.',false)+`<div class="form-card"><form id="configForm"><div class="form-grid">${rows.map(x=>`<div class="field"><label>${esc(x.clave)}</label><input name="${esc(x.clave)}" value="${esc(x.valor||'')}"><small>${esc(x.descripcion||'')}</small></div>`).join('')}</div><div class="modal-actions"><button class="btn primary">Guardar configuración</button></div></form></div>`;}
 if(view==='ordenes'){return renderResource('ordenes');}
 return renderResource(view);
}
function adminTableFor(resource,rows){
  return tableFor(resource,rows).replace(/data-action="(view|edit|delete)"/g, 'data-admin-action data-action="$1" data-resource="'+resource+'"');
}

function table(headers,rows){return `<div class="table-wrap"><table class="data-table"><thead><tr>${headers.map(h=>`<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr>${r.map(x=>`<td>${x??''}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;}
function empty(m){return `<div class="empty-state"><h3>${m}</h3></div>`;}
async function openForm(view,id=null){
 const normalizedView = view === 'role' ? 'roles' : view === 'usuario_roles' ? 'usuarios' : view;
 const r=resources[normalizedView];
 if(!r || !r.endpoint) throw new Error(`No existe configuración para el módulo "${view}".`);
 const data=id?(await api(`${r.endpoint}/${id}`)):{};
 state.editing={view,id};
 $('#modalTitle').textContent=id?`Editar ${r.singular}`:`Nuevo ${r.singular}`;
 $('#modalBody').innerHTML=`<form id="entityForm">${r.fields.map(f=>fieldHtml(view,f,data[f[0]])).join('')}</form>`;
 $('#modal').classList.add('show');
}
async function saveForm(){
 const f=$('#entityForm'), view=state.editing.view,r=resources[view];
 if(!r || !r.endpoint) throw new Error(`No existe configuración para el módulo "${view}".`);
 const data=Object.fromEntries(new FormData(f).entries());
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
 if(state.editing.id) await api(`${r.endpoint}/${state.editing.id}`,{method:'PUT',body:JSON.stringify(data)});
 else await api(r.endpoint,{method:'POST',body:JSON.stringify(data)});
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
