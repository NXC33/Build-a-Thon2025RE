<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Create account</title>
  <style>
    body{margin:0;min-height:100vh;display:grid;place-items:center;background:#0f172a;
         font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial}
    .card{width:100%;max-width:440px;background:#111827ee;color:#e5e7eb;border-radius:16px;
          padding:28px;border:1px solid rgba(148,163,184,.15)}
    h1{margin:0 0 6px;font-size:24px}
    p.sub{margin:0 0 18px;color:#94a3b8;font-size:14px}
    label{display:block;font-size:13px;color:#94a3b8;margin:14px 0 6px}
    input,select{width:100%;padding:12px 14px;border-radius:10px;background:rgba(2,6,23,.65);
                 border:1px solid rgba(148,163,184,.25);color:#e5e7eb;font-size:15px;outline:0}
    .row{display:flex;gap:12px;margin-top:18px}
    .btn{flex:1;padding:12px 16px;border:0;border-radius:10px;color:#fff;cursor:pointer;
         background:linear-gradient(135deg,#6366f1,#8b5cf6);font-weight:600}
    .btn.secondary{background:transparent;border:1px solid rgba(148,163,184,.35)}
    .error{margin-top:10px;padding:10px 12px;border-radius:10px;font-size:13px;
           color:#fecaca;background:rgba(239,68,68,.1);border:1px solid rgba(239,68,68,.25)}
    .ok{margin-top:10px;padding:10px 12px;border-radius:10px;font-size:13px;
        color:#bbf7d0;background:rgba(34,197,94,.1);border:1px solid rgba(34,197,94,.25)}
  </style>
</head>
<body>
  <form class="card" method="post" action="/signup">
    <h1>Create account</h1>
    <p class="sub">Join to schedule meetings.</p>

    % if defined('error') and error:
      <div class="error">{{error}}</div>
    % end
    % if defined('ok') and ok:
      <div class="ok">{{ok}}</div>
    % end

    <label for="name">Full name</label>
    <input id="name" name="name" type="text" placeholder="Your name" required>

    <label for="email">School email</label>
    <input id="email" name="email" type="email" placeholder="you@school.edu" required>

    <label for="role">Role</label>
    <select id="role" name="role" required>
      <option value="student">Student</option>
      <option value="teacher">Teacher</option>
    </select>

    <label for="password">Password</label>
    <input id="password" name="password" type="password" placeholder="••••••••" required>

    <div class="row">
      <button class="btn" type="submit">Create account</button>
      <a class="btn secondary" href="/login" role="button">Back to login</a>
    </div>
  </form>
</body>
</html>
