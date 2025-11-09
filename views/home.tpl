% include("shell_top", title="Home")
% if defined('message') and message:
  <div class="banner success">{{message}}</div>
% end
  <!-- Row 1: Calendar (left) + Upcoming (right) -->
<section class="row row--calendar-left">
  <style>
    /* Make the left column a bit wider for the calendar */
    .row--calendar-left { grid-template-columns: 1.25fr .75fr; }
    @media (max-width: 980px){ .row--calendar-left { grid-template-columns: 1fr; } }

    /* Calendar-specific styling (same as before) */
    .week-wrap{margin-top:12px}
    .week-grid{
      display:grid;
      grid-template-columns: 72px repeat(7, 1fr);
      grid-template-rows: 32px repeat({{(end_hour - start_hour)*2}}, 36px); /* header + half-hours */
      gap: 6px 6px; align-items:start;
    }
    .w-head{font-size:12px; color:var(--muted); display:flex; align-items:center; justify-content:center}
    .w-time{font-size:12px; color:var(--muted); text-align:right; padding-right:6px}
    .w-slot{background:rgba(2,6,23,.35); border:1px dashed rgba(148,163,184,.18); border-radius:10px}
    .w-meeting{
      position:relative; background:linear-gradient(135deg, var(--accent), var(--accent2));
      color:#fff; border-radius:10px; padding:8px 10px; font-size:12px; box-shadow:var(--shadow);
      border:1px solid rgba(255,255,255,.2); display:flex; flex-direction:column; gap:2px;
    }
    .w-meeting .sub{opacity:.9; font-size:11px}
    .w-pending{ background:linear-gradient(135deg, #eab308, #f59e0b); }
    .w-cancelled{ background:linear-gradient(135deg, #ef4444, #f43f5e); }
  </style>

  <!-- Calendar (LEFT) -->
  <div class="card">
    <h2>Calendar</h2>
    <div class="muted">Week view • 8:00 → 20:00</div>

    <div class="week-wrap">
      <div class="week-grid">
        <!-- headers -->
        <div></div>
        % for d in days:
          <div class="w-head"><strong>{{d}}</strong></div>
        % end

        <!-- time gutter + empty slots -->
        % for hr in range(start_hour, end_hour):
          <div class="w-time" style="grid-row: {{ (hr - start_hour)*2 + 2 }} / span 2;">
            {{ "%02d:00" % hr }}
          </div>
          % for col in range(7):
            <div class="w-slot" style="grid-column: {{ col+2 }}; grid-row: {{ (hr - start_hour)*2 + 2 }};"></div>
            <div class="w-slot" style="grid-column: {{ col+2 }}; grid-row: {{ (hr - start_hour)*2 + 3 }};"></div>
          % end
        % end

        <!-- meetings -->
        % for m in meetings:
          % cls = 'w-pending' if m.get('status')=='Pending' else ('w-cancelled' if m.get('status')=='Cancelled' else '')
          <div class="w-meeting {{cls}}"
               style="grid-column: {{ day_to_col(m['day']) + 2 }}; grid-row: {{ row_for(m['start']) }} / span {{ row_span(m['start'], m['end']) }};">
            <div><strong>{{ m.get('title','Meeting') }}</strong></div>
            <div class="sub">{{ m['day'] }} · {{ m['start'] }}–{{ m['end'] }}</div>
            % if m.get('with'):
              <div class="sub">With {{ m['with'] }}</div>
            % end
          </div>
        % end
      </div>
    </div>
  </div>

  <!-- Upcoming (RIGHT — original simple style) -->
  <div class="card">
    <h2>Upcoming meetings</h2>
    <div class="muted">Here are your next few meetings.</div>

    <div class="list" style="margin-top:10px">
      % if meetings and len(meetings) > 0:
        % for m in meetings[:5]:
          <div class="item">
            <div>
              <div><strong>{{m['day']}}, {{m['start']}}–{{m['end']}}</strong> • With {{m.get('with','—')}}</div>
              <div class="muted">Reason: {{m.get('title','(no title)')}}</div>
            </div>
            % status = m.get('status', 'Confirmed')
            % if status == 'Pending':
              <span class="pill" style="background:rgba(234,179,8,.15);border-color:rgba(234,179,8,.35);color:#fde68a">Pending</span>
            % elif status == 'Cancelled':
              <span class="pill" style="background:rgba(239,68,68,.15);border-color:rgba(239,68,68,.35);color:#fecaca">Cancelled</span>
            % else:
              <span class="pill">Confirmed</span>
            % end
          </div>
        % end
      % else:
        <div class="muted">No upcoming meetings yet — schedule one below.</div>
      % end
    </div>

    <div class="actions">
      <a class="btn" href="/request">Schedule a meeting</a>
      <a class="btn secondary" href="/meetings">View all</a>
    </div>
  </div>
</section>

<!-- Row 2: Quick actions -->
<section class="card">
  <h2>Quick actions</h2>
  <div class="actions">
    <a class="btn" href="/availability">Set availability</a>
    <a class="btn secondary" href="/account-setup">Account setup</a>
    <a class="btn secondary" href="/request">Request meeting</a>
    <a class="btn secondary" href="/meetings">See meetings</a>
  </div>
</section>

% include("shell_bottom")