const express = require('express');
const router = express.Router();
const { query } = require('./bd');
const { getSessionUser, getUserPermissions, requireAuth } = require('./auth');

router.get('/login', (req, res) => {
  res.render('login', { layout: false });
});

router.get('/', requireAuth, async (req,res,next) => {
  const user = req.user;
  try {
    const permissions = await getUserPermissions(user.id_usuario);
    res.render('index', { title: 'Dashboard', currentUser: user, permissions });
  } catch (e) {
    next(e);
  }
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
