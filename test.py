from bottle import Bottle, route, run, template, request, redirect, response, HTTPResponse #type: ignore
import json, os, uuid, datetime, sys
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
    success = False
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
    # Load current account for user info
    acct = load_current_account() or {}
    # Use signed-in user's name from cookie/account, else fall back to default
    kwargs.setdefault('user_name', acct.get('name') or request.get_cookie('user') or 'Nicolas')
    kwargs.setdefault('theme', request.get_cookie('theme') or 'dark')
    kwargs.setdefault('role', acct.get('role', 'Student'))
    return template(tpl, **kwargs)


app = Bottle()

@route('/')
def index():
    return "hello world"
@route('/login', method='GET')
def show_login():
    message = request.query.get('message')
    return render("login", message=message)
@route('/login', method=["POST"])
def login_post():
    # Simple authentication: check against saved account (data/accounts/current.json)
    email = (request.forms.get('email') or '').strip()
    pw = request.forms.get('password') or ''

    acct = load_current_account()
    if not acct:
        return render('login', error='No account exists. Please sign up.')

    # Match email and password (plain-text for hackathon simplicity)
    if email == acct.get('email') and pw == acct.get('password'):
        # successful login → set cookie and go to home
        response.set_cookie('user', acct.get('name', 'User'), path='/')
        return redirect('/home')

    # failed authentication
    return render('login', error='Invalid email or password.')
@route('/signup', method='GET')
def signup_get():
    return render('signup')
@route('/signup', method=["POST"])
def signup_post():
    name = request.forms.get("name", "").strip()
    email = request.forms.get("email", "").strip()
    role = request.forms.get("role", "student").strip()
    password = request.forms.get("password", "").strip()
    
    if not name or not email or not password:
        return render('signup', error="All fields are required")
    
    try:
        # Create initial account data
        account_data = {
            "name": name,
            "email": email,
            "role": role,
            "password": password,  # In production, this should be hashed
            "proficiency": {}  # Will be set in account setup
        }

        save_current_account(account_data)
        
        # Also create initial instance file
        instance_data = {
            "type": role,
            "name": name,
            "proficiency": {},
            "meetings": [],
            "requests": []
        }
        instance_dir = os.path.join("data", "instances")
        os.makedirs(instance_dir, exist_ok=True)
        instance_path = os.path.join(instance_dir, f"{name.lower().replace(' ', '_')}.json")
        tmp_path = instance_path + ".tmp"
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(instance_data, f, indent=2, ensure_ascii=False)
        os.replace(tmp_path, instance_path)
        
        # Account creation complete - send to login
        return redirect("/login?message=Account+created+successfully")

    except Exception as e:
        # bottle.redirect raises HTTPResponse which we should re-raise so the framework can handle it
        try:
            from bottle import HTTPResponse as _HTTPResponse
        except Exception:
            _HTTPResponse = None
        if _HTTPResponse and isinstance(e, _HTTPResponse):
            raise

        import traceback, sys
        tb = traceback.format_exc()
        print("Signup error:\n", tb, file=sys.stderr)
        return render('signup', error="Internal error while creating account. Check server logs.")
@route('/home')
def home():
    # Get real meetings from instance file
    acct = load_current_account() or {}
    name = acct.get("name")
    meetings = []
    if name:
        # Look in instances directory
        inst_path = os.path.join("data", "instances", f"{name.lower().replace(' ', '_')}.json")
        if os.path.exists(inst_path):
            try:
                with open(inst_path, "r", encoding="utf-8") as f:
                    inst = json.load(f)
                    meetings = inst.get("meetings", []) or []
            except Exception:
                meetings = []

    return render("home",
        days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
        meetings=meetings, day_to_col=day_to_col, row_for=row_for, row_span=row_span,
        message=request.query.get('message'))

@route('/availability', method='GET')
def availability_get():
    # Load availability for the current account
    acct = load_current_account()
    if not acct:
        return redirect("/login")
        
    user = acct.get("name", "demo")
    avail_ranges = load_availability(user, DAYS)
    return render('availability',
                    ok=request.query.get('saved') and "Availability saved.",
                    days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                    avail_ranges=avail_ranges,
                    user_name=user)

