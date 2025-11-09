from bottle import Bottle, route, run, template, request, redirect, response, HTTPResponse #type: ignore
import json, os, uuid, datetime, sys
from helpers.storage import load_availability, save_availability
from helpers.account_utils import (
    parse_proficiency, parse_courses,
    save_current_account, load_current_account,
    save_user_account, load_user_account
)

DAYS = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
START_HOUR = 8
END_HOUR = 20  # 8 pm

from home_utils import (
    DAYS, START_HOUR, END_HOUR,
    day_to_col, row_for, row_span
)

def current_user() -> str:
    # For hackathon: use cookie if set, else "demo"
    return request.get_cookie("user") or "demo"
    
ACCOUNT_DIR = os.path.join("data", "accounts")
os.makedirs(ACCOUNT_DIR, exist_ok=True)

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
    # Use role from cookie if set, else from account, else default to Student
    role = request.get_cookie('role') or acct.get('role', 'Student')
    
    # Use signed-in user's name from cookie/account, else fall back to default
    kwargs.setdefault('user_name', acct.get('name') or request.get_cookie('user') or 'Nicolas')
    kwargs.setdefault('theme', request.get_cookie('theme') or 'dark')
    kwargs.setdefault('role', role)
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
    # Get login credentials
    email = (request.forms.get('email') or '').strip()
    pw = request.forms.get('password') or ''

    # Load user account data
    acct = load_user_account(email)
    if not acct:
        return render('login', error='No account exists with this email. Please sign up.')

    # Match password (plain-text for hackathon simplicity)
    if pw != acct.get('password'):
        return render('login', error='Invalid password.')

    # successful login → set cookies and update current.json
    name = acct.get('name')
    role = acct.get('role', 'Student')
    print(f"DEBUG: Successful login - name: {name}, role: {role}")

    # Update session data
    save_current_account(acct)
    response.set_cookie('user', name, path='/')
    response.set_cookie('role', role, path='/')
    
    # Verify instance file exists
    inst_path = os.path.join("data", "instances", f"{name.lower().replace(' ', '_')}.json")
    if not os.path.exists(inst_path):
        print(f"DEBUG: Instance file missing at {inst_path}")
        # If no instance file, create one
        instance_data = {
            "type": role,
            "name": name,
            "proficiency": acct.get("proficiency", {}),
            "meetings": [],
            "requests": [],
            "title": acct.get("title", "") if role == "Teacher" else "",
            "subjects": acct.get("subjects", [])
        }
        try:
            tmp_path = inst_path + ".tmp"
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(instance_data, f, indent=2, ensure_ascii=False)
            os.replace(tmp_path, inst_path)
            print(f"DEBUG: Created missing instance file")
        except Exception as e:
            print(f"DEBUG: Error creating instance file: {e}")
    
    return redirect('/home')

@route('/signup', method='GET')
def signup_get():
    return render('signup')

@route("/signup", method=["POST"])
def signup_post():
    name = request.forms.get("name", "").strip()
    email = request.forms.get("email", "").strip()
    role = request.forms.get("role", "Student").strip()  # Default to Student
    password = request.forms.get("password", "").strip()
    
    if not name or not email or not password:
        return render('signup', error="All fields are required")

    # Check if account already exists
    if load_user_account(email):
        return render('signup', error="An account with this email already exists")
    # Build account data (outside try so obvious errors show)
    account_data = {
        "name": name,
        "email": email,
        "role": role.title(),  # Ensure proper case (Student/Teacher)
        "password": password,
        "proficiency": {}
    }

    try:
        # Persist session and user record
        save_current_account(account_data)
        save_user_account(account_data)

        # Ensure instance file exists
        instance_data = {
            "type": role.title(),
            "name": name,
            "proficiency": {},
            "meetings": [],
            "requests": []
        }
        instance_dir = os.path.join("data", "instances")
        os.makedirs(instance_dir, exist_ok=True)
        instance_path = os.path.join(instance_dir, f"{name.lower().replace(' ', '_')}.json")
        if not os.path.exists(instance_path):
            tmp_path = instance_path + ".tmp"
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(instance_data, f, indent=2, ensure_ascii=False)
            os.replace(tmp_path, instance_path)
    except HTTPResponse:
        # Allow Bottle control-flow redirects to bubble up unchanged
        raise
    except Exception as e:
        import traceback, sys
        tb = traceback.format_exc()
        print("Signup error (internal exception):\n", tb, file=sys.stderr)
        return render('signup', error="Internal error while creating account. Check server logs.")

    # Perform redirect AFTER successful creation (outside try so HTTPResponse isn't swallowed)
    return redirect("/login?message=Account+created+successfully")

