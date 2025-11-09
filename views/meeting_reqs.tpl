% include("shell_top", title="Request Meeting")

<main class="main">
  <section class="card" style="grid-column:1 / -1">
    <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap">
      <div>
        <h2 style="margin:0">Request a Meeting</h2>
        <div class="muted">Find a teacher by subject or by your saved availability.</div>
      </div>
      <a class="btn secondary" href="/meetings">My Meetings</a>
    </div>

    <!-- Mode toggle -->
    <div style="display:flex;gap:8px;margin-top:12px">
      <button type="button" id="btnByTeacher" class="btn">By Teacher</button>
      <button type="button" id="btnByAvail" class="btn secondary">By My Availability</button>
    </div>

    <!-- Filters -->
    <div style="display:flex;gap:12px;flex-wrap:wrap;margin-top:12px">
      <label class="muted">Subject
        <select id="subjectFilter" style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
          <option value="">Any</option>
          % for s in subjects:
            <option value="{{s}}">{{s}}</option>
          % end
        </select>
      </label>
      <label class="muted">Urgency
        <select id="urgency" style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
          <option>Normal</option>
          <option>High</option>
          <option>Low</option>
        </select>
      </label>
      <label class="muted">Duration
        <select id="duration" style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
          <option value="15">15 min</option>
          <option value="20" selected>20 min</option>
          <option value="30">30 min</option>
        </select>
      </label>
    </div>

    <!-- By Teacher -->
    <div id="panelByTeacher" style="margin-top:16px;display:grid;grid-template-columns:1.1fr .9fr;gap:16px">
      <!-- Teacher list -->
      <div class="card" style="background:rgba(2,6,23,.35);">
        <h3 style="margin:0 0 8px">Teachers</h3>
        <div id="teacherList" style="display:grid;gap:10px"></div>
      </div>

      <!-- Slot picker + reason -->
      <div class="card" style="background:rgba(2,6,23,.35);display:grid;gap:12px">
        <h3 style="margin:0">Pick a time</h3>
        <div class="muted" id="pickedTeacher">Select a teacher to see available times.</div>
        <label>Available slots
          <select id="slotSelect" disabled
                  style="width:100%;padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)"></select>
        </label>
        <label>Reason
          <textarea id="reason1" rows="3" placeholder="Why do you want to meet?"
                    style="width:100%;padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)"></textarea>
        </label>
        <div class="actions">
          <button class="btn" id="submitByTeacher" disabled>Request meeting</button>
        </div>
      </div>
    </div>

    <!-- By My Availability (sorted list of teachers with overlapping slots) -->
    <div id="panelByAvail" style="margin-top:16px;display:none">
      <div class="card" style="background:rgba(2,6,23,.35);">
        <h3 style="margin:0 0 8px">Matches with your availability</h3>
        <div class="muted">Sorted by number of overlapping slots. Change duration to recompute.</div>
        <div id="matchList" style="display:grid;gap:10px;margin-top:10px"></div>
      </div>
    </div>

    <!-- Hidden form that submits to backend -->
    <form id="requestForm" method="post" action="/request" style="display:none">
      <input name="mode" id="f_mode">
      <input name="subject" id="f_subject">
      <input name="urgency" id="f_urgency">
      <input name="duration" id="f_duration">
      <input name="teacher" id="f_teacher">
      <input name="day" id="f_day">
      <input name="start" id="f_start">
      <input name="end" id="f_end">
      <input name="reason" id="f_reason">
    </form>
  </section>
</main>

