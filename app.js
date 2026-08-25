const createError=require('http-errors');const express=require('express');const path=require('path');const cookieParser=require('cookie-parser');const logger=require('morgan');const hbs=require('hbs');require('dotenv').config();
const indexRouter=require('./routes/index');const authRouter=require('./routes/api/auth');const dataRouter=require('./routes/api/generic');const opsRouter=require('./routes/api/operations');const adminRouter=require('./routes/api/admin');const queryRouter=require('./routes/api/query');const {loadSession,csrf}=require('./middleware/auth');
const app=express();

// Helpers de autorización para las vistas. Ocultan del menú los módulos que el usuario no puede consultar.
hbs.registerHelper('hasPerm',function(permissions,code){
  const list=Array.isArray(permissions)?permissions:[];
  return list.includes('ADMIN_TOTAL')||list.includes(code);
});
hbs.registerHelper('hasAnyPerm',function(permissions,...args){
  const list=Array.isArray(permissions)?permissions:[];
  const codes=args.slice(0,-1);
  return list.includes('ADMIN_TOTAL')||codes.some(code=>list.includes(code));
});
hbs.registerPartials(path.join(__dirname,'views/partials'));app.set('views',path.join(__dirname,'views'));app.set('view engine','hbs');app.use(logger('dev'));app.use(express.json({limit:'2mb'}));app.use(express.urlencoded({extended:false,limit:'2mb'}));app.use(cookieParser());app.use(express.static(path.join(__dirname,'public')));app.set('trust proxy',1);app.get('/health',(req,res)=>res.status(200).json({ok:true,service:'TallerPro'}));app.use(loadSession);app.use(csrf);app.use('/',indexRouter);app.use('/api/auth',authRouter);app.use('/api/data',dataRouter);app.use('/api/ops',opsRouter);app.use('/api/admin',adminRouter);app.use('/api/query',queryRouter);app.use((req,res,next)=>next(createError(404)));app.use((err,req,res,next)=>{console.error(err);if(req.originalUrl.startsWith('/api/'))return res.status(err.status||500).json({ok:false,message:process.env.NODE_ENV==='production'?'Ocurrió un error al procesar la solicitud.':err.message});res.locals.message=err.message;res.locals.error=req.app.get('env')==='development'?err:{};res.status(err.status||500);res.render('error',{message:err.message,error:err});});module.exports=app;
