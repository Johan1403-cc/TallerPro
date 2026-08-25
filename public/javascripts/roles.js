const rolesList=document.getElementById('rolesList');
const dlgRol=document.getElementById('dlgRol');
const rolNombre=document.getElementById('rolNombre');

function esc(v){return String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}

async function loadRoles(){
  const j=await api('/api/admin/roles-list');
  rolesList.innerHTML=j.roles.length?j.roles.map(r=>`
    <article class="role-card">
      <div class="role-icon">👤</div>
      <div>
        <h3>${esc(r.Nombre)}</h3>
        <small>${r.CantidadUsuarios||0} usuario(s) asignado(s)</small>
      </div>
      <a class="btn" href="/permisos?rol=${r.RolId}">Permisos</a>
    </article>`).join(''):'<p>No hay roles registrados.</p>';
}

document.getElementById('btnNuevoRol').onclick=()=>{rolNombre.value='';dlgRol.showModal();rolNombre.focus();};
document.getElementById('cancelRol').onclick=()=>dlgRol.close();
document.getElementById('formRol').onsubmit=async e=>{
  e.preventDefault();
  try{
    await api('/api/admin/roles',{method:'POST',body:JSON.stringify({nombre:rolNombre.value.trim()})});
    dlgRol.close();
    await loadRoles();
  }catch(err){alert(err.message||err);}
};
loadRoles().catch(e=>alert(e.message||e));
