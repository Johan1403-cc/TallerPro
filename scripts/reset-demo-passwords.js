const crypto = require('crypto');
const { query, close } = require('../routes/bd');

const usuarios = [
  ['admin', 'Admin123!'],
  ['recepcionista1', 'Recep123!'],
  ['mecanico1', 'Meca123!'],
  ['inventario1', 'Inven123!'],
  ['vendedor1', 'Venta123!'],
  ['cajero1', 'Caja123!'],
  ['supervisor1', 'Super123!'],
  ['mecanico2', 'Meca223!'],
  ['vendedor2', 'Venta223!'],
  ['recepcionista2', 'Recep223!']
];

async function main() {
  try {
    for (const [usuario, password] of usuarios) {
      const salt = crypto.randomBytes(32);

      // IMPORTANTE:
      // Debe coincidir exactamente con routes/api/auth.js
      const hash = crypto.scryptSync(password, salt, 64);

      const result = await query(
        UPDATE USUARIOS
        SET
          password_hash = @hash,
          password_salt = @salt,
          activo = 1,
          intentos_fallidos = 0,
          bloqueado_hasta = NULL
        WHERE LOWER(nombre_usuario) = LOWER(@usuario)
      , {
        usuario,
        hash,
        salt
      });

      console.log(Actualizado: ${usuario});
    }

    console.log('');
    console.log('Contraseñas de demostración actualizadas correctamente.');
  } catch (err) {
    console.error('ERROR:', err);
    process.exitCode = 1;
  } finally {
    if (typeof close === 'function') {
      await close();
    }
  }
}

main();
