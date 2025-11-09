DAYS = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

START_HOUR = 8
END_HOUR = 20

def _to_minutes(hhmm: str) -> int:
    h, m = map(int, hhmm.split(":"))
    return h*60 + m

def day_to_col(day: str) -> int:
    return DAYS.index(day)

def row_for(hhmm: str) -> int:
    offset = _to_minutes(hhmm) - START_HOUR*60
    half_hours = max(0, offset // 30)
    return 2 + half_hours  # row index used by CSS grid

def row_span(start: str, end: str) -> int:
    dur = max(30, _to_minutes(end) - _to_minutes(start))
    return max(1, dur // 30)