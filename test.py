from bottle import Bottle, route, run, template, request, redirect, response #type: ignore
import json, os, uuid, datetime
from helpers.storage import load_availability, save_availability

DAYS = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
START_HOUR = 8
END_HOUR = 20  # 8 pm

from home_utils import (
    DAYS, START_HOUR, END_HOUR,
    day_to_col, row_for, row_span
)
from helpers.account_utils import (
    parse_proficiency, parse_courses,
    save_current_account, load_current_account
)

def current_user() -> str:
    # For hackathon: use cookie if set, else "demo"
    return request.get_cookie("user") or "demo"
ACCOUNT_DIR  = os.path.join(os.path.dirname(__file__), "data")
ACCOUNT_PATH = os.path.join(ACCOUNT_DIR, "account.json")
os.makedirs(ACCOUNT_DIR, exist_ok=True)

DEFAULT_ACCOUNT = {
    "name": "User",
    "email": "",
    "password": ""   # plain text for hackathon simplicity
}

def load_account():
    if not os.path.exists(ACCOUNT_PATH):
        return DEFAULT_ACCOUNT.copy()
    try:
        with open(ACCOUNT_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
    except:
        return DEFAULT_ACCOUNT.copy()

    acc = DEFAULT_ACCOUNT.copy()
    acc.update(data)
    return acc


def save_account(acc):
    with open(ACCOUNT_PATH, "w", encoding="utf-8") as f:
        json.dump(acc, f, indent=2, ensure_ascii=False)

def get_theme():
    # cookie values: 'dark' | 'light' | 'system'
    t = request.get_cookie('theme') or 'dark'
    if t == 'system':
        # optional: map system to dark by default (keeps CSS simple)
        # you can keep returning 'system' too—CSS still works fine
        return 'dark'
    return t

def render(tpl, **kwargs):
    kwargs.setdefault('user_name', 'Nicolas')
    kwargs.setdefault('theme', request.get_cookie('theme') or 'dark')
    return template(tpl, **kwargs)


app = Bottle()

@route('/')
def index():
    return "hello world"
@route('/login', method='GET')
def show_login():
    return render("login")
@route('/login', method=["POST"])
def login_post():
    # ignore authentication for now
    # just go to home
    return redirect('/home')
@route('/signup', method='GET')
def signup_get():
    return render('signup')
@route('/signup', method=["POST"])
def signup_post():
    # ignore storing account for now
    # after submitting form → go to login
    return redirect("/login")
@route('/home')
def home():
    meetings = [
        {"day":"Mon","start":"10:30","end":"11:30","title":"Test review","with":"Ms. Rivera","status":"Confirmed"},
        {"day":"Tue","start":"14:15","end":"14:30","title":"Project help","with":"Mr. Lee","status":"Pending"},
        {"day":"Wed","start":"09:00","end":"10:00","title":"Counselor check-in","with":"Dr. Adams","status":"Confirmed"},
    ]
    return render("home",
        days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
        meetings=meetings, day_to_col=day_to_col, row_for=row_for, row_span=row_span)

@route('/availability', method='GET')
def availability_get():
    user = current_user()
    avail_ranges = load_availability(user, DAYS)
    return render('availability',
                    ok=request.query.get('saved') and "Availability saved.",
                    days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                    avail_ranges=avail_ranges)

@route('/availability', method='POST')
def availability_post():
    user = current_user()
    raw = request.forms.get('avail_json') or "{}"
    try:
        data = json.loads(raw)
    except Exception:
        data = {d: [] for d in DAYS}
    # Optional: normalize to ensure all days exist
    data = {d: data.get(d, []) for d in DAYS}
    save_availability(user, data)
    return redirect("/availability?saved=1")
@route("/account", method=["GET", "POST"])
def account_page():
    acc = load_account()

    if request.method == "POST":
        action = request.forms.get("action")

        if action == "profile":
            acc["name"] = request.forms.get("name", "").strip()
            acc["email"] = request.forms.get("email", "").strip()
            save_account(acc)
            return redirect("/account?ok=Saved")

        elif action == "password":
            pw = request.forms.get("new_password", "")
            if len(pw) < 4:
                return render("account",
                                user=acc,
                                ok=None,
                                err="Password must be at least 4 characters.",
                                user_name=acc.get("name","User"))
            acc["password"] = pw
            save_account(acc)
            return redirect("/account?ok=Password+updated")

    return render("account",
                    user=acc,
                    ok=request.query.get("ok"),
                    err=None,
                    user_name=acc.get("name","User"))
TEACHERS = [
    {
        "name": "Ms. Rivera",
        "subjects": ["Algebra", "Geometry"],
        "availability": [
            {"day":"Mon", "times": ["10:30","11:00","14:00"]},
            {"day":"Tue", "times": ["09:00","09:30","14:15"]},
            {"day":"Thu", "times": ["10:00","10:30"]},
        ]
    },
    {
        "name": "Mr. Lee",
        "subjects": ["Physics", "Calculus"],
        "availability": [
            {"day":"Tue", "times": ["14:15","14:45"]},
            {"day":"Wed", "times": ["09:00","09:30","10:00"]},
            {"day":"Fri", "times": ["11:00","11:30"]},
        ]
    },
    {
        "name": "Coach Diaz",
        "subjects": ["Counseling"],
        "availability": [
            {"day":"Wed", "times": ["09:00","09:30"]},
            {"day":"Thu", "times": ["15:00","15:30"]},
        ]
    }
]

def all_subjects():
    s=set()
    for t in TEACHERS:
        for x in t.get("subjects",[]):
            s.add(x)
    return sorted(s)

@route("/request", method=["GET","POST"])
def request_page():
    if request.method == "GET":
        AVAIL_PATH = os.path.join("data","availability","demo.json")
        user_ranges = load_availability(AVAIL_PATH, DAYS)
        return render(
            "meeting_reqs",
            days=DAYS,
            start_hour=START_HOUR,
            end_hour=END_HOUR,
            teachers=TEACHERS,
            subjects=all_subjects(),
            user_ranges=user_ranges,       # <-- raw ranges for “By My Availability”
            user_name="User"
        )

    # POST: collect request (same as before)
    payload = {
        "mode": request.forms.get("mode"),
        "subject": request.forms.get("subject",""),
        "urgency": request.forms.get("urgency","Normal"),
        "duration": request.forms.get("duration","20"),
        "teacher": request.forms.get("teacher",""),
        "day": request.forms.get("day",""),
        "start": request.forms.get("start",""),
        "end": request.forms.get("end",""),
        "reason": request.forms.get("reason",""),
    }
    print("REQUESTED MEETING:", json.dumps(payload, indent=2))
    os.makedirs("data", exist_ok=True)
    path="data/requests.json"
    try:
        arr=json.load(open(path,"r",encoding="utf-8"))
        if not isinstance(arr,list): arr=[]
    except Exception:
        arr=[]
    arr.append(payload)
    json.dump(arr, open(path,"w",encoding="utf-8"), ensure_ascii=False, indent=2)
    return redirect("/meetings")
@route("/meetings")
def meetings_page():
    # Example mock data — replace with real meetings later
    meetings = [
        {"day":"Mon","start":"10:30","end":"10:50","title":"Test review","with":"Ms. Rivera","status":"Confirmed"},
        {"day":"Tue","start":"14:15","end":"14:45","title":"Project help","with":"Mr. Lee","status":"Pending"},
        {"day":"Wed","start":"09:00","end":"09:30","title":"Check-in","with":"Coach Diaz","status":"Cancelled"},
    ]

    return render(
        "meetings",
        days=DAYS,
        start_hour=START_HOUR,
        end_hour=END_HOUR,
        meetings=meetings,
        user_name=load_account().get("name","User")
    )

@route('/settings', method='GET')
def settings_get():
    return render('settings', theme=request.get_cookie('theme') or 'dark', ok="Settings saved." if request.query.get('saved') else None)

@route('/settings', method='POST')
def settings_post():
    theme = request.forms.get('theme') or 'dark'
    # store cookie for 30 days
    response.set_cookie('theme', theme, path='/', max_age=30*24*60*60, httponly=False)
    return redirect('/settings?saved=1')

HELP_DIR = os.path.join("data", "help")
HELP_PATH = os.path.join(HELP_DIR, "tickets.json")
os.makedirs(HELP_DIR, exist_ok=True)

def _load_tickets():
    try:
        with open(HELP_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data if isinstance(data, list) else []
    except Exception:
        return []

def _save_tickets(arr):
    with open(HELP_PATH, "w", encoding="utf-8") as f:
        json.dump(arr, f, ensure_ascii=False, indent=2)

@route("/help", method=["GET", "POST"])
def help_page():
    # If you have load_account(), use it to prefill name/email; else fallback.
    try:
        acc = load_account()  # optional if you already have this
        user_name = acc.get("name", "User")
        user_email = acc.get("email", "")
    except:
        user_name, user_email = "User", ""
    if request.method == "GET":
        return template("help",
                        ok=request.query.get("ok"),
                        err=None,
                        pre_name=user_name,
                        pre_email=user_email,
                        user_name=user_name)

    # POST
    name = (request.forms.get("name") or "").strip()
    email = (request.forms.get("email") or "").strip()
    category = (request.forms.get("category") or "Other").strip()
    urgency = (request.forms.get("urgency") or "Normal").strip()
    subject = (request.forms.get("subject") or "").strip()
    description = (request.forms.get("description") or "").strip()

    if not subject or not description:
        return template("help",
                        ok=None,
                        err="Please include both a subject and a description.",
                        pre_name=name or user_name,
                        pre_email=email or user_email,
                        user_name=name or user_name)

    tickets = _load_tickets()
    tickets.append({
        "id": str(uuid.uuid4())[:8],
        "when": datetime.datetime.now().isoformat(timespec="seconds"),
        "name": name or user_name,
        "email": email or user_email,
        "category": category,
        "urgency": urgency,
        "subject": subject,
        "description": description,
        "status": "Open"
    })
    _save_tickets(tickets)
    return redirect("/help?ok=Ticket+submitted")
@route("/account-setup", method=["GET", "POST"])
def account_setup():
    existing = load_current_account() or {}
    user_name = existing.get("name") or "User"

    if request.method == "GET":
        return template("account_setup",
                        preset=existing,
                        user_name=user_name)

    # POST: read form
    role  = (request.forms.get("role")  or "Student").strip()
    name  = (request.forms.get("name")  or "").strip()
    email = (request.forms.get("email") or "").strip()

    if not name:
        # re-render with error
        return template("account_setup",
                        preset=dict(request.forms),
                        user_name=user_name,
                        err="Name is required.")

    # dynamic proficiency rows from the form
    subs = request.forms.getall("prof_subject[]")
    labs = request.forms.getall("prof_labels[]")
    rows = [{"subject": subs[i] if i < len(subs) else "",
             "labels":  labs[i] if i < len(labs) else ""} for i in range(max(len(subs), len(labs)))]

    proficiency = parse_proficiency(rows)

    account_obj = {
        "role": role,
        "name": name,
        "email": email,
        "proficiency": proficiency,
    }

    if role == "Student":
        account_obj["grade"]   = (request.forms.get("grade") or "").strip()
        account_obj["courses"] = parse_courses(request.forms.get("courses"))
    else:
        account_obj["title"] = (request.forms.get("title") or "").strip()

    save_current_account(account_obj)

    # (optional) if you maintain a minimal account store for avatar/name
    # try:
    #     from helpers.storage import load_account, save_account
    #     acc = load_account()
    #     acc["name"] = name
    #     acc["email"] = email
    #     save_account(acc)
    # except Exception:
    #     pass

    return redirect("/account")


run(host='localhost', port=8080)