<script>
(function(){
  // ---- Data from server
  const DAYS = {{!repr(days)}};
  const START_H = {{start_hour}};
  const END_H   = {{end_hour}};
  const TEACHERS = {{!repr(teachers)}};
  const USER_RANGES = {{!repr(user_ranges)}}; // {Mon:[{start,end},...], ...}

  // ---- Elements
  const btnTeacher = document.getElementById('btnByTeacher');
  const btnAvail   = document.getElementById('btnByAvail');
  const panelTeacher = document.getElementById('panelByTeacher');
  const panelAvail   = document.getElementById('panelByAvail');

  const subjectSel = document.getElementById('subjectFilter');
  const urgencySel = document.getElementById('urgency');
  const durationSel= document.getElementById('duration');

  const teacherList = document.getElementById('teacherList');
  const pickedTeacher = document.getElementById('pickedTeacher');
  const slotSelect = document.getElementById('slotSelect');
  const reason1 = document.getElementById('reason1');
  const submitByTeacher = document.getElementById('submitByTeacher');

  const matchList = document.getElementById('matchList');

  // form
  const f_mode = document.getElementById('f_mode');
  const f_subject = document.getElementById('f_subject');
  const f_urgency = document.getElementById('f_urgency');
  const f_duration = document.getElementById('f_duration');
  const f_teacher = document.getElementById('f_teacher');
  const f_day = document.getElementById('f_day');
  const f_start = document.getElementById('f_start');
  const f_end = document.getElementById('f_end');
  const f_reason = document.getElementById('f_reason');
  const form = document.getElementById('requestForm');

  // Helpers
  function hhmm(h, m){ return `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}`; }
  function addMin(t, m){
    const [h,mi]=t.split(':').map(Number); const tot=h*60+mi+m;
    return hhmm(Math.floor(tot/60), tot%60);
  }
  function rowsBetween(a,b){
    const [h1,m1]=a.split(':').map(Number), [h2,m2]=b.split(':').map(Number);
    return Math.max(1, ((h2*60+m2)-(h1*60+m1))/30|0);
  }
  function timeToMin(t){ const [h,m]=t.split(':').map(Number); return h*60+m; }
  function withinRange(day, start, end){
    const arr = USER_RANGES[day] || [];
    const s = timeToMin(start), e = timeToMin(end);
    for(const r of arr){
      const rs = timeToMin(r.start), re = timeToMin(r.end);
      if (s >= rs && e <= re) return true;
    }
    return false;
  }

  // Mode switch
  function setMode(mode){
    if(mode==='teacher'){
      panelTeacher.style.display='grid';
      panelAvail.style.display='none';
      btnTeacher.classList.remove('secondary');
      btnAvail.classList.add('secondary');
    }else{
      panelTeacher.style.display='none';
      panelAvail.style.display='block';
      btnAvail.classList.remove('secondary');
      btnTeacher.classList.add('secondary');
      renderMatches(); // compute when entering this mode
    }
  }
  btnTeacher.onclick=()=>setMode('teacher');
  btnAvail.onclick=()=>setMode('avail');
  setMode('teacher');

  // ---------- By Teacher ----------
  function renderTeachers(){
    const want = subjectSel.value;
    teacherList.innerHTML='';
    TEACHERS.forEach(t=>{
      const ok = !want || (t.subjects||[]).includes(want);
      if(!ok) return;
      const card = document.createElement('div');
      card.className='item';
      card.style.background='rgba(2,6,23,.55)';
      card.style.cursor='pointer';
      card.innerHTML=`
        <div>
          <div><strong>${t.name}</strong></div>
          <div class="muted" style="font-size:12px">${(t.subjects||[]).join(' • ') || '—'}</div>
        </div>
        <span class="pill">select</span>
      `;
      card.onclick=()=>selectTeacher(t);
      teacherList.appendChild(card);
    });
  }
  subjectSel.onchange=()=>{ renderTeachers(); if(panelAvail.style.display==='block') renderMatches(); };
  renderTeachers();

  function selectTeacher(t){
    pickedTeacher.textContent = `Selected: ${t.name}`;
    slotSelect.innerHTML='';
    const dur = parseInt(durationSel.value,10);
    const options=[];
    (t.availability||[]).forEach(a=>{
      (a.times||[]).forEach(start=>{
        const end = addMin(start, dur);
        // also respect the user's availability (optional for this mode; enable if you prefer)
        options.push({label:`${a.day} · ${start}–${end}`, day:a.day, start, end, teacher:t.name});
      });
    });
    options.slice(0,100).forEach(o=>{
      const opt=document.createElement('option');
      opt.value = JSON.stringify(o);
      opt.textContent = o.label;
      slotSelect.appendChild(opt);
    });
    slotSelect.disabled = options.length===0;
    submitByTeacher.disabled = options.length===0;
    f_teacher.value = t.name;
  }
  durationSel.onchange=()=>{
    if(f_teacher.value){
      const t = TEACHERS.find(x=>x.name===f_teacher.value);
      if(t) selectTeacher(t);
    }
    if(panelAvail.style.display==='block') renderMatches();
  };

  submitByTeacher.onclick=()=>{
    const sel = slotSelect.value ? JSON.parse(slotSelect.value) : null;
    if(!sel) return;
    f_mode.value='teacher';
    f_subject.value=subjectSel.value||'';
    f_urgency.value=urgencySel.value||'Normal';
    f_duration.value=durationSel.value||'20';
    f_day.value=sel.day;
    f_start.value=sel.start;
    f_end.value=sel.end;
    f_reason.value=document.getElementById('reason1').value||'';
    form.submit();
  };

  // ---------- By My Availability ----------
  function overlappingSlotsForTeacher(t, dur){
    const out = [];
    (t.availability||[]).forEach(a=>{
      const day = a.day;
      (a.times||[]).forEach(start=>{
        const end = addMin(start, dur);
        if(withinRange(day, start, end)){
          // Subject filter still applies
          const want = subjectSel.value;
          const ok = !want || (t.subjects||[]).includes(want);
          if(ok) out.push({day, start, end});
        }
      });
    });
    return out;
  }

  function renderMatches(){
    const dur = parseInt(durationSel.value,10);
    const rows = TEACHERS.map(t=>{
      const slots = overlappingSlotsForTeacher(t, dur);
      return { teacher:t, slots, count: slots.length };
    }).filter(x=>x.count>0);

    // sort by number of overlapping slots (desc)
    rows.sort((a,b)=>b.count - a.count);

    matchList.innerHTML='';
    if(!rows.length){
      matchList.innerHTML = `<div class="muted">No overlaps with your availability. Try another subject or duration.</div>`;
      return;
    }

    rows.forEach(row=>{
      const wrap = document.createElement('div');
      wrap.className='item';
      wrap.style.background='rgba(2,6,23,.55)';

      // slot selector
      const selectId = 'sel_'+btoa(row.teacher.name).replace(/=/g,'');
      const sel = document.createElement('select');
      sel.id = selectId;
      sel.style.cssText = 'width:100%;padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)';
      row.slots.slice(0,120).forEach(s=>{
        const opt = document.createElement('option');
        opt.value = JSON.stringify({day:s.day, start:s.start, end:s.end, teacher:row.teacher.name});
        opt.textContent = `${s.day} · ${s.start}–${s.end}`;
        sel.appendChild(opt);
      });

      // request button
      const btn = document.createElement('button');
      btn.className='btn';
      btn.textContent='Request';
      btn.onclick=()=>{
        const chosen = sel.value ? JSON.parse(sel.value) : null;
        if(!chosen) return;
        f_mode.value='availability';
        f_subject.value=subjectSel.value||'';
        f_urgency.value=urgencySel.value||'Normal';
        f_duration.value=String(dur);
        f_teacher.value=chosen.teacher;
        f_day.value=chosen.day;
        f_start.value=chosen.start;
        f_end.value=chosen.end;
        f_reason.value=''; // (could add a reason textarea per row if you want)
        form.submit();
      };

      // assemble row
      wrap.innerHTML = `
        <div>
          <div><strong>${row.teacher.name}</strong></div>
          <div class="muted" style="font-size:12px">${(row.teacher.subjects||[]).join(' • ')}</div>
          <div class="muted" style="font-size:12px;margin-top:4px">${row.count} matching slot${row.count===1?'':'s'}</div>
        </div>
      `;
      const right = document.createElement('div');
      right.style.display='grid';
      right.style.gap='8px';
      right.style.minWidth='280px';
      right.appendChild(sel);
      right.appendChild(btn);

      wrap.style.display='grid';
      wrap.style.gridTemplateColumns='1fr 320px';
      wrap.style.alignItems='center';
      wrap.style.gap='12px';

      wrap.appendChild(right);
      matchList.appendChild(wrap);
    });
  }
})();
</script>

% include("shell_bottom")