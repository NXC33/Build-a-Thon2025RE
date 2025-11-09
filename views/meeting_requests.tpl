% rebase('shell_top.tpl', title='Meeting Requests')

<div class="card">
  <h2>Pending Meeting Requests</h2>
  <div class="meetings-list">
    % for meeting in meetings:
      % if meeting.get('status') == 'Pending' and meeting.get('student_request'):
        <div class="meeting-card" style="padding:12px; margin:12px 0; border:1px solid var(--border); border-radius:12px;">
          <div style="margin-bottom:8px">
            <strong>{{meeting['title']}}</strong>
            <span class="muted">with {{meeting['with']}}</span>
          </div>
          <div class="muted">
            {{meeting['day']}} at {{meeting['start']}}
          </div>
          <form method="POST" action="/meetings/respond" style="margin-top:10px">
            <input type="hidden" name="meeting_id" value="{{meeting['id']}}">
            <div class="actions">
              <button type="submit" name="response" value="accept" class="btn">Accept</button>
              <button type="submit" name="response" value="reject" class="btn secondary">Reject</button>
            </div>
          </form>
        </div>
      % end
    % end

    % if not any(m.get('status') == 'Pending' and m.get('student_request') for m in meetings):
      <p class="muted">No pending meeting requests.</p>
    % end
  </div>
</div>

<div class="card">
  <h2>Past Requests</h2>
  <div class="meetings-list">
    % for meeting in meetings:
      % if meeting.get('status') != 'Pending' and meeting.get('student_request'):
        <div class="meeting-card" style="padding:12px; margin:12px 0; border:1px solid var(--border); border-radius:12px;">
          <div style="margin-bottom:8px">
            <strong>{{meeting['title']}}</strong>
            <span class="muted">with {{meeting['with']}}</span>
          </div>
          <div class="muted">
            {{meeting['day']}} at {{meeting['start']}}
            <span style="margin-left:10px; padding:4px 8px; border-radius:999px; font-size:12px; background:{{
              '#22c55a' if meeting.get('status') == 'Confirmed' else '#ef4444'
            }}">{{meeting.get('status')}}</span>
          </div>
        </div>
      % end
    % end
  </div>
</div>