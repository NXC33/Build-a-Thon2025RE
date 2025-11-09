% include("shell_top", title="Settings")

<section class="card">
  <h2>Settings</h2>
  <div class="muted">Site preferences</div>

  % if ok:
    <div style="margin-top:12px;padding:10px 12px;border-radius:10px;
         background:rgba(34,197,94,.10);border:1px solid rgba(34,197,94,.25);color:#16a34a;font-size:13px;">
      {{ok}}
    </div>
  % end

  <form method="post" action="/settings" style="margin-top:16px;display:grid;gap:16px">
    <fieldset style="border:1px solid var(--border);border-radius:12px;padding:12px">
      <legend class="muted" style="padding:0 6px">Theme</legend>
      <label style="display:flex;gap:8px;align-items:center;margin-bottom:8px">
        <input type="radio" name="theme" value="dark" {{'checked' if theme=='dark' else ''}}> Dark
      </label>
      <label style="display:flex;gap:8px;align-items:center;margin-bottom:8px">
        <input type="radio" name="theme" value="light" {{'checked' if theme=='light' else ''}}> Light
      </label>
      <label style="display:flex;gap:8px;align-items:center">
        <input type="radio" name="theme" value="system" {{'checked' if theme=='system' else ''}}> System (match device)
      </label>
      <div class="muted" style="margin-top:8px;font-size:12px">
        “System” uses your device’s light/dark preference.
      </div>
    </fieldset>

    <div class="actions">
      <button class="btn" type="submit">Save</button>
      <a class="btn secondary" href="/home">Cancel</a>
    </div>
  </form>
</section>

% include("shell_bottom")