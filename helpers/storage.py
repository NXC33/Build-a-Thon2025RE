import os, json, re

BASE_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "availability")
os.makedirs(BASE_DIR, exist_ok=True)

_filename_safe = re.compile(r"[^A-Za-z0-9_.-]+")

def _safe_user(u: str) -> str:
    u = u.strip() or "demo"
    return _filename_safe.sub("_", u)

def load_availability(user: str, days: list[str]) -> dict:
    """Return dict like {'Mon':[{'start':'09:00','end':'11:30'}], ...} with all days present."""
    path = os.path.join(BASE_DIR, f"{_safe_user(user)}.json")
    if not os.path.exists(path):
        return {d: [] for d in days}
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        return {d: [] for d in days}
    # normalize keys
    out = {d: [] for d in days}
    for d, arr in (data.items() if isinstance(data, dict) else []):
        if d in out and isinstance(arr, list):
            out[d] = [
                {"start": str(it.get("start","00:00")), "end": str(it.get("end","00:00"))}
                for it in arr if isinstance(it, dict)
            ]
    return out

def save_availability(user: str, data: dict) -> None:
    """Persist availability JSON exactly as received (already normalized by the UI)."""
    path = os.path.join(BASE_DIR, f"{_safe_user(user)}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