@route('/logout')
def logout():
    """Clear session cookies and return to login page."""
    response.delete_cookie('user', path='/')
    response.delete_cookie('role', path='/')
    return redirect('/login?message=Logged+out')

@route('/home')
def home():
    """Home dashboard with meetings pulled from the instance file for the current user."""
    acct = load_current_account() or {}
    name = acct.get("name")
    meetings = []
    if name:
        inst_path = os.path.join("data", "instances", f"{name.lower().replace(' ', '_')}.json")
        if os.path.exists(inst_path):
            try:
                with open(inst_path, "r", encoding="utf-8") as f:
                    inst = json.load(f)
                    meetings = inst.get("meetings", []) or []
            except Exception:
                meetings = []

    return render(
        "home",
        days=DAYS,
        start_hour=START_HOUR,
        end_hour=END_HOUR,
        meetings=meetings,
        day_to_col=day_to_col,
        row_for=row_for,
        row_span=row_span,
        message=request.query.get('message')
    )

# ================= RESTORED FEATURE ROUTES (availability, account, requests, meetings, settings, help, account-setup) =================

@route('/availability', method='GET')
def availability_get():
    acct = load_current_account()
    if not acct:
        return redirect('/login')
    user = acct.get('name', 'demo')
    avail_ranges = load_availability(user, DAYS)
    return render('availability',
                  ok=request.query.get('saved') and "Availability saved.",
                  days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                  avail_ranges=avail_ranges,
                  user_name=user)

@route('/availability', method='POST')
def availability_post():
    acct = load_current_account()
    if not acct:
        return redirect('/login')
    raw = request.forms.get('avail_json') or "{}"
    try:
        data = json.loads(raw)
        if not isinstance(data, dict):
            raise ValueError('Expected object')
    except Exception:
        return render('availability', ok=None, err='Invalid availability data received.',
                      days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                      avail_ranges={d: [] for d in DAYS}, user_name=acct.get('name','User'))
    data = {d: data.get(d, []) for d in DAYS}
    try:
        save_availability(acct.get('name','demo'), data)
        return redirect('/availability?saved=1')
    except Exception as e:
        if isinstance(e, HTTPResponse):
            raise
        return render('availability', ok=None, err=f'Failed to save: {e}',
                      days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                      avail_ranges=data, user_name=acct.get('name','User'))

@route('/account', method=['GET','POST'])
def account_page():
    acc = load_current_account()
    if not acc:
        return redirect('/signup')
    if request.method == 'POST':
        action = request.forms.get('action')
        if action == 'profile':
            acc['name'] = request.forms.get('name','').strip()
            acc['email'] = request.forms.get('email','').strip()
            try:
                save_current_account(acc)
                save_user_account(acc)
            except Exception as e:
                return render('account', user=acc, ok=None, err=f'Failed to save: {e}', user_name=acc.get('name','User'))
            return redirect('/account?ok=Saved')
        elif action == 'password':
            pw = request.forms.get('new_password','')
            if len(pw) < 4:
                return render('account', user=acc, ok=None, err='Password must be at least 4 characters.', user_name=acc.get('name','User'))
            acc['password'] = pw
            try:
                save_current_account(acc)
                save_user_account(acc)
            except Exception as e:
                return render('account', user=acc, ok=None, err=f'Failed to save: {e}', user_name=acc.get('name','User'))
            return redirect('/account?ok=Password+updated')
    return render('account', user=acc, ok=request.query.get('ok'), err=None, user_name=acc.get('name','User'))

# ---------- Meeting request / teacher meetings ----------

def _all_subjects_from_teachers(teachers):
    s = set()
    for t in teachers:
        for x in t.get('subjects', []):
            s.add(x)
    return sorted(s)

@route('/request', method=['GET'])
def request_page():
    acct = load_current_account()
    if not acct:
        return redirect('/login')
    role = acct.get('role','Student')
    if role == 'Teacher':
        return redirect('/teacher-meetings')
    return redirect('/student-request')

