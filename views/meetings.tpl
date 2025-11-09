% include("shell_top", title="My Meetings")

<main class="main">

  <!-- Big calendar card -->
  <section class="card" style="grid-column: 1 / -1">
    <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap">
      <div>
        <h2 style="margin:0">My Meetings</h2>
        <div class="muted">
          Week view • {{ "%02d:00" % start_hour }} → {{ "%02d:00" % end_hour }}
        </div>
      </div>

      <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
        <a class="btn" href="/request">Schedule a meeting</a>
      </div>
    </div>

    <style>
      /* Bigger, cleaner calendar */
      .week-wrap{margin-top:12px}
      .week-grid{
        display:grid;
        grid-template-columns: 84px repeat(7, 1fr);
        grid-template-rows: 40px repeat({{(end_hour - start_hour)*2}}, 32px); /* header + half-hours */
        gap: 8px 8px;
        align-items:start;
      }
      .w-head{font-size:13px; color:var(--muted); display:flex; align-items:center; justify-content:center}
      .w-time{font-size:12px; color:var(--muted); text-align:right; padding-right:6px}
      .w-slot{
        background:rgba(2,6,23,.35);
        border:1px dashed rgba(148,163,184,.18);
        border-radius:10px;
      }

      .m-block{
        position:relative;
        border-radius:12px;
        padding:10px 12px;
        color:#fff;
        box-shadow:var(--shadow);
        border:1px solid rgba(255,255,255,.2);
        display:flex; flex-direction:column; gap:4px;
        overflow:hidden;
      }
      .m-confirmed{ background:linear-gradient(135deg, var(--accent), var(--accent2)); }
      .m-pending{   background:linear-gradient(135deg, #eab308, #f59e0b); }
      .m-cancelled{ background:linear-gradient(135deg, #ef4444, #f43f5e); }

      .m-title{ font-weight:700; font-size:13px; line-height:1.2 }
      .m-sub{ font-size:12px; opacity:.95 }
    </style>

    <!-- Week grid -->
    <div class="week-wrap">
      <div class="week-grid" id="meetGrid">

        <!-- header row -->
        <div></div>
        % for d in days:
          <div class="w-head"><strong>{{d}}</strong></div>
        % end

        <!-- time gutter + background slots -->
        % for hr in range(start_hour, end_hour):
          <div class="w-time" style="grid-row: {{ (hr - start_hour)*2 + 2 }} / span 2;">
            {{ "%02d:00" % hr }}
          </div>
          % for col in range(7):
            % idx_top = (hr - start_hour)*2
            % idx_bot = (hr - start_hour)*2 + 1
            <div class="w-slot" style="grid-column: {{ col+2 }}; grid-row: {{ idx_top + 2 }};"></div>
            <div class="w-slot" style="grid-column: {{ col+2 }}; grid-row: {{ idx_bot + 2 }};"></div>
          % end
        % end

        <!-- Helpers to place meetings -->
        % def row_for(hhmm):
        %   h,m = map(int, hhmm.split(':'))
        %   return 2 + ((h - start_hour)*2 + (m//30))
        % end
        % def span_for(a,b):
        %   h1,m1 = map(int, a.split(':')); h2,m2 = map(int, b.split(':'))
        %   return max(1, ((h2*60+m2)-(h1*60+m1))//30)
        % end
        % def col_for(day_name):
        %   return days.index(day_name) if day_name in days else 0
        % end

        <!-- Render meetings -->
        % for m in meetings:
          % _col = col_for(m.get('day','Mon'))
          % _row = row_for(m.get('start','08:00'))
          % _span = span_for(m.get('start','08:00'), m.get('end','08:30'))
          % st = (m.get('status','Confirmed') or '').lower()
          % cls = 'm-confirmed' if st=='confirmed' else ('m-pending' if st=='pending' else ('m-cancelled' if st=='cancelled' else 'm-confirmed'))
          <div class="m-block {{cls}}"
               data-status="{{st}}"
               style="grid-column: {{ _col+2 }};
                      grid-row-start: {{ _row }};
                      grid-row-end: {{ _row + _span }};">
            <div class="m-title">{{ m.get('title','Meeting') }}</div>
            <div class="m-sub">{{ m.get('day','') }} · {{ m.get('start','') }}–{{ m.get('end','') }}</div>
            % if m.get('with'):
              <div class="m-sub">With {{ m.get('with') }}</div>
            % end
          </div>
        % end

      </div>
    </div>
  </section>
</main>

<script>
  // Simple status filter toggles
  (function(){
    const grid = document.getElementById('meetGrid');
    const boxes = {
      confirmed: document.getElementById('filterConfirmed'),
      pending: document.getElementById('filterPending'),
      cancelled: document.getElementById('filterCancelled')
    };
    function apply(){
      const show = {
        confirmed: boxes.confirmed ? boxes.confirmed.checked : true,
        pending: boxes.pending ? boxes.pending.checked : true,
        cancelled: boxes.cancelled ? boxes.cancelled.checked : true
      };
      grid.querySelectorAll('.m-block').forEach(el=>{
        const st = (el.getAttribute('data-status') || '').toLowerCase();
        const ok = (st==='pending') ? show.pending
                 : (st==='cancelled') ? show.cancelled
                 : show.confirmed; // default confirmed
        el.style.display = ok ? '' : 'none';
      });
    }
    if (boxes.confirmed) boxes.confirmed.addEventListener('change', apply);
    if (boxes.pending) boxes.pending.addEventListener('change', apply);
    if (boxes.cancelled) boxes.cancelled.addEventListener('change', apply);
    apply();
  })();
</script>

<!-- Pending Requests Section -->
<section class="card" style="grid-column: 1 / -1; margin-top: 24px;">
  <h3 style="margin:0 0 12px">Pending Requests</h3>
  
  % pending = [m for m in meetings if m.get('status','').lower() == 'pending']
  % if not pending:
    <div class="muted">No pending meeting requests.</div>
  % else:
    <div style="display:grid; gap:12px;">
      % for m in pending:
        <div class="card" style="background:rgba(2,6,23,.35); display:grid; gap:8px;">
          <div style="display:flex; justify-content:space-between; align-items:start;">
            <div>
              <div><strong>{{m.get('title', 'Meeting')}}</strong></div>
              <div class="muted">With {{m.get('with', '')}} • {{m.get('day', '')}} {{m.get('start', '')}}–{{m.get('end', '')}}</div>
              % if m.get('reason'):
                <div class="muted" style="margin-top:4px">Reason: {{m.get('reason')}}</div>
              % end
            </div>
            
            % if m.get('student_request'):
              <!-- Teacher view -->
              <div style="display:flex; gap:8px;">
                <form method="post" action="/meetings/respond" style="display:inline">
                  <input type="hidden" name="meeting_id" value="{{m.get('id', '')}}">
                  <input type="hidden" name="response" value="accept">
                  <button class="btn">Accept</button>
                </form>
                <form method="post" action="/meetings/respond" style="display:inline">
                  <input type="hidden" name="meeting_id" value="{{m.get('id', '')}}">
                  <input type="hidden" name="response" value="reject">
                  <button class="btn secondary">Reject</button>
                </form>
              </div>
            % else:
              <!-- Student view -->
              <div class="pill warning">Awaiting Response</div>
            % end
          </div>
          
          % if m.get('urgency'):
            <div style="display:flex; gap:8px; align-items:center">
              <div class="pill {{m.get('urgency','Normal').lower()}}">{{m.get('urgency', 'Normal')}} Priority</div>
              % if m.get('subject'):
                <div class="pill">{{m.get('subject')}}</div>
              % end
            </div>
          % end
        </div>
      % end
    </div>
  % end
</section>

<style>
.pill.warning { background: #ca8a04; }
.pill.high { background: #dc2626; }
.pill.normal { background: #2563eb; }
.pill.low { background: #059669; }
</style>

% include("shell_bottom")
