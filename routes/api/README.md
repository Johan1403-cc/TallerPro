# API modular de TallerPro

La API está separada por módulo. Todas las rutas se montan desde `routes/api/index.js` bajo el prefijo `/api`.

## Módulos

- `/api/clientes`
- `/api/vehiculos`
- `/api/empleados`
- `/api/servicios`
- `/api/proveedores`
- `/api/categorias`
- `/api/inventario`
- `/api/citas`
- `/api/recepciones`
- `/api/diagnosticos`
- `/api/ordenes`
- `/api/compras`
- `/api/ventas`
- `/api/facturas`
- `/api/usuarios`
- `/api/garantias`

## Consultas generales

- `/api/health`
- `/api/dashboard`
- `/api/catalogos`
- `/api/reportes`
- `/api/configuracion`
- `/api/roles`

`crud.js` contiene la fábrica reutilizable para los CRUD sencillos. Los módulos con lógica de negocio adicional (`ordenes`, `inventario`, `compras`, `ventas`, `facturas` y `usuarios`) mantienen sus endpoints específicos en su propio archivo.