@route('/availability', method='POST')
def availability_post():
    # Require a logged-in account
    acct = load_current_account()
    if not acct:
        return redirect("/login")
        
    raw = request.forms.get('avail_json') or "{}"
    try:
        data = json.loads(raw)
        if not isinstance(data, dict):
            raise ValueError("Expected object")
    except Exception:
        return render('availability',
                    ok=None,
                    err="Invalid availability data received.",
                    days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                    avail_ranges={d: [] for d in DAYS},
                    user_name=acct.get("name", "User"))

    # Optional: normalize to ensure all days exist
    data = {d: data.get(d, []) for d in DAYS}
    
    try:
        save_availability(acct.get("name", "demo"), data)
        return redirect("/availability?saved=1")
    except Exception as e:
        # Allow Bottle's redirect response to pass through
        if isinstance(e, HTTPResponse):
            raise
        # Log full traceback for debugging
        import traceback, sys
        tb = traceback.format_exc()
        print("Availability save error:\n", tb, file=sys.stderr)
        return render('availability',
                    ok=None,
                    err=f"Failed to save: {str(e)}",
                    days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                    avail_ranges=data,
                    user_name=acct.get("name", "User"))
@route("/account", method=["GET", "POST"])
def account_page():
    # Use the account stored by helpers/account_utils (data/accounts/current.json)
    acc = load_current_account()
    if not acc:
        # No account yet — send user to signup
        return redirect('/signup')

    if request.method == "POST":
        action = request.forms.get("action")

        if action == "profile":
            acc["name"] = request.forms.get("name", "").strip()
            acc["email"] = request.forms.get("email", "").strip()
            try:
                save_current_account(acc)
            except Exception as e:
                return render("account", user=acc, ok=None, err=f"Failed to save: {e}", user_name=acc.get("name","User"))
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
            try:
                save_current_account(acc)
            except Exception as e:
                return render("account", user=acc, ok=None, err=f"Failed to save: {e}", user_name=acc.get("name","User"))
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
        # Load account to check role
        acct = load_current_account() or {}
        user = current_user()
        user_name = acct.get("name") or user
        role = acct.get("role", "Student")
        
        if role == "Teacher":
            # Load teacher's meetings with student_request=True
            inst_path = os.path.join("data", "instances", f"{user_name.lower().replace(' ', '_')}.json")
            meetings = []
            if os.path.exists(inst_path):
                try:
                    with open(inst_path, "r", encoding="utf-8") as f:
                        inst = json.load(f)
                        meetings = inst.get("meetings", []) or []
                except Exception:
                    meetings = []
            
            return render(
                "meeting_requests",
                meetings=meetings,
                user_name=user_name,
                role=role
            )
        else:
            # Student view - show meeting request form
            user_ranges = load_availability(user, DAYS)
            return render(
                "meeting_reqs",
                days=DAYS,
                start_hour=START_HOUR,
                end_hour=END_HOUR,
                teachers=TEACHERS,
                subjects=all_subjects(),
                user_ranges=user_ranges,       # <-- raw ranges for "By My Availability"
                user_name=user_name,
                role=role
            )

    # POST: create a new meeting request
    acct = load_current_account()
    if not acct:
        return redirect("/login")
    
    # Build request object
    request_id = str(uuid.uuid4())[:8]  # Generate unique ID
    payload = {
        "id": request_id,
        "status": "Pending",
        "when": datetime.datetime.now().isoformat(timespec="seconds"),
        "student": acct.get("name", "Unknown Student"),
        "teacher": request.forms.get("teacher",""),
        "subject": request.forms.get("subject",""),
        "urgency": request.forms.get("urgency","Normal"),
        "duration": request.forms.get("duration","20"),
        "day": request.forms.get("day",""),
        "start": request.forms.get("start",""),
        "end": request.forms.get("end",""),
        "reason": request.forms.get("reason",""),
        "mode": request.forms.get("mode"),  # How it was requested (by teacher/availability)
    }
    
    # Load student's instance file
    student_file = os.path.join("data", "instances", f"{acct.get('name','').lower().replace(' ', '_')}.json")
    if not os.path.exists(student_file):
        return render("meeting_reqs",
                    err="Account not properly set up. Please complete account setup first.",
                    days=DAYS,
                    start_hour=START_HOUR,
                    end_hour=END_HOUR,
                    teachers=TEACHERS,
                    subjects=all_subjects(),
                    user_ranges={},
                    user_name=acct.get("name", "User"))
    
    try:
        # Load existing instance data
        try:
            with open(student_file, "r", encoding="utf-8") as f:
                instance_data = json.load(f)
        except json.JSONDecodeError:
            # If file exists but is invalid JSON, create new data
            instance_data = {"meetings": [], "requests": []}
            
        # Add request to both requests and meetings arrays
        instance_data.setdefault("requests", []).append(payload)
        # Create meeting title - include subject (or default to "Meeting") and duration
        meeting_title = "Meeting" if not payload["subject"] else payload["subject"]
        instance_data.setdefault("meetings", []).append({
            "id": request_id,
            "day": payload["day"],
            "start": payload["start"],
            "end": payload["end"],
            "title": f"{meeting_title} ({payload['duration']}min)",
            "with": payload["teacher"],
            "status": "Pending"
        })
        
        try:
            # Save atomically
            tmp_path = student_file + ".tmp"
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(instance_data, f, ensure_ascii=False, indent=2)
            os.replace(tmp_path, student_file)
            
            # Also save to teacher's instance file if it exists
            teacher_file = os.path.join("data", "instances", f"{payload['teacher'].lower().replace(' ', '_')}.json")
            if os.path.exists(teacher_file):
                try:
                    with open(teacher_file, "r", encoding="utf-8") as f:
                        teacher_data = json.load(f)
                    # Same title logic for teacher's view
                    meeting_title = "Meeting" if not payload["subject"] else payload["subject"]
                    teacher_data.setdefault("meetings", []).append({
                        "id": request_id,
                        "day": payload["day"],
                        "start": payload["start"],
                        "end": payload["end"],
                        "title": f"{meeting_title} ({payload['duration']}min)",
                        "with": payload["student"],
                        "status": "Pending",
                        "student_request": True  # Flag to show this came from student
                    })
                    tmp_path = teacher_file + ".tmp"
                    with open(tmp_path, "w", encoding="utf-8") as f:
                        json.dump(teacher_data, f, ensure_ascii=False, indent=2)
                    os.replace(tmp_path, teacher_file)
                except Exception:
                    # Non-fatal if we can't update teacher's file
                    pass

            return redirect("/meetings")
        except Exception as e:
            print(f"Error saving meeting request: {e}", file=sys.stderr)
            return render("meeting_reqs",
                        err=f"Failed to save meeting request: {str(e)}",
                        days=DAYS,
                        start_hour=START_HOUR,
                        end_hour=END_HOUR,
                        teachers=TEACHERS,
                        subjects=all_subjects(),
                        user_ranges=load_availability(acct.get("name", "demo"), DAYS),
                        user_name=acct.get("name", "User"))
        
    except Exception as e:
        print("Error saving meeting request:", str(e), file=sys.stderr)
        return render("meeting_reqs",
                    err=f"Failed to save meeting request: {str(e)}",
                    days=DAYS,
                    start_hour=START_HOUR,
                    end_hour=END_HOUR,
                    teachers=TEACHERS,
                    subjects=all_subjects(),
                    user_ranges=load_availability(acct.get("name", "demo"), DAYS),
                    user_name=acct.get("name", "User"))
