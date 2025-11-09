% include("shell_top", title="Availability")

<section class="card">
  <h2>Set Availability</h2>
  <div class="muted">Drag to add solid blocks. Hold <strong>Shift</strong> while dragging to erase. Click a block to delete it.</div>

  % if ok:
    <div style="margin-top:12px;padding:10px 12px;border-radius:10px;
         background:rgba(34,197,94,.10);border:1px solid rgba(34,197,94,.25);color:#16a34a;font-size:13px;">
      {{ok}}
    </div>
  % end

  <style>
    :root{
      --timecol:72px;    /* time gutter width */
      --headh:32px;      /* header height */
      --rowh:28px;       /* half-hour row height */
      --gap:6px;         /* grid gap */
    }

    .avail-toolbar{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}
    .btn.small{padding:6px 10px;border-radius:10px;font-size:12px}

    .week-wrap{margin-top:12px; position:relative}
    .week-grid{
      user-select:none;
      display:grid;
      grid-template-columns: var(--timecol) repeat(7, 1fr);
      grid-template-rows: var(--headh) repeat({{(end_hour - start_hour)*2}}, var(--rowh));
      gap: var(--gap) var(--gap);
      align-items:start;
      position:relative;
      touch-action:none;
      cursor:crosshair;
    }
    .w-head{font-size:12px; color:var(--muted); display:flex; align-items:center; justify-content:center}
    .w-time{font-size:12px; color:var(--muted); text-align:right; padding-right:6px}
    .w-slot{
      background:rgba(2,6,23,.35);
      border:1px dashed rgba(148,163,184,.18);
      border-radius:8px;
    }

    /* Overlay that captures pointer events and holds blocks absolutely */
    .overlay-col{
      position:absolute;
      pointer-events:auto; /* capture pointer input */
    }
    .overlay-inner{
      position:relative;
      width:100%; height:100%;
    }

    /* Blocks (absolute in overlay) */
    .a-block{
      position:absolute;
      left:6px; right:6px; /* small inset for aesthetics */
      background:linear-gradient(135deg, rgba(99,102,241,.85), rgba(139,92,246,.85));
      color:#fff; border-radius:10px; padding:6px 8px; font-size:12px; box-shadow:var(--shadow);
      border:1px solid rgba(255,255,255,.2);
      cursor:pointer;
      display:flex;
      align-items:flex-start;     /* move content to the top */
      justify-content:flex-start; /* ensure label stays top-left */
    }
    .a-block .label{font-size:11px; opacity:.95}

    /* Ghost while dragging (absolute) */
    .a-ghost{
      position:absolute; left:6px; right:6px;
      background:linear-gradient(135deg, rgba(99,102,241,.35), rgba(139,92,246,.35));
      outline:2px dashed rgba(199,210,254,.7);
      border-radius:10px;
      pointer-events:none;
    }

    .hint{margin-top:8px; font-size:12px; color:var(--muted)}
  </style>

  <div class="avail-toolbar">
    <button class="btn small" type="button" id="preset-workdays">Mon–Fri 09:00–17:00</button>
    <button class="btn secondary small" type="button" id="clear-all">Clear all</button>
  </div>

  <!-- Background grid -->
  <div class="week-wrap">
    <div class="week-grid" id="grid" data-start-hour="{{start_hour}}" data-end-hour="{{end_hour}}">
      <!-- top-left corner -->
      <div></div>
      % for d in days:
        <div class="w-head"><strong>{{d}}</strong></div>
      % end

      % for hr in range(start_hour, end_hour):
        <div class="w-time" style="grid-row: {{ (hr - start_hour)*2 + 2 }} / span 2;">{{ "%02d:00" % hr }}</div>
        % for col in range(7):
          % idx_top = (hr - start_hour)*2
          % idx_bot = (hr - start_hour)*2 + 1
          <div class="w-slot" data-col="{{col}}" data-idx="{{ idx_top }}"
               style="grid-column: {{ col+2 }}; grid-row: {{ idx_top + 2 }};"></div>
          <div class="w-slot" data-col="{{col}}" data-idx="{{ idx_bot }}"
               style="grid-column: {{ col+2 }}; grid-row: {{ idx_bot + 2 }};"></div>
        % end
      % end
    </div>

    <!-- Overlays are inserted by JS to align exactly with each day column -->
  </div>

  <div class="hint">Drag to add. Hold <strong>Shift</strong> to erase. Click a block to delete. Then Save.</div>

  <!-- POST payload -->
  <form method="post" action="/availability">
    <input type="hidden" id="avail_json" name="avail_json" value="">
    <div class="actions" style="margin-top:12px">
      <button class="btn" type="submit" id="save-btn">Save availability</button>
      <a class="btn secondary" href="/home">Cancel</a>
    </div>
  </form>

  <script>
  (function(){
    const grid = document.getElementById('grid');
    grid.style.touchAction = 'none';

    const startHour = parseInt(grid.dataset.startHour, 10);
    const endHour   = parseInt(grid.dataset.endHour, 10);
    const days = {{!repr(days)}};
    const rowsPerDay = (endHour - startHour) * 2;    // 30-min rows

    // Utilities
    const normalize = (a,b)=> a<=b ? [a,b] : [b,a];
    const idxToTime = (i)=>{ const t=startHour*60+i*30, h=Math.floor(t/60), m=t%60; return (h<10?'0':'')+h+':'+(m<10?'0':'')+m; };
    const toIdx = (t)=>{ const [h,m]=t.split(':').map(Number); return (h-startHour)*2 + Math.floor(m/30); };

    // Model (seed from server)
    let blocks = [];
    const initial = {{!repr(avail_ranges)}};
    for(const d of days){ (initial[d]||[]).forEach(r=>blocks.push({day:d,startIdx:toIdx(r.start),endIdxEx:toIdx(r.end)})); }

    // Measure grid and create overlay columns that exactly cover each day column
    const wrap = document.querySelector('.week-wrap');
    const gridRect = grid.getBoundingClientRect();

    // For each column: compute top/bottom/left/right from actual slots
    const columns = []; // {col,left,right,top,bottom,rowStep, overlayEl, innerEl}
    for(let col=0; col<7; col++){
      const slots = Array.from(grid.querySelectorAll(`.w-slot[data-col="${col}"]`));
      const rects = slots.map(s => s.getBoundingClientRect());
      if (rects.length === 0) continue;

      const left   = Math.min(...rects.map(r => r.left));
      const right  = Math.max(...rects.map(r => r.right));
      const top    = Math.min(...rects.map(r => r.top));
      const bottom = Math.max(...rects.map(r => r.bottom));

      // rowStep: average distance between first two indices that differ by 1
      let step = null;
      const slot0 = grid.querySelector(`.w-slot[data-col="${col}"][data-idx="0"]`);
      const slot1 = grid.querySelector(`.w-slot[data-col="${col}"][data-idx="1"]`);
      if (slot0 && slot1) {
        const r0 = slot0.getBoundingClientRect();
        const r1 = slot1.getBoundingClientRect();
        step = r1.top - r0.top; // includes gap
      } else {
        step = (bottom - top) / rowsPerDay;
      }

      // Create overlay column aligned to this column (absolute inside .week-wrap)
      const overlay = document.createElement('div');
      overlay.className = 'overlay-col';
      overlay.style.left   = (left - gridRect.left) + 'px';
      overlay.style.top    = (top - gridRect.top) + 'px';
      overlay.style.width  = (right - left) + 'px';
      overlay.style.height = (bottom - top) + 'px';
      overlay.style.pointerEvents = 'auto';
      overlay.style.position = 'absolute';

      const inner = document.createElement('div');
      inner.className = 'overlay-inner';
      overlay.appendChild(inner);
      wrap.appendChild(overlay);

      columns[col] = {
        col,
        left: left, right: right, top: top, bottom: bottom,
        rowStep: step,
        overlayEl: overlay,
        innerEl: inner
      };
    }

    // Render all blocks as absolute boxes inside overlay columns
    function renderBlocks(){
      // Clear existing
      columns.forEach(c=>{
        if (!c) return;
        c.innerEl.querySelectorAll('.a-block, .a-ghost').forEach(el=>el.remove());
      });

      for(const bl of blocks){
        const colInfo = columns[days.indexOf(bl.day)];
        if(!colInfo) continue;
        const { innerEl, rowStep } = colInfo;
        const topPx = bl.startIdx * rowStep;
        const hPx   = Math.max(1, (bl.endIdxEx - bl.startIdx) * rowStep);

        const el = document.createElement('div');
        el.className = 'a-block';
        el.style.top    = topPx + 'px';
        el.style.height = hPx + 'px';
        el.innerHTML = `<span class="label">${bl.day} • ${idxToTime(bl.startIdx)}–${idxToTime(bl.endIdxEx)}</span><span style="opacity:.85">▰</span>`;
        el.addEventListener('click', ()=>{
          blocks = blocks.filter(b => !(b.day===bl.day && b.startIdx===bl.startIdx && b.endIdxEx===bl.endIdxEx));
          renderBlocks();
        });
        innerEl.appendChild(el);
      }
    }

    // Merge overlapping blocks per day
    function mergeDay(day){
      const ds = blocks.filter(b=>b.day===day).sort((a,b)=>a.startIdx-b.startIdx);
      const out=[]; for(const b of ds){
        if(!out.length) out.push({...b});
        else {
          const last = out[out.length-1];
          if(b.startIdx <= last.endIdxEx){ last.endIdxEx = Math.max(last.endIdxEx, b.endIdxEx); }
          else out.push({...b});
        }
      }
      blocks = blocks.filter(b=>b.day!==day).concat(out);
    }

    function addBlock(day, s, e){ blocks.push({day,startIdx:s,endIdxEx:e}); mergeDay(day); renderBlocks(); }
    function eraseRange(day, sIdx, eIdx){
      const [s,e] = normalize(sIdx, eIdx); const ex = e+1;
      const out=[];
      for(const b of blocks){
        if(b.day!==day){ out.push(b); continue; }
        if(ex <= b.startIdx || s >= b.endIdxEx){ out.push(b); continue; }
        if(s > b.startIdx) out.push({day, startIdx:b.startIdx, endIdxEx:s});
        if(ex < b.endIdxEx) out.push({day, startIdx:ex, endIdxEx:b.endIdxEx});
      }
      blocks = out; renderBlocks();
    }

    // Map Y (clientY) to nearest idx for a given column
    function yToIdx(colInfo, clientY){
      const y = clientY - colInfo.top;
      let idx = Math.round(y / colInfo.rowStep);
      if (idx < 0) idx = 0;
      if (idx > rowsPerDay - 1) idx = rowsPerDay - 1;
      return idx;
    }

    // Ghost (absolute inside overlay)
    let ghost = null;
    function startGhost(colInfo, idx){
      stopGhost();
      ghost = document.createElement('div');
      ghost.className = 'a-ghost';
      ghost.style.top = (idx * colInfo.rowStep) + 'px';
      ghost.style.height = colInfo.rowStep + 'px';
      colInfo.innerEl.appendChild(ghost);
    }
    function updateGhost(colInfo, a, b){
      const s = Math.min(a,b), e = Math.max(a,b) + 1; // exclusive
      ghost.style.top    = (s * colInfo.rowStep) + 'px';
      ghost.style.height = Math.max(1, (e - s) * colInfo.rowStep) + 'px';
    }
    function stopGhost(){
      if (ghost && ghost.parentNode) ghost.parentNode.removeChild(ghost);
      ghost = null;
    }

    // Drag state
    let dragging = false, eraseMode = false;
    let dragCol = null, dragDay = null, dragStartIdx = null, startX=0, startY=0;

    // Attach handlers to each overlay column so clicks are EASY
    columns.forEach(colInfo=>{
      if(!colInfo) return;

      const el = colInfo.overlayEl;

      el.addEventListener('pointerdown', (e)=>{
        dragging  = true;
        eraseMode = e.shiftKey;
        dragCol   = colInfo;
        dragDay   = days[colInfo.col];
        dragStartIdx = yToIdx(colInfo, e.clientY);
        startX = e.clientX; startY = e.clientY;

        startGhost(colInfo, dragStartIdx);
        if (typeof el.setPointerCapture === 'function') el.setPointerCapture(e.pointerId);
        e.preventDefault();
      });

      el.addEventListener('pointermove', (e)=>{
        if(!dragging || !ghost || dragCol !== colInfo) return;
        const idx = yToIdx(colInfo, e.clientY);
        updateGhost(colInfo, dragStartIdx, idx);
      });

      el.addEventListener('pointerup', (e)=>{
        if(!dragging || dragCol !== colInfo) return;

        const idx = yToIdx(colInfo, e.clientY);
        const dist = Math.hypot(e.clientX - startX, e.clientY - startY);
        const isClick = dist < 3;

        if (eraseMode) {
          if (isClick) eraseRange(dragDay, dragStartIdx, dragStartIdx);
          else eraseRange(dragDay, dragStartIdx, idx);
        } else {
          if (isClick) addBlock(dragDay, dragStartIdx, dragStartIdx+1);
          else { const [s,e2] = normalize(dragStartIdx, idx); addBlock(dragDay, s, e2+1); }
        }

        dragging=false; eraseMode=false; dragCol=null; dragDay=null; dragStartIdx=null; stopGhost();
        if (typeof el.releasePointerCapture === 'function') el.releasePointerCapture(e.pointerId);
      });
    });

    // Buttons
    document.getElementById('clear-all')?.addEventListener('click', ()=>{ blocks = []; renderBlocks(); });
    document.getElementById('preset-workdays')?.addEventListener('click', ()=>{
      blocks = blocks.filter(b => !['Mon','Tue','Wed','Thu','Fri'].includes(b.day));
      const s = (9 - startHour) * 2;
      const e = (17 - startHour) * 2; // exclusive
      for(let i=0;i<5;i++){
        blocks.push({ day: days[i], startIdx: s, endIdxEx: e });
      }
      ['Mon','Tue','Wed','Thu','Fri'].forEach(mergeDay);
      renderBlocks();
    });

    // Save
    document.getElementById('save-btn')?.addEventListener('click', ()=>{
      const out={}; for(const d of days){ out[d]=[]; }
      for(const b of blocks){ out[b.day].push({ start: idxToTime(b.startIdx), end: idxToTime(b.endIdxEx) }); }
      for(const d of days){ out[d].sort((x,y)=> (x.start<y.start?-1:1)); }
      document.getElementById('avail_json').value = JSON.stringify(out);
    });

    // Initial paint
    renderBlocks();

    // Surface runtime errors
    window.addEventListener('error', ev => console.error('Availability error:', ev.error||ev.message));
  })();
  </script>
</section>

% include("shell_bottom")