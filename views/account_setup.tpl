% include("shell_top", title="Account Setup")

<main class="main">
  <section class="card" style="grid-column:1 / -1">
    <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap">
      <div>
        <h2 style="margin:0">Account Setup</h2>
        <div class="muted">Tell us who you are and what you can teach.</div>
      </div>
      <a class="btn secondary" href="/account">Back to Account</a>
    </div>

    % if defined('ok') and ok:
      <div style="margin-top:12px;padding:10px;border-radius:10px;background:rgba(34,197,94,.10);
                  border:1px solid rgba(34,197,94,.25);color:#4ade80">
        {{ok}}
      </div>
    % end

    % if defined('err') and err:
      <div style="margin-top:12px;padding:10px;border-radius:10px;background:rgba(239,68,68,.10);
                  border:1px solid rgba(239,68,68,.25);color:#ef4444">
        {{err}}
      </div>
    % end

    <form method="post" action="/account-setup" style="margin-top:16px;display:grid;gap:16px">
      <!-- Role + Basic -->
      <div style="display:grid;grid-template-columns:200px 1fr 1fr;gap:12px">
        <label>Role
          <select name="role"
                  style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                         background:rgba(2,6,23,.55);color:var(--text)">
            <option {{'selected' if preset.get('role')=='Student' else ''}}>Student</option>
            <option {{'selected' if preset.get('role')=='Teacher' else ''}}>Teacher</option>
          </select>
        </label>
        <label>Name
          <input name="name" required value="{{preset.get('name','')}}"
                 style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>
        <label>Email
          <input name="email" value="{{preset.get('email','')}}"
                 style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>
      </div>

      <!-- Student-only -->
      <div id="studentBlock" style="display:{{'grid' if preset.get('role','Student')=='Student' else 'none'}};grid-template-columns:1fr 2fr;gap:12px">
        <label>Grade
          <select name="grade"
                  style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                         background:rgba(2,6,23,.55);color:var(--text)">
            % for g in ["Freshman","Sophomore","Junior","Senior"]:
              <option {{'selected' if preset.get('grade')==g else ''}}>{{g}}</option>
            % end
          </select>
        </label>
        <label>Courses (comma separated)
          <input name="courses" value="{{', '.join(preset.get('courses', [])) if preset.get('courses') else ''}}"
                 placeholder="Algebra II, Chemistry, APUSH"
                 style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>
      </div>

      <!-- Teacher-only -->
      <div id="teacherBlock" style="display:{{'grid' if preset.get('role')=='Teacher' else 'none'}};grid-template-columns:1fr;gap:12px">
        <label>Title
          <input name="title" value="{{preset.get('title','')}}" placeholder='e.g., "Mr.", "Ms.", "Dr."'
                 style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>
      </div>

      <!-- Proficiency builder -->
      <div class="card" style="background:rgba(2,6,23,.35);display:grid;gap:12px">
        <h3 style="margin:0">Proficiency</h3>
        <div class="muted">Add subjects and the course labels you’re strong in.</div>

        <div id="profRows" style="display:grid;gap:10px">
          % if preset.get('proficiency'):
            % for subj, labels in preset.get('proficiency').items():
              <div class="item" style="display:grid;grid-template-columns:1fr 2fr 40px;gap:8px;align-items:center;background:rgba(2,6,23,.55)">
                <input name="prof_subject[]" value="{{subj}}" placeholder="Subject (e.g., Math)"
                       style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
                <input name="prof_labels[]" value="{{', '.join(labels)}}" placeholder="Course labels (comma-separated)"
                       style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
                <button class="btn secondary" type="button" onclick="this.parentElement.remove()">✕</button>
              </div>
            % end
          % else:
            <div class="item" style="display:grid;grid-template-columns:1fr 2fr 40px;gap:8px;align-items:center;background:rgba(2,6,23,.55)">
              <input name="prof_subject[]" placeholder="Subject (e.g., Math)"
                     style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
              <input name="prof_labels[]" placeholder="Course labels (comma-separated)"
                     style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
              <button class="btn secondary" type="button" onclick="this.parentElement.remove()">✕</button>
            </div>
          % end
        </div>

        <div class="actions">
          <button class="btn" type="button" id="addRow">Add subject</button>
        </div>
      </div>

      <div class="actions">
        <button class="btn" type="submit">Save</button>
      </div>
    </form>
  </section>
</main>

<script>
(function(){
  const roleSel = document.querySelector('select[name="role"]');
  const student = document.getElementById('studentBlock');
  const teacher = document.getElementById('teacherBlock');
  roleSel.addEventListener('change', ()=>{
    const v = roleSel.value;
    student.style.display = (v==='Student') ? 'grid' : 'none';
    teacher.style.display = (v==='Teacher') ? 'grid' : 'none';
  });

  const profRows = document.getElementById('profRows');
  document.getElementById('addRow').onclick = ()=>{
    const wrap = document.createElement('div');
    wrap.className = 'item';
    wrap.style.cssText = 'display:grid;grid-template-columns:1fr 2fr 40px;gap:8px;align-items:center;background:rgba(2,6,23,.55)';
    wrap.innerHTML = `
      <input name="prof_subject[]" placeholder="Subject (e.g., Science)"
             style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
      <input name="prof_labels[]" placeholder="Course labels (comma-separated)"
             style="padding:10px;border-radius:10px;border:1px solid var(--border);background:rgba(2,6,23,.55);color:var(--text)">
      <button class="btn secondary" type="button">✕</button>
    `;
    wrap.querySelector('button').onclick = ()=>wrap.remove();
    profRows.appendChild(wrap);
  };
})();
</script>

% include("shell_bottom")
