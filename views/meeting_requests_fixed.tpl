
% include("shell_top", title="Meeting Requests")

<main class="main">

  % if not defined('meetings'):
    <!-- No meetings provided -->
  % end

  <div class="card">
    <h2>Pending Meeting Requests</h2>
    <div class="meetings-list">
      % pending = [m for m in meetings if m.get('status','').lower() == 'pending' and m.get('student_request')]
      % if pending:
        % for meeting in pending:
          <div class="meeting-card" style="padding:12px; margin:12px 0; border:1px solid var(--border); border-radius:12px;">
            <div style="margin-bottom:8px">
              <strong>{{meeting.get('title','Meeting')}}</strong>
              <span class="muted" style="margin-left:8px">with</span>
              <strong style="margin-left:4px">{{meeting.get('with','Unknown')}}</strong>
            </div>
            <div class="muted">{{meeting.get('day','')}} at {{meeting.get('start','')}}</div>
            <form method="POST" action="/meetings/respond" style="margin-top:8px">
              <input type="hidden" name="meeting_id" value="{{meeting.get('id','')}}">
              <div class="actions">
                <button class="btn" type="submit" name="response" value="accept">Accept</button>
                <button class="btn secondary" type="submit" name="response" value="reject">Reject</button>
              </div>
            </form>
          </div>
        % end
      % else:
        <div style="text-align:center; padding:24px">
          <div class="muted">No pending meeting requests.</div>
        </div>
      % end
    </div>
  </div>

  <div class="card" style="margin-top:16px">
    <h2>Past Requests</h2>
    <div class="meetings-list">
      % past = [m for m in meetings if m.get('status','').lower() != 'pending' and m.get('student_request')]
      % if past:
        % for meeting in past:
          <div class="meeting-card" style="padding:12px; margin:12px 0; border:1px solid var(--border); border-radius:12px;">
            <div style="margin-bottom:8px"><strong>{{meeting.get('title','Meeting')}}</strong></div>
            <div class="muted">{{meeting.get('day','')}} at {{meeting.get('start','')}} — <strong>{{meeting.get('status')}}</strong></div>
          </div>
        % end
      % else:
        <div style="text-align:center; padding:24px">
          <div class="muted">No past meeting requests.</div>
        </div>
      % end
    </div>
  </div>

</main>

% include("shell_bottom")
