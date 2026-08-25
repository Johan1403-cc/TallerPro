# TallerPro - GitHub + Render + Azure SQL

## 1. Base de datos
La aplicación espera la base **TallerProDB**.
Ejecute primero en Azure SQL:

1. `database/01_TallerPro_CREACION_BD.sql`
2. `database/02_TallerPro_INSERCION_DATOS.sql`

## 2. GitHub
No suba `node_modules/` ni `.env`. Ya están incluidos en `.gitignore`.

Ejemplo:

```bash
git init
git add .
git commit -m "TallerPro final"
git branch -M main
git remote add origin URL_DE_TU_REPOSITORIO
git push -u origin main
```

## 3. Render
Puede conectar el repositorio manualmente o usar `render.yaml`.

Build command:

```text
npm ci
```

Start command:

```text
npm start
```

Health check:

```text
/health
```

## 4. Variables de entorno de Render
Configure estas variables en Render:

```text
DB_SERVER=tallerpro-johan2026.database.windows.net
DB_NAME=TallerProDB
DB_USER=tallerproadmin
DB_PASSWORD=<contraseña real>
DB_PORT=1433
DB_ENCRYPT=true
DB_TRUST_SERVER_CERTIFICATE=false
NODE_ENV=production
COOKIE_SECURE=true
SESSION_HOURS=8
```

`PORT` no debe fijarse manualmente: Render lo proporciona automáticamente.

La aplicación también acepta `DB_DATABASE` como alias de `DB_NAME` y `DB_TRUST_CERT` como alias de `DB_TRUST_SERVER_CERTIFICATE`.

## 5. Variables antiguas del servicio de Render
Si está reemplazando el programa anterior, puede conservar `DB_SERVER`, `DB_USER`, `DB_PASSWORD`, `DB_PORT` y `DB_ENCRYPT` si siguen apuntando al mismo servidor Azure.

Cambie obligatoriamente:

```text
DB_NAME=TallerProDB
```

`APP_SESSION_SECRET`, `DB_AUTH_MODE`, `DB_INSTANCE` y `TEST_MODE` no son requeridas por esta versión de TallerPro. Puede eliminarlas de Render si no las utiliza otro proceso.

## 6. Azure SQL y firewall
El servidor Azure SQL debe aceptar conexiones desde los IP de salida de Render. Si la conexión falla con errores de firewall/login, revise en Azure SQL Server > Networking / Firewalls que las direcciones de salida de su servicio de Render estén autorizadas.

## 7. Seguridad
- `.env` real no está incluido en el ZIP para GitHub.
- Las cookies de sesión usan `Secure` en producción.
- Azure SQL usa cifrado (`DB_ENCRYPT=true`).
- Las consultas usan `mssql` y parámetros en los módulos del proyecto.
