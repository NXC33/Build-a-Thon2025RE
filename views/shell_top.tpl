<!doctype html>
<html lang="en" data-theme="{{ theme if defined('theme') else 'dark' }}">
<head>
  <meta charset="utf-8" />
  <title>{{title}}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    :root{
      --bg:#0f172a;         /* slate-900 */
      --panel:#111827ee;    /* gray-900 alpha */
      --muted:#94a3b8;      /* slate-400 */
      --text:#e5e7eb;       /* gray-200 */
      --accent:#6366f1;     /* indigo-500 */
      --accent2:#8b5cf6;    /* violet-500 */
      --ring:#c7d2fe;       /* indigo-200 */
      --border:rgba(148,163,184,.18);
      --shadow:0 10px 30px rgba(0,0,0,.35), 0 2px 6px rgba(0,0,0,.25);
      --radius:16px;
    }
    *{box-sizing:border-box}
    html,body{height:100%}
    body{
      margin:0; font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial;
      background: radial-gradient(1200px 700px at 20% -10%, #1f2937 10%, transparent 60%),
                  radial-gradient(1000px 600px at 110% 10%, #1e293b 10%, transparent 60%),
                  linear-gradient(180deg, #0b1220, #0f172a);
      color:var(--text);
    }
    /* Light theme overrides */
    html[data-theme="light"] {
    --bg:#f8fafc;
    --panel:#ffffffee;
    --muted:#64748b;
    --text:#0f172a;
    --border:rgba(15,23,42,.12);
    --shadow:0 10px 30px rgba(2,6,23,.08), 0 2px 6px rgba(2,6,23,.06);
    }

    /* Use background based on theme */
    body{
    margin:0; font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial;
    background:
        radial-gradient(1200px 700px at 20% -10%, rgba(31,41,55,.35) 10%, transparent 60%),
        radial-gradient(1000px 600px at 110% 10%, rgba(30,41,59,.35) 10%, transparent 60%),
        linear-gradient(180deg, var(--bg), var(--bg));
    color:var(--text);
    }
    /* Layout */
    .topbar{
      position:sticky; top:0; z-index:20;
      display:flex; align-items:center; justify-content:space-between;
      padding:14px 20px; border-bottom:1px solid var(--border);
      background:rgba(2,6,23,.6); backdrop-filter:blur(8px);
    }
    .brand{font-weight:700; letter-spacing:.3px}
    .shell{display:grid; grid-template-columns:260px 1fr; gap:16px; padding:16px; min-height:calc(100vh - 60px)}
    .sidebar{
      background:var(--panel); border:1px solid var(--border); border-radius:var(--radius);
      padding:14px; height:fit-content; position:sticky; top:84px;
    }
    .main{display:grid; gap:16px}
    .row{display:grid; grid-template-columns:1.1fr .9fr; gap:16px}
    @media (max-width: 980px){
      .shell{grid-template-columns:1fr}
      .row{grid-template-columns:1fr}
      .sidebar{position:static}
    }

    /* Sidebar */
    .nav a{
      display:flex; align-items:center; gap:10px;
      padding:10px 12px; border-radius:12px; color:var(--text);
      text-decoration:none; border:1px solid transparent;
    }
    .nav a:hover{background:rgba(148,163,184,.08); border-color:var(--border)}
    .nav a.active{background:linear-gradient(135deg,var(--accent),var(--accent2)); border-color:transparent}

    /* Cards & text */
    .card{
      background:var(--panel); border:1px solid var(--border); border-radius:var(--radius);
      box-shadow:var(--shadow); padding:18px
    }
    .card h2{margin:0 0 10px; font-size:18px}
    .muted{color:var(--muted); font-size:14px}

    /* Buttons */
    .btn{
      display:inline-block; padding:10px 14px; border-radius:12px; font-weight:600; text-decoration:none;
      background:linear-gradient(135deg,var(--accent),var(--accent2)); color:#fff; border:0; cursor:pointer
    }
    .btn.secondary{
      background:transparent; color:var(--text); border:1px solid var(--border)
    }
    .actions{display:flex; gap:10px; flex-wrap:wrap; margin-top:12px}

    /* Account dropdown (stable hover/focus) */
    .account{position:relative; padding-bottom:10px;}
    .acct-btn{
      display:flex; align-items:center; gap:10px; padding:8px 12px;
      background:rgba(2,6,23,.6); border:1px solid var(--border);
      border-radius:999px; cursor:pointer; text-decoration:none; color:var(--text); outline:0;
    }
    .acct-btn:focus{ box-shadow:0 0 0 3px rgba(99,102,241,.35); border-color:var(--ring); }
    .avatar{
      width:28px; height:28px; border-radius:999px; background:linear-gradient(135deg,var(--accent),var(--accent2));
      display:grid; place-items:center; font-size:13px; font-weight:700; color:white
    }
    .menu{
      position:absolute; right:0; top:calc(100% + 6px); min-width:200px; padding:8px;
      background:var(--panel); border:1px solid var(--border); border-radius:14px; box-shadow:var(--shadow);
      opacity:0; visibility:hidden; transition:opacity .12s ease, visibility .12s ease;
    }
    .menu a{
      display:block; color:var(--text); text-decoration:none; padding:10px 10px; border-radius:10px
    }
    .menu a:hover{background:rgba(148,163,184,.08)}
    .account:hover .menu, .account:focus-within .menu{opacity:1; visibility:visible}

    /* Keyboard hint (optional) */
    .top-actions{display:flex; gap:10px}
    .kbd{font:11px ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; color:var(--muted)}
  </style>
</head>
<body>
  <!-- Top Bar -->
  <header class="topbar">
    <a class="brand" href="/home" style="text-decoration:none;color:var(--text)">MeetMatch</a>
    <div class="top-actions">
      <div class="account">
        <a class="acct-btn" href="#" tabindex="0" aria-haspopup="true" aria-expanded="false">
          <div class="avatar">{{ (user_name if defined('user_name') else 'User')[0] }}</div>
          <span>{{ user_name if defined('user_name') else 'User' }}</span>
        </a>
        <div class="menu" role="menu">
          <a href="/account" role="menuitem">Account details</a>
          <a href="/settings" role="menuitem">Settings</a>
          <a href="/login" role="menuitem">Log out</a>
        </div>
      </div>
    </div>
  </header>

  <!-- Body -->
  <div class="shell">
    <!-- Sidebar -->
    <aside class="sidebar">
      <nav class="nav">
        <a href="/home">Home</a>
        <a href="/availability">Availability</a>
        <a href="/request">Request Meeting</a>
        <a href="/meetings">My Meetings</a>
        <a href="/account-setup">Account Setup</a>
        <a href="/help">Help</a>
      </nav>
    </aside>

    <!-- Main -->
    <main class="main">