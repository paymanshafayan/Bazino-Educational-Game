"""تست ریاضی موتور تسلط (بدون دیتابیس)."""
from datetime import datetime, timedelta, timezone

from app.services import mastery_engine as me


def now():
    return datetime.now(timezone.utc)


FAST = {"solved": True, "time_ms": 1200, "retries": 0, "tool_correct": True}
SLOW_WRONG = {"solved": False, "time_ms": 12000, "retries": 3, "tool_correct": False}


def test_fast_solve_beats_slow_wrong():
    s1, _, _ = me.apply_event(0, 0, None, FAST, now())
    s2, _, _ = me.apply_event(0, 0, None, SLOW_WRONG, now())
    assert s1 > 20 and s2 == 0 and s1 > s2


def test_threshold_crossing_after_repeated_fast_solves():
    score, ev, mastered, at = 0.0, 0, False, None
    for _ in range(4):
        score, ev, mastered = me.apply_event(score, ev, at, FAST, now())
        at = now()
    assert mastered and score >= 70 and ev == 4


def test_half_life_decay_between_sessions():
    s1, ev, _ = me.apply_event(60, 3, now() - timedelta(days=28), FAST, now())
    # ۲ نیم‌عمر گذشته → ۶۰ × ۰.۲۵ = ۱۵ + ~۲۳ ← جمع
    assert 35 < s1 < 45


def test_readiness_labels():
    assert me.readiness_label(75) == "green"
    assert me.readiness_label(50) == "yellow"
    assert me.readiness_label(10) == "red"
