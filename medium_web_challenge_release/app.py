import os
import sqlite3
from pathlib import Path

from flask import Flask, g, redirect, render_template_string, request, session, url_for


BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / "challenge.db"

app = Flask(__name__)
app.secret_key = "medium-web-idor-lab-secret"


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(error):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    db = sqlite3.connect(DB_PATH)
    db.executescript(
        """
        DROP TABLE IF EXISTS users;
        DROP TABLE IF EXISTS profiles;

        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            role TEXT NOT NULL
        );

        CREATE TABLE profiles (
            user_id INTEGER PRIMARY KEY,
            display_name TEXT NOT NULL,
            department TEXT NOT NULL,
            note TEXT NOT NULL,
            secret_attachment TEXT NOT NULL
        );

        INSERT INTO users (id, username, password, role) VALUES
            (1, 'admin', 'not_for_red_team_2026', 'admin'),
            (3, 'employee', 'pass1234', 'employee');

        INSERT INTO profiles (user_id, display_name, department, note, secret_attachment) VALUES
            (
                1,
                'System Administrator',
                'Security Office',
                'Confidential profile. This record should only be visible to administrators.',
                'RkxBR3tJRE9SX3Byb2ZpbGVfbGVha30='
            ),
            (
                3,
                'TW-Corp Employee',
                'IT Support',
                'Normal employee profile. Internal systems should only show your own data.',
                'No confidential attachment for this account.'
            );
        """
    )
    db.commit()
    db.close()


@app.before_request
def log_request():
    print(
        "REQUEST "
        f"remote={request.remote_addr} "
        f"method={request.method} "
        f"path={request.path} "
        f"profile_id={request.args.get('id', '-')} "
        f"session_user={session.get('username', '-')}",
        flush=True,
    )


def current_user():
    user_id = session.get("user_id")
    if not user_id:
        return None
    return get_db().execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()


@app.route("/")
def index():
    if current_user():
        return redirect(url_for("profile", id=session.get("user_id")))
    return redirect(url_for("login"))


@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        username = request.form.get("username", "")
        password = request.form.get("password", "")

        # Intentional vulnerability for CTF: string concatenation allows SQL injection.
        query = (
            "SELECT * FROM users WHERE username = '"
            + username
            + "' AND password = '"
            + password
            + "'"
        )

        try:
            user = get_db().execute(query).fetchone()
        except sqlite3.Error as exc:
            error = f"Login query error: {exc}"
            user = None

        if user:
            session.clear()
            session["user_id"] = user["id"]
            session["username"] = user["username"]
            session["role"] = user["role"]
            return redirect(url_for("profile", id=user["id"]))

        if error is None:
            error = "Invalid username or password."

    return render_template_string(LOGIN_TEMPLATE, error=error)


@app.route("/profile")
def profile():
    user = current_user()
    if not user:
        return redirect(url_for("login"))

    requested_id = request.args.get("id", str(user["id"]))
    profile_row = get_db().execute(
        """
        SELECT users.id, users.username, users.role,
               profiles.display_name, profiles.department,
               profiles.note, profiles.secret_attachment
        FROM users
        JOIN profiles ON profiles.user_id = users.id
        WHERE users.id = ?
        """,
        (requested_id,),
    ).fetchone()

    if profile_row is None:
        return render_template_string(PROFILE_NOT_FOUND_TEMPLATE, requested_id=requested_id), 404

    return render_template_string(PROFILE_TEMPLATE, user=user, profile=profile_row)


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


LOGIN_TEMPLATE = """
<!doctype html>
<html lang="zh-Hant">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>TW-Corp Employee Portal</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #eef2f5; color: #1d2b36; }
    main { max-width: 420px; margin: 9vh auto; background: #fff; padding: 28px; border: 1px solid #d8e0e7; border-radius: 8px; }
    h1 { margin: 0 0 8px; font-size: 24px; }
    p { color: #566774; line-height: 1.5; }
    label { display: block; margin-top: 16px; font-weight: 700; }
    input { width: 100%; box-sizing: border-box; margin-top: 6px; padding: 10px; border: 1px solid #b8c5cf; border-radius: 4px; font-size: 16px; }
    button { margin-top: 20px; width: 100%; padding: 11px; border: 0; border-radius: 4px; background: #146c78; color: #fff; font-size: 16px; font-weight: 700; }
    .error { padding: 10px; background: #ffecec; border: 1px solid #f3b6b6; color: #8a1f1f; border-radius: 4px; }
    .hint { font-size: 14px; color: #667985; }
  </style>
</head>
<body>
  <main>
    <h1>TW-Corp Employee Portal</h1>
    <p>Sign in with your employee account to view your internal profile.</p>
    {% if error %}<div class="error">{{ error }}</div>{% endif %}
    <form method="post">
      <label for="username">Username</label>
      <input id="username" name="username" autocomplete="username">
      <label for="password">Password</label>
      <input id="password" name="password" type="password" autocomplete="current-password">
      <button type="submit">Sign in</button>
    </form>
    <p class="hint">Provided account: employee / pass1234</p>
  </main>
</body>
</html>
"""


PROFILE_TEMPLATE = """
<!doctype html>
<html lang="zh-Hant">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Profile {{ profile.id }}</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #eef2f5; color: #1d2b36; }
    header { background: #1c3447; color: #fff; padding: 18px 32px; display: flex; justify-content: space-between; align-items: center; }
    header a { color: #c8f3f6; text-decoration: none; }
    main { max-width: 760px; margin: 40px auto; background: #fff; border: 1px solid #d8e0e7; border-radius: 8px; padding: 28px; }
    h1 { margin: 0 0 6px; }
    dl { display: grid; grid-template-columns: 160px 1fr; gap: 12px 20px; }
    dt { font-weight: 700; color: #516373; }
    dd { margin: 0; }
    code { display: inline-block; padding: 4px 6px; background: #edf6f7; border-radius: 4px; }
    .notice { margin-top: 24px; padding: 14px; background: #fff9e5; border: 1px solid #ead58a; border-radius: 4px; }
  </style>
</head>
<body>
  <header>
    <div>TW-Corp Employee Portal</div>
    <a href="{{ url_for('logout') }}">Logout {{ user.username }}</a>
  </header>
  <main>
    <h1>{{ profile.display_name }}</h1>
    <p>Profile record #{{ profile.id }}</p>
    <dl>
      <dt>Username</dt><dd>{{ profile.username }}</dd>
      <dt>Role</dt><dd>{{ profile.role }}</dd>
      <dt>Department</dt><dd>{{ profile.department }}</dd>
      <dt>Internal Note</dt><dd>{{ profile.note }}</dd>
      <dt>Attachment</dt><dd><code>{{ profile.secret_attachment }}</code></dd>
    </dl>
    <div class="notice">
      You are signed in as <strong>{{ user.username }}</strong>. This portal is under maintenance.
    </div>
  </main>
</body>
</html>
"""


PROFILE_NOT_FOUND_TEMPLATE = """
<!doctype html>
<html lang="zh-Hant">
<head><meta charset="utf-8"><title>Not Found</title></head>
<body>
  <h1>Profile not found</h1>
  <p>No profile exists for id {{ requested_id }}.</p>
  <p><a href="{{ url_for('index') }}">Back</a></p>
</body>
</html>
"""


if __name__ == "__main__":
    if not DB_PATH.exists() or os.environ.get("RESET_DB") == "1":
        init_db()
    app.run(host="0.0.0.0", port=5000)
