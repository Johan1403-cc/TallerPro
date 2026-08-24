const express = require('express');
const router = express.Router();
const { query } = require('./bd');
const { getSessionUser } = require('./auth');

router.get('/login', (req, res) => {
  if (getSessionUser(req)) return res.redirect('/');
  res.render('login', { layout: false });
});

router.get('/', (req,res) => {
  const user = getSessionUser(req);
  if (!user) return res.redirect('/login');
  res.render('index', { title: 'Dashboard', currentUser: user });
});

router.get('/health', async (req,res) => {
  try {
    const r = await query('SELECT DB_NAME() AS database_name, GETDATE() AS server_time');
    res.json({ok:true, database:r.recordset[0]});
  } catch(e) {
    res.status(500).json({ok:false,error:e.message});
  }
});

module.exports = router;
