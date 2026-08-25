const rolesMenu=document.getElementById('rolesMenu');
const permPanel=document.getElementById('permPanel');
const permissionGroups=document.getElementById('permissionGroups');
const selectedRoleName=document.getElementById('selectedRoleName');
let data=null,currentRole=null;
function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
async function init(){
 data=await api('/api/admin/roles');
 rolesMenu.innerHTML=data.roles.map(r=>`<button type="button" class="role-menu-item" data-id="${r.RolId}"><b>${esc(r.Nombre)}</b><span>Abrir permisos →</span></button>`).join('');
 rolesMenu.querySelectorAll('.role-menu-item').forEach(b=>b.onclick=()=>openRole(Number(b.dataset.id)));
 const q=new URLSearchParams(location.search).get('rol'); if(q) openRole(Number(q));
}
function openRole(id){
 const r=data.roles.find(x=>x.RolId===id); if(!r)return;
 currentRole=id; selectedRoleName.textContent=r.Nombre; permPanel.style.display='block';
 rolesMenu.querySelectorAll('.role-menu-item').forEach(b=>b.classList.toggle('active',Number(b.dataset.id)===id));
 const selected=new Set(data.asignaciones.filter(x=>x.RolId===id).map(x=>x.PermisoId));
 const groups={}; data.permisos.forEach(p=>(groups[p.Modulo||'GENERAL']??=[]).push(p));
 permissionGroups.innerHTML=Object.entries(groups).map(([mod,perms])=>`<section class="permission-group"><h3>${esc(mod)}</h3>${perms.map(p=>`<label class="permission-row"><input type="checkbox" data-pid="${p.PermisoId}" ${selected.has(p.PermisoId)?'checked':''}><span><b>${esc(p.Codigo)}</b><small>${esc(p.Descripcion||'')}</small></span></label>`).join('')}</section>`).join('');
 permissionGroups.querySelectorAll('input[type=checkbox]').forEach(ch=>ch.onchange=()=>togglePermission(ch));
 permPanel.scrollIntoView({behavior:'smooth',block:'start'});
}
async function togglePermission(ch){
 ch.disabled=true;
 try{
   await api(`/api/admin/roles/${currentRole}/permisos/${ch.dataset.pid}`,{method:'POST',body:'{}'});
   const idx=data.asignaciones.findIndex(x=>x.RolId===currentRole&&x.PermisoId===Number(ch.dataset.pid));
   if(ch.checked&&idx<0)data.asignaciones.push({RolId:currentRole,PermisoId:Number(ch.dataset.pid)});
   if(!ch.checked&&idx>=0)data.asignaciones.splice(idx,1);
 }catch(e){ch.checked=!ch.checked;alert(e.message||e);}finally{ch.disabled=false;}
}
document.getElementById('closePerms').onclick=()=>{permPanel.style.display='none';currentRole=null;rolesMenu.querySelectorAll('.active').forEach(x=>x.classList.remove('active'));};
init().catch(e=>alert(e.message||e));