@route('/teacher-meetings', method=['GET'])
def teacher_meetings():
    acct = load_current_account()
    if not acct or acct.get('role') != 'Teacher':
        return redirect('/request')
    user_name = acct.get('name')
    meetings = []
    try:
        inst_path = os.path.join('data','instances', f"{user_name.lower().replace(' ','_')}.json")
        if os.path.exists(inst_path):
            with open(inst_path,'r',encoding='utf-8') as f:
                inst = json.load(f)
                meetings = inst.get('meetings',[])
    except Exception:
        meetings = []
    return render('meeting_requests_fixed', meetings=meetings, user_name=user_name, role='Teacher')

@route('/student-request', method=['GET','POST'])
def student_request():
    acct = load_current_account()
    if not acct or acct.get('role') != 'Student':
        if not acct:
            return redirect('/login')
        return redirect('/request')
    user_name = acct.get('name')
    user_ranges = load_availability(user_name, DAYS)
    teachers = []
    subjects_set = set()
    inst_dir = os.path.join('data','instances')
    if os.path.exists(inst_dir):
        for fn in os.listdir(inst_dir):
            if not fn.endswith('.json'): continue
            path = os.path.join(inst_dir, fn)
            try:
                with open(path,'r',encoding='utf-8') as f:
                    inst = json.load(f)
            except Exception:
                continue
            if inst.get('type') != 'Teacher':
                continue
            tname = inst.get('name') or fn[:-5]
            subs = inst.get('subjects', []) or list((inst.get('proficiency') or {}).keys())
            for s in subs:
                subjects_set.add(s)
            # availability
            avail = load_availability(tname, DAYS)
            availability = []
            for d in DAYS:
                ranges = avail.get(d, []) or []
                times = []
                for r in ranges:
                    start = r.get('start'); end = r.get('end')
                    if not start or not end: continue
                    try:
                        sh, sm = map(int, start.split(':'))
                        eh, em = map(int, end.split(':'))
                        tmin = sh*60+sm; emin = eh*60+em
                        while tmin + 15 <= emin:
                            times.append(f"{tmin//60:02d}:{tmin%60:02d}")
                            tmin += 30
                    except Exception:
                        continue
                if times:
                    availability.append({'day': d, 'times': times})
            teachers.append({'name': tname, 'subjects': subs, 'availability': availability})
    subjects = sorted(subjects_set) if subjects_set else _all_subjects_from_teachers(teachers)
    if request.method == 'GET':
        return render('meeting_reqs', days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                      teachers=teachers, subjects=subjects, user_ranges=user_ranges,
                      user_name=user_name, role='Student')
    # POST create meeting
    request_id = str(uuid.uuid4())[:8]
    payload = {
        'id': request_id,
        'status': 'Pending',
        'when': datetime.datetime.now().isoformat(timespec='seconds'),
        'student': user_name,
        'teacher': request.forms.get('teacher',''),
        'subject': request.forms.get('subject',''),
        'urgency': request.forms.get('urgency','Normal'),
        'duration': request.forms.get('duration','20'),
        'day': request.forms.get('day',''),
        'start': request.forms.get('start',''),
        'end': request.forms.get('end',''),
        'reason': request.forms.get('reason',''),
        'mode': request.forms.get('mode')
    }
    student_file = os.path.join('data','instances', f"{user_name.lower().replace(' ','_')}.json")
    if not os.path.exists(student_file):
        return render('meeting_reqs', err='Account not properly set up. Please complete account setup first.',
                      days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                      teachers=teachers, subjects=subjects, user_ranges=user_ranges,
                      user_name=user_name, role='Student')
    try:
        with open(student_file,'r',encoding='utf-8') as f:
            instance_data = json.load(f)
        instance_data.setdefault('requests', []).append(payload)
        meeting_title = 'Meeting' if not payload['subject'] else payload['subject']
        instance_data.setdefault('meetings', []).append({
            'id': request_id,
            'day': payload['day'],
            'start': payload['start'],
            'end': payload['end'],
            'title': f"{meeting_title} ({payload['duration']}min)",
            'with': payload['teacher'],
            'status': 'Pending'
        })
        tmp_path = student_file + '.tmp'
        with open(tmp_path,'w',encoding='utf-8') as f:
            json.dump(instance_data, f, ensure_ascii=False, indent=2)
        os.replace(tmp_path, student_file)
        teacher_file = os.path.join('data','instances', f"{payload['teacher'].lower().replace(' ','_')}.json")
        if os.path.exists(teacher_file):
            with open(teacher_file,'r',encoding='utf-8') as f:
                teacher_data = json.load(f)
            teacher_data.setdefault('meetings', []).append({
                'id': request_id,
                'day': payload['day'],
                'start': payload['start'],
                'end': payload['end'],
                'title': f"{meeting_title} ({payload['duration']}min)",
                'with': payload['student'],
                'status': 'Pending',
                'student_request': True
            })
            tmp_t = teacher_file + '.tmp'
            with open(tmp_t,'w',encoding='utf-8') as f:
                json.dump(teacher_data, f, ensure_ascii=False, indent=2)
            os.replace(tmp_t, teacher_file)
        return redirect('/meetings')
    except Exception as e:
        return render('meeting_reqs', err=f'Failed to save meeting request: {e}',
                      days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                      teachers=teachers, subjects=subjects, user_ranges=user_ranges,
                      user_name=user_name, role='Student')

