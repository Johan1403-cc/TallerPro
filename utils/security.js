const crypto=require('crypto');
function hashPassword(password,salt=crypto.randomBytes(16).toString('hex')){const hash=crypto.scryptSync(String(password),salt,64).toString('hex');return {salt,hash};}
function verifyPassword(password,salt,expected){const actual=crypto.scryptSync(String(password),salt,64);const exp=Buffer.from(expected,'hex');return actual.length===exp.length&&crypto.timingSafeEqual(actual,exp);}
function token(bytes=32){return crypto.randomBytes(bytes).toString('hex');}
function sha256(v){return crypto.createHash('sha256').update(v).digest('hex');}
function safeText(v,max=4000){return String(v??'').replace(/[<>]/g,'').slice(0,max).trim();}
module.exports={hashPassword,verifyPassword,token,sha256,safeText};
