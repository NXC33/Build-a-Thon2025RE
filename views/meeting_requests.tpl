
% include("shell_top", title="Meeting Requests")

<main class="main">

  % # Debug information
  % if defined('meetings'):
    <!-- Found {{len(meetings)}} total meetings -->
  % else:
    <!-- No meetings list provided to template -->
  % end

  <div class="card">
    <h2>Pending Meeting Requests</h2>
    <div class="meetings-list">
      % pending = [m for m in meetings if m.get('status', '').lower() == 'pending' and m.get('student_request')]
      % if pending:
        % for meeting in pending:
          <div class="meeting-card" style="padding:12px; margin:12px 0; border:1px solid var(--border); border-radius:12px;">
            <div style="margin-bottom:8px">
              <strong>{{meeting.get('title', 'Meeting')}}</strong>
              <span class="muted" style="margin-left:8px">with</span>
              <strong style="margin-left:4px">{{meeting.get('with', 'Unknown Student')}}</strong>
            </div>
            <div class="muted" style="margin-bottom:12px">
              <span style="display:inline-block; min-width:80px"><strong>When:</strong></span>
              {{meeting.get('day', '')}} at {{meeting.get('start', '')}}
            </div>
            <form method="POST" action="/meetings/respond" style="margin-top:10px">
              <input type="hidden" name="meeting_id" value="{{meeting.get('id', '')}}">
              <div class="actions" style="display:flex; gap:10px;">
                <button type="submit" name="response" value="accept" class="btn" style="background:var(--accent)">Accept</button>
                <button type="submit" name="response" value="reject" class="btn secondary">Reject</button>
              </div>
            </form>
          </div>
        % end
      % else:
        <div style="text-align:center; padding:30px 20px;">
          <div style="margin-bottom:15px; opacity:0.6">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
          <p class="muted" style="font-size:16px; margin-bottom:8px;">No Pending Meeting Requests</p>
          <p style="color:var(--muted); font-size:14px;">Student meeting requests will appear here when received.</p>
        </div>
      % end
    </div>
  </div>

  <div class="card" style="margin-top:18px">
    <h2>Past Requests</h2>
    <div class="meetings-list">
      % past = [m for m in meetings if m.get('status', '').lower() != 'pending' and m.get('student_request')]
      % if past:
        % for meeting in past:
          <div class="meeting-card" style="padding:12px; margin:12px 0; border:1px solid var(--border); border-radius:12px;">
            <div style="margin-bottom:8px">
              <strong>{{meeting.get('title', 'Meeting')}}</strong>
              <span class="muted" style="margin-left:8px">with</span>
              <strong style="margin-left:4px">{{meeting.get('with', 'Unknown Student')}}</strong>
            </div>
            <div class="muted" style="display:flex; align-items:center;">
              <span style="display:inline-block; min-width:80px"><strong>When:</strong></span>
              {{meeting.get('day', '')}} at {{meeting.get('start', '')}}
              <span style="margin-left:auto; padding:4px 12px; border-radius:999px; font-size:12px; color:white; background:{{
                'var(--accent)' if meeting.get('status') == 'Confirmed' else '#ef4444'
              }}">{{meeting.get('status', 'Unknown')}}</span>
            </div>
          </div>
        % end
      % else:
        <div style="text-align:center; padding:30px 20px;">
          <div style="margin-bottom:15px; opacity:0.6">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p class="muted" style="font-size:16px; margin-bottom:8px;">No Past Meeting Requests</p>
          <p style="color:var(--muted); font-size:14px;">Previous meeting requests you've handled will appear here.</p>
        </div>
      % end
    </div>
  </div>

</main>

% include("shell_bottom")
% include("shell_top", title="Meeting Requests")

<main class="main">

% # Debug information
% if defined('meetings'):
  <!-- Found {{len(meetings)}} total meetings -->
% else:
  <!-- No meetings list provided to template -->
% end

<div class="card">
  <h2>Pending Meeting Requests</h2>
  <div class="meetings-list">
    % pending = [m for m in meetings if m.get('status') == 'Pending' and m.get('student_request')]
    % if pending:
      % for meeting in pending:
        <div class="meeting-card" style="padding:12px; margin:12px 0; border:1px solid var(--border); border-radius:12px;">
          <div style="margin-bottom:8px">
            <strong>{{meeting.get('title', 'Meeting')}}</strong>
            <span class="muted" style="margin-left:8px">with</span>
            <strong style="margin-left:4px">{{meeting.get('with', 'Unknown Student')}}</strong>
          </div>
          <div class="muted" style="margin-bottom:12px">
            <span style="display:inline-block; min-width:80px"><strong>When:</strong></span>
            {{meeting.get('day', '')}} at {{meeting.get('start', '')}}
          </div>
          <form method="POST" action="/meetings/respond" style="margin-top:10px">
            <input type="hidden" name="meeting_id" value="{{meeting.get('id', '')}}">
            <div class="actions" style="display:flex; gap:10px;">
              <button type="submit" name="response" value="accept" class="btn" style="background:var(--accent)">Accept</button>
              <button type="submit" name="response" value="reject" class="btn secondary">Reject</button>
            </div>
          </form>
        </div>
      % end
    % else:
      <div style="text-align:center; padding:30px 20px;">
        <div style="margin-bottom:15px; opacity:0.6">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
        </div>
        <p class="muted" style="font-size:16px; margin-bottom:8px;">No Pending Meeting Requests</p>
        <p style="color:var(--muted); font-size:14px;">Student meeting requests will appear here when received.</p>
      </div>
    % end
  </div>

<div class="card">
  <h2>Past Requests</h2>
  <div class="meetings-list">
    % past = [m for m in meetings if m.get('status') != 'Pending' and m.get('student_request')]
    % if past:
      % for meeting in past:
        <div class="meeting-card" style="padding:12px; margin:12px 0; border:1px solid var(--border); border-radius:12px;">
          <div style="margin-bottom:8px">
            <strong>{{meeting.get('title', 'Meeting')}}</strong>
            <span class="muted" style="margin-left:8px">with</span>
            <strong style="margin-left:4px">{{meeting.get('with', 'Unknown Student')}}</strong>
          </div>
          <div class="muted" style="display:flex; align-items:center;">
            <span style="display:inline-block; min-width:80px"><strong>When:</strong></span>
            {{meeting.get('day', '')}} at {{meeting.get('start', '')}}
            <span style="margin-left:auto; padding:4px 12px; border-radius:999px; font-size:12px; color:white; background:{{
              'var(--accent)' if meeting.get('status') == 'Confirmed' else '#ef4444'
            }}">{{meeting.get('status', 'Unknown')}}</span>
          </div>
        </div>
 
          </main>

          % include("shell_bottom")
        % end
    % else:
      <div style="text-align:center; padding:30px 20px;">
        <div style="margin-bottom:15px; opacity:0.6">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <p class="muted" style="font-size:16px; margin-bottom:8px;">No Past Meeting Requests</p>
        <p style="color:var(--muted); font-size:14px;">Previous meeting requests you've handled will appear here.</p>
      </div>
    % end
  </div>
</div>