@route("/meetings")
def meetings_page():
    # Load meetings from instance file
    acct = load_current_account() or {}
    name = acct.get("name")
    meetings = []
    if name:
        # Look in instances directory
        inst_path = os.path.join("data", "instances", f"{name.lower().replace(' ', '_')}.json")
        if os.path.exists(inst_path):
            try:
                with open(inst_path, "r", encoding="utf-8") as f:
                    inst = json.load(f)
                    meetings = inst.get("meetings", []) or []
            except Exception:
                meetings = []

    return render(
        "meetings",
        days=DAYS,
        start_hour=START_HOUR,
        end_hour=END_HOUR,
        meetings=meetings,
        user_name=acct.get("name","User")
    )

@route('/meetings/respond', method='POST')
def meeting_respond():
    """Handle accepting/rejecting meeting requests"""
    acct = load_current_account()
    if not acct:
        return redirect("/login")
    
    meeting_id = request.forms.get("meeting_id")
    response = request.forms.get("response")  # 'accept' or 'reject'
    
    if not meeting_id or response not in ('accept', 'reject'):
        return redirect("/meetings")
    
    # Update teacher's instance
    teacher_file = os.path.join("data", "instances", f"{acct.get('name','').lower().replace(' ', '_')}.json")
    if os.path.exists(teacher_file):
        try:
            with open(teacher_file, "r", encoding="utf-8") as f:
                teacher_data = json.load(f)
            
            # Find and update the meeting
            found_meeting = None
            for m in teacher_data.get("meetings", []):
                if m.get("id") == meeting_id:
                    m["status"] = "Confirmed" if response == "accept" else "Cancelled"
                    found_meeting = m
                    break
            
            if found_meeting:
                # Save teacher data
                tmp = teacher_file + ".tmp"
                with open(tmp, "w", encoding="utf-8") as f:
                    json.dump(teacher_data, f, ensure_ascii=False, indent=2)
                os.replace(tmp, teacher_file)
                
                # Update student's instance too
                student_name = found_meeting.get("with", "").lower().replace(" ", "_")
                student_file = os.path.join("data", "instances", f"{student_name}.json")
                if os.path.exists(student_file):
                    try:
                        with open(student_file, "r", encoding="utf-8") as f:
                            student_data = json.load(f)
                        
                        # Update both meetings and requests arrays
                        for m in student_data.get("meetings", []):
                            if m.get("id") == meeting_id:
                                m["status"] = "Confirmed" if response == "accept" else "Cancelled"
                        
                        for r in student_data.get("requests", []):
                            if r.get("id") == meeting_id:
                                r["status"] = "Confirmed" if response == "accept" else "Cancelled"
                        
                        # Save student data
                        tmp = student_file + ".tmp"
                        with open(tmp, "w", encoding="utf-8") as f:
                            json.dump(student_data, f, ensure_ascii=False, indent=2)
                        os.replace(tmp, student_file)
                    except Exception:
                        pass  # Non-fatal if student update fails
        
        except Exception as e:
            print(f"Error updating meeting {meeting_id}: {str(e)}", file=sys.stderr)
    
    return redirect("/meetings")

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
    # Prefill name/email from the saved current account when available
    acct = load_current_account() or {}
    user_name = acct.get("name", "User")
    user_email = acct.get("email", "")
    if request.method == "GET":
        return render("help",
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
        return render("help",
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
    # Load current account - this is for editing account settings only
    existing = load_current_account() or {}
    if not existing:
        return redirect("/signup")
    user_name = existing.get("name") or "User"

    if request.method == "GET":
        return render("account_setup",
                        preset=existing,
                        user_name=user_name)

    # POST: read form
    try:
        with open(os.path.join(os.path.dirname(__file__), 'acct_debug.log'), 'a', encoding='utf-8') as _dbg:
            _dbg.write('account_setup: POST entered\n')
    except Exception:
        pass
    role  = (request.forms.get("role")  or "Student").strip()
    name  = (request.forms.get("name")  or "").strip()
    email = (request.forms.get("email") or "").strip()
    subjects_raw = (request.forms.get("subjects") or "").strip()
    subjects = [s.strip() for s in subjects_raw.split(",") if s.strip()]

    if not name:
        # re-render with error
        return render("account_setup",
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
        "subjects": subjects,
    }

    if role == "Student":
        account_obj["grade"]   = (request.forms.get("grade") or "").strip()
        account_obj["courses"] = parse_courses(request.forms.get("courses"))
    else:
        account_obj["title"] = (request.forms.get("title") or "").strip()

    # Persist account data and a serialized instance without importing Backend classes
    try:
        # Save raw account object
        save_current_account(account_obj)

        # Build instance data directly (avoid importing Backend to prevent circular/import-time side-effects)
        instance_data = {
            "type": role,
            "name": name,
            "proficiency": proficiency,
            "meetings": [],
            "requests": []
        }
        if role == "Student":
            instance_data.update({
                "courses": account_obj.get("courses", []),
                "grade": account_obj.get("grade", "")
            })
        else:
            instance_data.update({
                "title": account_obj.get("title", "")
            })
        if subjects:
            instance_data["subjects"] = subjects

        # Write atomically to avoid truncated JSON on failure
        instance_dir = os.path.join("data", "instances")
        os.makedirs(instance_dir, exist_ok=True)
        instance_path = os.path.join(instance_dir, f"{name.lower().replace(' ', '_')}.json")
        tmp_path = instance_path + ".tmp"
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(instance_data, f, indent=2, ensure_ascii=False)
        os.replace(tmp_path, instance_path)

        acct_instance_dir = os.path.join("data", "accounts", "instances")
        os.makedirs(acct_instance_dir, exist_ok=True)
        acct_instance_path = os.path.join(acct_instance_dir, f"{name.lower().replace(' ', '_')}.json")
        tmp2 = acct_instance_path + ".tmp"
        try:
            with open(tmp2, "w", encoding="utf-8") as f:
                json.dump(instance_data, f, indent=2, ensure_ascii=False)
            os.replace(tmp2, acct_instance_path)
        except Exception:
            # non-fatal
            if os.path.exists(tmp2):
                try:
                    os.remove(tmp2)
                except Exception:
                    pass

        success = True
        
    except Exception as e:
        # If Bottle's control-flow HTTPResponse (raised by redirect) bubbles up, re-raise it
        try:
            from bottle import HTTPResponse as _HTTPResponse
        except Exception:
            _HTTPResponse = None
        if _HTTPResponse and isinstance(e, _HTTPResponse):
            raise

        # Log full traceback to server log for debugging
        import traceback, sys
        tb = traceback.format_exc()
        print("Account setup exception:\n", tb, file=sys.stderr)
        return render("account_setup",
                    preset=account_obj,
                    user_name=user_name,
                    err=f"Error creating account: {str(e)}")

    # after try/except: if success, stay on account setup page with success message
    if success:
        return render("account_setup",
                    preset=account_obj,
                    user_name=user_name,
                    ok="Changes saved successfully")


run(host='localhost', port=8080)