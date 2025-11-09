import os, json

ACCT_DIR  = os.path.join("data", "accounts")
ACCT_PATH = os.path.join(ACCT_DIR, "current.json")

os.makedirs(ACCT_DIR, exist_ok=True)

def parse_proficiency(rows):
    """
    rows: list of {"subject": str, "labels": str(comma-separated)}
    returns: dict[str, tuple[str,...]]
    """
    out = {}
    for r in rows or []:
        subj = (r.get("subject") or "").strip()
        labels_raw = (r.get("labels") or "").strip()
        if not subj or not labels_raw:
            continue
        labels = tuple(s.strip() for s in labels_raw.split(",") if s.strip())
        if labels:
            out[subj] = labels
    return out

def parse_courses(raw):
    """Comma-separated string → list[str]"""
    raw = (raw or "").strip()
    return [s.strip() for s in raw.split(",") if s.strip()]

def save_current_account(acct: dict):
    # Write atomically to avoid leaving a truncated file if the process is killed
    tmp = ACCT_PATH + ".tmp"
    os.makedirs(os.path.dirname(ACCT_PATH), exist_ok=True)
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(acct, f, ensure_ascii=False, indent=2)
    try:
        os.replace(tmp, ACCT_PATH)
    except Exception:
        # Best-effort cleanup on failure
        if os.path.exists(tmp):
            try:
                os.remove(tmp)
            except Exception:
                pass

def load_current_account() -> dict | None:
    if not os.path.exists(ACCT_PATH):
        return None
    try:
        return json.load(open(ACCT_PATH, "r", encoding="utf-8"))
    except Exception:
        return None

def load_account_instance(name: str):
    """Load a saved account instance JSON as a plain dict.

    Historically this returned a backend Student/Teacher object which
    could cause circular imports at runtime. For the purposes of the web
    UI we only need the stored data, so return the raw dict or None.
    """
    # Support two locations where instances may be saved for historical reasons:
    # - data/accounts/instances/<name>.json
    # - data/instances/<name>.json
    instance_path1 = os.path.join(ACCT_DIR, "instances", f"{name.lower().replace(' ', '_')}.json")
    instance_path2 = os.path.join("data", "instances", f"{name.lower().replace(' ', '_')}.json")
    instance_path = instance_path1 if os.path.exists(instance_path1) else instance_path2
    if not instance_path or not os.path.exists(instance_path):
        return None
    try:
        with open(instance_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None