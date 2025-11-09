% include("shell_top", title="Account")

<style>
  /* ✅ force the account cards to be short */
  .account-card {
    min-height: 150px;   /* ↓ adjust smaller or larger if needed */
    height: fit-content; /* keeps it compact */
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
  }
</style>

<main class="main">

  <section class="row">

    <!-- Profile -->
    <div class="card account-card">
      <h2>Profile</h2>

      % if ok:
        <div style="padding:10px;border-radius:10px;background:rgba(34,197,94,.08);
                    border:1px solid rgba(34,197,94,.3);color:#22c55e;margin-bottom:12px">
          {{ok}}
        </div>
      % end

      % if err:
        <div style="padding:10px;border-radius:10px;background:rgba(239,68,68,.08);
                    border:1px solid rgba(239,68,68,.3);color:#ef4444;margin-bottom:12px">
          {{err}}
        </div>
      % end

      <form method="post" action="/account" style="display:grid;gap:8px">
        <input type="hidden" name="action" value="profile">

        <label>Name
          <input name="name" value="{{user.get('name','')}}" required
                 style="width:100%;padding:8px;border-radius:10px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>

        <label>Email
          <input name="email" value="{{user.get('email','')}}" required
                 style="width:100%;padding:8px;border-radius:10px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>

        <div class="actions">
          <button class="btn" type="submit">Save</button>
        </div>
      </form>
    </div>


    <!-- Password -->
    <div class="card account-card">
      <h2>Change Password</h2>

      <form method="post" action="/account" style="display:grid;gap:8px">
        <input type="hidden" name="action" value="password">

        <label>New password
          <input name="new_password" type="password" required minlength="4"
                 style="width:100%;padding:8px;border-radius:10px;border:1px solid var(--border);
                        background:rgba(2,6,23,.55);color:var(--text)">
        </label>

        <div class="actions">
          <button class="btn" type="submit">Update</button>
        </div>
      </form>
    </div>

  </section>

</main>

% include("shell_bottom")