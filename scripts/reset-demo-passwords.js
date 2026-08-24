require('dotenv').config();
const crypto = require('crypto');
const { getPool } = require('../routes/bd');

const DEMO_USERS = [
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
  const pool = await getPool();
  let updated = 0;

  for (const [nombre_usuario, password] of DEMO_USERS) {
    const salt = crypto.randomBytes(32);
    const hash = crypto.scryptSync(password, salt, 64);
    const result = await pool.request()
      .input('nombre_usuario', nombre_usuario)
      .input('password_hash', hash)
      .input('password_salt', salt)
      .query(`
        UPDATE USUARIOS
        SET password_hash=@password_hash,
            password_salt=@password_salt,
            activo=1,
            intentos_fallidos=0,
            bloqueado_hasta=NULL
        WHERE LOWER(nombre_usuario)=LOWER(@nombre_usuario)
      `);

    const rows = result.rowsAffected.reduce((a, b) => a + b, 0);
    if (rows) {
      updated += rows;
      console.log(`OK  ${nombre_usuario.padEnd(16)} -> ${password}`);
    } else {
      console.log(`NO ENCONTRADO: ${nombre_usuario}`);
    }
  }

  console.log(`\nUsuarios actualizados: ${updated}`);
  await pool.close();
}

main().catch(err => {
  console.error('Error al reiniciar contraseñas:', err.message);
  process.exitCode = 1;
});