@route('/meetings')
def meetings_page():
    acct = load_current_account() or {}
    name = acct.get('name')
    meetings = []
    if name:
        inst_path = os.path.join('data','instances', f"{name.lower().replace(' ','_')}.json")
        if os.path.exists(inst_path):
            try:
                with open(inst_path,'r',encoding='utf-8') as f:
                    inst = json.load(f)
                    meetings = inst.get('meetings', []) or []
            except Exception:
                meetings = []
    return render('meetings', days=DAYS, start_hour=START_HOUR, end_hour=END_HOUR,
                  meetings=meetings, user_name=acct.get('name','User'))

@route('/meetings/respond', method='POST')
def meeting_respond():
    acct = load_current_account()
    if not acct:
        return redirect('/login')
    meeting_id = request.forms.get('meeting_id')
    resp = request.forms.get('response')
    if not meeting_id or resp not in ('accept','reject'):
        return redirect('/meetings')
    teacher_file = os.path.join('data','instances', f"{acct.get('name','').lower().replace(' ','_')}.json")
    if os.path.exists(teacher_file):
        try:
            with open(teacher_file,'r',encoding='utf-8') as f:
                teacher_data = json.load(f)
            found = None
            for m in teacher_data.get('meetings', []):
                if m.get('id') == meeting_id:
                    m['status'] = 'Confirmed' if resp == 'accept' else 'Cancelled'
                    found = m
                    break
            if found:
                tmp = teacher_file + '.tmp'
                with open(tmp,'w',encoding='utf-8') as f:
                    json.dump(teacher_data, f, ensure_ascii=False, indent=2)
                os.replace(tmp, teacher_file)
                student_name = found.get('with','').lower().replace(' ','_')
                student_file = os.path.join('data','instances', f"{student_name}.json")
                if os.path.exists(student_file):
                    try:
                        with open(student_file,'r',encoding='utf-8') as f:
                            student_data = json.load(f)
                        for m in student_data.get('meetings', []):
                            if m.get('id') == meeting_id:
                                m['status'] = 'Confirmed' if resp == 'accept' else 'Cancelled'
                        for r in student_data.get('requests', []):
                            if r.get('id') == meeting_id:
                                r['status'] = 'Confirmed' if resp == 'accept' else 'Cancelled'
                        tmp2 = student_file + '.tmp'
                        with open(tmp2,'w',encoding='utf-8') as f:
                            json.dump(student_data, f, ensure_ascii=False, indent=2)
                        os.replace(tmp2, student_file)
                    except Exception:
                        pass
        except Exception:
            pass
    return redirect('/meetings')

@route('/settings', method='GET')
def settings_get():
    return render('settings', theme=request.get_cookie('theme') or 'dark', ok='Settings saved.' if request.query.get('saved') else None)

@route('/settings', method='POST')
def settings_post():
    theme = request.forms.get('theme') or 'dark'
    response.set_cookie('theme', theme, path='/', max_age=30*24*60*60, httponly=False)
    return redirect('/settings?saved=1')

# Help / support ticket system
HELP_DIR = os.path.join('data','help')
HELP_PATH = os.path.join(HELP_DIR, 'tickets.json')
os.makedirs(HELP_DIR, exist_ok=True)

def _load_tickets():
    try:
        with open(HELP_PATH,'r',encoding='utf-8') as f:
            data = json.load(f)
            return data if isinstance(data, list) else []
    except Exception:
        return []

