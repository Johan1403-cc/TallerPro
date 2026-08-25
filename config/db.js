const sql = require('mssql');
require('dotenv').config();

function envBool(name, fallback = false) {
  const value = process.env[name];
  if (value === undefined || value === null || value === '') return fallback;
  return String(value).toLowerCase() === 'true';
}

const database = process.env.DB_DATABASE || process.env.DB_NAME;
const trustServerCertificate = process.env.DB_TRUST_CERT !== undefined
  ? envBool('DB_TRUST_CERT', false)
  : envBool('DB_TRUST_SERVER_CERTIFICATE', false);

const config = {
  server: process.env.DB_SERVER,
  database,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: Number(process.env.DB_PORT || 1433),
  options: {
    encrypt: envBool('DB_ENCRYPT', true),
    trustServerCertificate
  },
  pool: {
    max: Number(process.env.DB_POOL_MAX || 10),
    min: 0,
    idleTimeoutMillis: 30000
  },
  connectionTimeout: Number(process.env.DB_CONNECTION_TIMEOUT || 30000),
  requestTimeout: Number(process.env.DB_REQUEST_TIMEOUT || 30000)
};

const required = [
  ['DB_SERVER', config.server],
  ['DB_NAME o DB_DATABASE', config.database],
  ['DB_USER', config.user],
  ['DB_PASSWORD', config.password]
];

const missing = required.filter(([, value]) => !value).map(([name]) => name);
if (missing.length) {
  throw new Error(`Faltan variables de entorno de SQL Server: ${missing.join(', ')}`);
}

let pool;

async function getPool() {
  if (!pool) {
    pool = await new sql.ConnectionPool(config).connect();
    console.log(`SQL Server conectado: ${config.server}/${config.database}`);
  }
  return pool;
}

module.exports = { sql, getPool, dbConfig: config };
