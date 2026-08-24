const express = require('express');
const { query } = require('../bd');
const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const result = await query('SELECT DB_NAME() AS database_name, GETDATE() AS server_time');
    res.json({ ok: true, database: result.recordset[0] });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

module.exports = router;
