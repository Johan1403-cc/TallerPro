async function api(url,opt={}){
  opt.headers={'Content-Type':'application/json','x-csrf-token':window.CSRF||'',...(opt.headers||{})};
  const r=await fetch(url,opt);
  let j;
  try{j=await r.json()}catch{j={ok:r.ok,message:r.statusText}}
  if(r.status===401){location='/login';throw new Error('Sesión vencida')}
  if(!r.ok)throw Object.assign(new Error(j.message||'Error'),{data:j});
  return j;
}
window.api=api;
window.addEventListener('DOMContentLoaded',()=>{
  const lo=document.getElementById('logout');
  if(lo)lo.onclick=async()=>{try{await api('/api/auth/logout',{method:'POST',body:'{}'})}finally{location='/login'}};
});
window.addEventListener('unhandledrejection',e=>{const m=e.reason?.message;if(m)alert(m)});
