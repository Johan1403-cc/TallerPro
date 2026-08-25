require('dotenv').config();

const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const hbs = require('hbs');

const indexRouter = require('./routes/index');
const apiRouter = require('./routes/api');

const app = express();

// Render actúa como proxy inverso; permite registrar la IP real del cliente.
app.set('trust proxy', 1);

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'hbs');

hbs.registerHelper('eq', (a, b) => a === b);
hbs.registerHelper('json', value => JSON.stringify(value));
hbs.registerHelper('initials', value => {
  const name = String(value || '').trim();
  if (!name) return 'TP';
  const parts = name.split(/\s+/).slice(0, 2);
  return parts.map(p => p.charAt(0).toUpperCase()).join('');
});
hbs.registerHelper('rolesText', roles => {
  if (!Array.isArray(roles) || !roles.length) return 'Sin rol';
  return roles.map(r => r.nombre).join(', ');
});

app.use(logger('dev'));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// Vistas de TallerPro
app.use('/', indexRouter);

// API separada por módulos/sectores
app.use('/api', apiRouter);

// 404
app.use((req, res, next) => next(createError(404)));

// Manejador central de errores
app.use((err, req, res, next) => {
  console.error(err);

  if (req.path.startsWith('/api/')) {
    return res.status(err.status || 500).json({
      error: err.message || 'Error interno del servidor'
    });
  }

  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;

// Si este archivo se ejecuta directamente (ej. Plesk/Passenger usando
// "app.js" como archivo de inicio), arrancamos el servidor aquí mismo.
// Si en cambio se ejecuta a través de bin/www (require('../app')), esta
// parte NO se ejecuta, así que no hay conflicto de puertos entre ambos.
if (require.main === module) {
  const port = process.env.PORT || 3000;
  app.listen(port, () => {
    console.log(`TallerPro escuchando en el puerto ${port}`);
  });
}
