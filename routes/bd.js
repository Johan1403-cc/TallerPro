// Modo de autenticación contra SQL Server:
//   'windows' -> Autenticación de Windows (integrada, usa el usuario de Windows que ejecuta Node)
//   'sql'     -> Autenticación de SQL Server (usuario y contraseña, ej. sa)
// Se controla con la variable DB_AUTH_MODE en el archivo .env
// Ver README_AUTENTICACION.md para más detalles y cómo cambiar de una a otra.
const AUTH_MODE = String(process.env.DB_AUTH_MODE || 'sql').toLowerCase();

let sql;
let config;
let logLabel; // texto descriptivo para el console.log de conexión

if (AUTH_MODE === 'windows') {
  // Requiere el driver nativo msnodesqlv8 (ver README_AUTENTICACION.md para instalarlo)
  sql = require('mssql/msnodesqlv8');

  const server = process.env.DB_SERVER || 'localhost';
  const instance = process.env.DB_INSTANCE || '';
  const port = process.env.DB_PORT || '';
  const database = process.env.DB_NAME || 'taller_mecanico';

  // El driver ODBC instalado en la máquina (ver README_AUTENTICACION.md para saber
  // cuáles tienes disponibles). Los Windows/SQL Server modernos suelen traer
  // "ODBC Driver 17 for SQL Server" o "ODBC Driver 18 for SQL Server".
  const odbcDriver = process.env.DB_ODBC_DRIVER || 'ODBC Driver 17 for SQL Server';

  let serverPart = server;
  if (instance) {
    serverPart = `${server}\\${instance}`;
  } else if (port) {
    serverPart = `${server},${port}`;
  }

  // Construimos la cadena de conexión ODBC explícitamente en lugar de dejar que
  // msnodesqlv8 use su driver por defecto (SQL Server Native Client 11.0), que
  // ya no viene instalado en Windows/SQL Server recientes.
  let connectionString = `Driver={${odbcDriver}};Server=${serverPart};Database=${database};Trusted_Connection=Yes;`;
  if (String(process.env.DB_ENCRYPT || 'false').toLowerCase() === 'true') {
    connectionString += 'Encrypt=Yes;';
  } else {
    connectionString += 'Encrypt=No;';
  }
  if (String(process.env.DB_TRUST_SERVER_CERTIFICATE || 'true').toLowerCase() === 'true') {
    connectionString += 'TrustServerCertificate=Yes;';
  }

  config = {
    driver: 'msnodesqlv8',
    connectionString,
    pool: { max: 10, min: 0, idleTimeoutMillis: 30000 }
  };

  logLabel = `Autenticación de Windows (driver ODBC: ${odbcDriver}): ${serverPart}/${database}`;
} else {
  sql = require('mssql');

  const server = process.env.DB_SERVER || 'localhost';
  const database = process.env.DB_NAME || 'taller_mecanico';
  const instanceName = process.env.DB_INSTANCE || undefined;

  config = {
    server,
    database,
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD || '',
    port: process.env.DB_PORT ? Number(process.env.DB_PORT) : undefined,
    options: {
      encrypt: String(process.env.DB_ENCRYPT || 'false').toLowerCase() === 'true',
      trustServerCertificate: String(process.env.DB_TRUST_SERVER_CERTIFICATE || 'true').toLowerCase() === 'true',
      instanceName
    },
    pool: { max: 10, min: 0, idleTimeoutMillis: 30000 }
  };

  logLabel = `Autenticación de SQL Server: ${server}${instanceName ? '\\' + instanceName : ''}/${database}`;
}

let poolPromise;

function getPool() {
  if (!poolPromise) {
    poolPromise = new sql.ConnectionPool(config).connect()
      .then(pool => {
        console.log(`SQL Server conectado (${logLabel})`);
        pool.on('error', err => console.error('SQL pool error:', err));
        return pool;
      })
      .catch(err => {
        poolPromise = null;
        console.error('No se pudo conectar a SQL Server:', err.message);
        throw err;
      });
  }
  return poolPromise;
}

async function query(text, params = {}) {
  const pool = await getPool();
  const request = pool.request();
  Object.entries(params).forEach(([key, value]) => request.input(key, value === undefined ? null : value));
  return request.query(text);
}

async function executeProcedure(name, params = {}) {
  const pool = await getPool();
  const request = pool.request();
  Object.entries(params).forEach(([key, value]) => request.input(key.replace(/^@/, ''), value === undefined ? null : value));
  return request.execute(name);
}

module.exports = { sql, config, getPool, query, executeProcedure };