def _save_tickets(arr):
    with open(HELP_PATH,'w',encoding='utf-8') as f:
        json.dump(arr, f, ensure_ascii=False, indent=2)

@route('/help', method=['GET','POST'])
def help_page():
    acct = load_current_account() or {}
    user_name = acct.get('name','User')
    user_email = acct.get('email','')
    if request.method == 'GET':
        return render('help', ok=request.query.get('ok'), err=None, pre_name=user_name,
                      pre_email=user_email, user_name=user_name)
    name = (request.forms.get('name') or '').strip()
    email = (request.forms.get('email') or '').strip()
    category = (request.forms.get('category') or 'Other').strip()
    urgency = (request.forms.get('urgency') or 'Normal').strip()
    subject = (request.forms.get('subject') or '').strip()
    description = (request.forms.get('description') or '').strip()
    if not subject or not description:
        return render('help', ok=None, err='Please include both a subject and a description.',
                      pre_name=name or user_name, pre_email=email or user_email, user_name=name or user_name)
    tickets = _load_tickets()
    tickets.append({
        'id': str(uuid.uuid4())[:8],
        'when': datetime.datetime.now().isoformat(timespec='seconds'),
        'name': name or user_name,
        'email': email or user_email,
        'category': category,
        'urgency': urgency,
        'subject': subject,
        'description': description,
        'status': 'Open'
    })
    _save_tickets(tickets)
    return redirect('/help?ok=Ticket+submitted')

@route('/account-setup', method=['GET','POST'])
def account_setup():
    existing = load_current_account() or {}
    if not existing:
        return redirect('/signup')
    user_name = existing.get('name') or 'User'
    response.set_cookie('user', user_name, path='/')
    response.set_cookie('role', existing.get('role','Student'), path='/')
    if request.method == 'GET':
        return render('account_setup', preset=existing, user_name=user_name)
    role  = (request.forms.get('role')  or 'Student').strip()
    name  = (request.forms.get('name')  or '').strip()
    email = (request.forms.get('email') or '').strip()
    if not name:
        return render('account_setup', preset=dict(request.forms), user_name=user_name, err='Name is required.')
    subs = request.forms.getall('prof_subject[]')
    labs = request.forms.getall('prof_labels[]')
    rows = [{ 'subject': subs[i] if i < len(subs) else '', 'labels': labs[i] if i < len(labs) else '' } for i in range(max(len(subs), len(labs)))]
    proficiency = parse_proficiency(rows)
    current = load_current_account() or {}
    account_obj = {
        'role': role.title(),
        'name': name,
        'email': email,
        'proficiency': proficiency,
        'password': current.get('password','')
    }
    if role.title() == 'Student':
        account_obj['grade'] = (request.forms.get('grade') or '').strip()
        account_obj['courses'] = parse_courses(request.forms.get('courses'))
    else:
        account_obj['title'] = (request.forms.get('title') or '').strip()
        account_obj['subjects'] = sorted(proficiency.keys())
    try:
        save_current_account(account_obj)
        save_user_account(account_obj)
        instance_data = {
            'type': role.title(),
            'name': name,
            'proficiency': proficiency,
            'meetings': [],
            'requests': [],
            'title': account_obj.get('title','') if role.title() == 'Teacher' else '',
            'subjects': account_obj.get('subjects', [])
        }
        if role.title() == 'Student':
            instance_data.update({'courses': account_obj.get('courses', []), 'grade': account_obj.get('grade','')})
        inst_dir = os.path.join('data','instances')
        os.makedirs(inst_dir, exist_ok=True)
        inst_path = os.path.join(inst_dir, f"{name.lower().replace(' ','_')}.json")
        tmp_i = inst_path + '.tmp'
        with open(tmp_i,'w',encoding='utf-8') as f:
            json.dump(instance_data, f, indent=2, ensure_ascii=False)
        os.replace(tmp_i, inst_path)
    except HTTPResponse:
        raise
    except Exception as e:
        import traceback
        print('Account setup exception:\n', traceback.format_exc(), file=sys.stderr)
        return render('account_setup', preset=account_obj, user_name=user_name, err=f'Error creating account: {e}')
    return render('account_setup', preset=account_obj, user_name=user_name, ok='Changes saved successfully')

run(host='localhost', port=8080)