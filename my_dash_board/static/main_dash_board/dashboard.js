/*
  Dashboard dropdown and details renderer.
  By default this loads ./api/items.json. To use a backend endpoint,
  change `API_URL` below to your endpoint that returns the same JSON shape.

  JSON shape: array of objects with fields:
  - defect_id
  - status
  - todays_plan
  - missed_plan
  - spent_time
  - comments
  - log (a local directory path or link)
*/
(function(){
  const API_URL = './api/items.json'; // change this to your backend endpoint if available

  const select = document.getElementById('item-select');
  const details = document.getElementById('item-details');
  let items = [];

  function formatRow(key, val){
    const row = document.createElement('div');
    row.className = 'item-row';
    const k = document.createElement('div'); k.className='item-key'; k.textContent = key+':';
    const v = document.createElement('div'); v.className='item-val';
    if(key === 'log' && val){
      const a = document.createElement('a');
      // Use file:// for local directories (may be blocked by some browsers)
      a.href = val.startsWith('file://') ? val : 'file:///'+val.replace(/^[\/]+/,'');
      a.textContent = val;
      a.target = '_blank';
      v.appendChild(a);
    } else {
      v.textContent = val ?? '';
    }
    row.appendChild(k); row.appendChild(v);
    return row;
  }

  function renderDetails(item){
    details.innerHTML = '';
    if(!item){ details.textContent = 'No item selected.'; return; }
    details.appendChild(formatRow('defect_id', item.defect_id));
    details.appendChild(formatRow('status', item.status));
    details.appendChild(formatRow("todays plan", item.todays_plan));
    details.appendChild(formatRow('missed plan', item.missed_plan));
    details.appendChild(formatRow('spent time', item.spent_time));
    details.appendChild(formatRow('comments', item.comments));
    details.appendChild(formatRow('log', item.log));
  }

  function populateSelect(list){
    select.innerHTML = '';
    const emptyOpt = document.createElement('option');
    emptyOpt.value = ''; emptyOpt.textContent = '-- Select defect --';
    select.appendChild(emptyOpt);
    list.forEach((it, idx)=>{
      const o = document.createElement('option');
      o.value = String(idx);
      o.textContent = `${it.defect_id} — ${it.status}`;
      select.appendChild(o);
    });
  }

  select.addEventListener('change', ()=>{
    const idx = select.value;
    if(idx === ''){ renderDetails(null); return; }
    const item = items[Number(idx)];
    renderDetails(item);
  });

  async function loadItems(){
    try{
      const res = await fetch(API_URL);
      if(!res.ok) throw new Error('Network response not ok');
      items = await res.json();
      if(!Array.isArray(items)) throw new Error('Invalid data');
      populateSelect(items);
    //   renderDetails(null);
    }catch(err){
      details.innerHTML = '<div style="color:var(--muted)">Failed to load defect items.</div>';
      console.error('loadItems error', err);
    }
  }

  loadItems();
})();
