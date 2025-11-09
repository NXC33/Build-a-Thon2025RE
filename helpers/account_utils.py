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
    with open(ACCT_PATH, "w", encoding="utf-8") as f:
        json.dump(acct, f, ensure_ascii=False, indent=2)

def load_current_account() -> dict | None:
    if not os.path.exists(ACCT_PATH):
        return None
    try:
        return json.load(open(ACCT_PATH, "r", encoding="utf-8"))
    except Exception:
        return None