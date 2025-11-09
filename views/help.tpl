% include("shell_top", title="Help")

<main class="main">
  <section class="card" style="grid-column:1 / -1">
    <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap">
      <div>
        <h2 style="margin:0">Help & Support</h2>
        <div class="muted">Submit a ticket and we’ll take a look.</div>
      </div>
      <!-- removed the My Meetings button -->
    </div>

    % if ok:
      <div style="margin-top:12px;padding:10px;border-radius:10px;background:rgba(34,197,94,.10);
                  border:1px solid rgba(34,197,94,.25);color:#16a34a">
        {{ok}}
      </div>
    % end
    % if err:
      <div style="margin-top:12px;padding:10px;border-radius:10px;background:rgba(239,68,68,.10);
                  border:1px solid rgba(239,68,68,.25);color:#ef4444">
        {{err}}
      </div>
    % end

    <form method="post" action="/help" style="margin-top:16px;display:grid;gap:12px">
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
        <label>Name
          <input name="name" value="{{pre_name or ''}}"
                 style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>
        <label>Email
          <input name="email" value="{{pre_email or ''}}"
                 style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px">
        <label>Category
          <select name="category"
                  style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                         background:rgba(2,6,23,.55);color:var(--text)">
            <option>Scheduling</option>
            <option>Account</option>
            <option>Availability</option>
            <option>Bug</option>
            <option selected>Other</option>
          </select>
        </label>
        <label>Urgency
          <select name="urgency"
                  style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                         background:rgba(2,6,23,.55);color:var(--text)">
            <option>Low</option>
            <option selected>Normal</option>
            <option>High</option>
          </select>
        </label>
        <label>Subject
          <input name="subject" required placeholder="Brief summary"
                 style="width:100%;padding:10px;border-radius:12px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>
      </div>

      <label>Description
        <textarea name="description" rows="6" required placeholder="What happened? What did you expect?"
                  style="width:100%;padding:12px;border-radius:12px;border:1px solid var(--border);
                         background:rgba(2,6,23,.55);color:var(--text)"></textarea>
      </label>

      <div class="actions" style="margin-top:4px">
        <button class="btn" type="submit">Submit ticket</button>
      </div>
    </form>

    <div class="card" style="margin-top:16px;background:rgba(2,6,23,.35)">
      <h3 style="margin:0 0 8px">Quick tips</h3>
      <ul class="muted" style="margin:0;padding-left:18px;line-height:1.6">
        <li>Include the page (Home / Availability / Request / Meetings) in the subject.</li>
        <li>Describe steps to reproduce any bug you saw.</li>
        <li>If it’s a scheduling conflict, list teacher + time windows.</li>
      </ul>
    </div>
  </section>
</main>

% include("shell_bottom")