<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Sign in</title>
  <style>
    :root {
      --bg: #0f172a;        /* slate-900 */
      --card: #111827ee;    /* gray-900 w/ alpha */
      --muted: #94a3b8;     /* slate-400 */
      --text: #e5e7eb;      /* gray-200 */
      --accent: #6366f1;    /* indigo-500 */
      --accent-2: #8b5cf6;  /* violet-500 */
      --danger: #ef4444;    /* red-500 */
      --ring: #c7d2fe;      /* indigo-200 */
      --shadow: 0 10px 30px rgba(0,0,0,.35), 0 2px 6px rgba(0,0,0,.25);
    }
    * { box-sizing: border-box; }
    html, body { height: 100%; }
    body {
      margin: 0; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Apple Color Emoji", "Segoe UI Emoji";
      background: radial-gradient(1200px 700px at 20% -10%, #1f2937 10%, transparent 60%),
                  radial-gradient(1000px 600px at 110% 10%, #1e293b 10%, transparent 60%),
                  linear-gradient(180deg, #0b1220, #0f172a);
      color: var(--text); display: grid; place-items: center; padding: 24px;
    }
    .card {
      width: 100%; max-width: 420px; background: var(--card);
      backdrop-filter: blur(8px);
      border: 1px solid rgba(148,163,184,.15);
      border-radius: 16px; padding: 28px; box-shadow: var(--shadow);
      position: relative; overflow: hidden;
    }
    .glow {
      position: absolute; inset: -40% -20% auto auto;
      width: 320px; height: 320px; filter: blur(60px);
      background: conic-gradient(from 180deg at 50% 50%, var(--accent), var(--accent-2), transparent 40%);
      opacity: .35; pointer-events: none;
    }
    h1 { margin: 0 0 6px; font-size: 24px; letter-spacing: .2px; }
    p.sub { margin: 0 0 22px; color: var(--muted); font-size: 14px; }
    label { display: block; font-size: 13px; color: var(--muted); margin: 14px 0 6px; }
    input {
      width: 100%; padding: 12px 14px; border-radius: 10px; font-size: 15px;
      color: var(--text); background: rgba(2,6,23,.65);
      border: 1px solid rgba(148,163,184,.25);
      outline: none; transition: border .15s, box-shadow .15s, background .15s;
    }
    input::placeholder { color: #64748b; }
    input:focus {
      border-color: var(--ring);
      box-shadow: 0 0 0 3px rgba(99,102,241,.25);
      background: rgba(2,6,23,.8);
    }
    .row { display: flex; gap: 12px; align-items: center; justify-content: space-between; margin-top: 18px; }
    .btn {
      appearance: none; border: 0; cursor: pointer;
      padding: 12px 16px; border-radius: 10px; font-weight: 600; letter-spacing: .2px;
      background: linear-gradient(135deg, var(--accent), var(--accent-2));
      color: white; width: 100%; transition: transform .06s ease, filter .15s;
    }
    .btn:hover { filter: brightness(1.05); }
    .btn:active { transform: translateY(1px); }
    .btn.secondary {
      background: transparent; color: var(--text);
      border: 1px solid rgba(148,163,184,.35);
    }
    .error {
      margin-top: 10px; padding: 10px 12px; border-radius: 10px; font-size: 13px;
      color: #fecaca; background: rgba(239,68,68,.1); border: 1px solid rgba(239,68,68,.25);
    }
    .foot {
      margin-top: 14px; font-size: 12px; color: var(--muted); text-align: center;
    }
  </style>
</head>
<body>
  <form class="card" method="post" action="/login">
    <div class="glow"></div>

    <h1>Welcome back</h1>
    <p class="sub">Sign in to schedule a meeting.</p>

    % if defined('error') and error:
      <div class="error">{{error}}</div>
    % end

    % if defined('message') and message:
      <div style="margin-top: 10px; padding: 10px 12px; border-radius: 10px; font-size: 13px;
                 color: #bbf7d0; background: rgba(34,197,94,.1); border: 1px solid rgba(34,197,94,.25);">
        {{message}}
      </div>
    % end

    <label for="email">Email</label>
    <input id="email" name="email" type="email" placeholder="you@school.edu" autocomplete="username" required />

    <label for="password">Password</label>
    <input id="password" name="password" type="password" placeholder="••••••••" autocomplete="current-password" required />

    % if defined('csrf') and csrf:
      <input type="hidden" name="csrf" value="{{csrf}}" />
    % end

    <div class="row">
      <button class="btn" type="submit">Sign in</button>
      <a class="btn secondary" href="/signup" role="button">Create account</a>
    </div>

    <div class="foot">By continuing you agree to our guidelines.</div>
  </form>
</body>
</html>
