const { createCrudRouter } = require('./crud');
module.exports = createCrudRouter({ table:'MODELOS_VEHICULO', id:'id_modelo', columns:['id_marca','nombre','activo'], select:'SELECT mo.id_modelo AS id,mo.id_marca,m.nombre AS marca,mo.nombre,mo.activo FROM MODELOS_VEHICULO mo INNER JOIN MARCAS_VEHICULO m ON m.id_marca=mo.id_marca ORDER BY m.nombre,mo.nombre' });
