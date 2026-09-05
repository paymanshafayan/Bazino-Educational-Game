"""موتور تسلط تطبیقی v1 (GDD §۷.۲ — BKT سبکِ قابل‌توضیح، بدون ML سنگین).

فرمول:  M = 100 × (۰٫۳۵·سرعت + ۰٫۲۵·اول‌بارگی + ۰٫۲۵·ابزار درست + ۰٫۱۵·تکرار بین‌جلساتی)
با فراموشی نیم‌عمری ۱۴روزه بین جلسات بازی. آستانهٔ «ملکه ذهن» = MASTERY_THRESHOLD (۷۰).
خروجی صرفاً برای والد/ادمین است — بازیکن هرگز نمره نمی‌بیند.
"""
from __future__ import annotations

import math
from datetime import datetime, timezone

from ..config import settings

W_SPEED, W_FIRST, W_TOOL, W_RETENTION = 0.35, 0.25, 0.25, 0.15
HALF_LIFE_DAYS = 14.0
DELTA_BASE = 28.0
PENALTY_WRONG = 10.0
REF_TIME_MS = 3000  # زمان مرجع «تفکر طبیعی» برای هر مانع


def _days_since(prev: datetime | None, now: datetime) -> float:
    if prev is None:
        return 0.0
    if prev.tzinfo is None:
        prev = prev.replace(tzinfo=timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)
    return max(0.0, (now - prev).total_seconds() / 86400.0)


def speed_term(time_ms: int | None) -> float:
    """۱ برای پاسخ طبیعی/سریع، افت نمایی برای کندی (کف ۰٫۱۵)."""
    if time_ms is None:
        return 0.5
    if time_ms <= REF_TIME_MS:
        return 1.0
    return max(0.15, math.exp(-(time_ms - REF_TIME_MS) / REF_TIME_MS))


def first_try_term(retries: int | None) -> float:
    r = max(0, retries or 0)
    return 1.0 if r == 0 else 0.6 ** min(r, 4)


def tool_term(tool_correct: bool | None) -> float:
    return 1.0 if tool_correct else 0.0


def retention_term(evidence: int, days: float) -> float:
    """تثبیت‌داشتن مبحث از قبل، با فراموشی بین جلسات."""
    if evidence <= 0:
        return 0.0
    base = min(1.0, 0.5 + 0.1 * evidence)
    return base * (0.5 ** (days / HALF_LIFE_DAYS))


def apply_event(score: float, evidence: int, last_at: datetime | None,
                payload: dict, now: datetime) -> tuple[float, int, bool]:
    """یک رویداد مانع/باس را روی ردیف تسلط اعمال می‌کند ← (score, evidence, mastered)."""
    solved = bool(payload.get("solved", False))
    days = _days_since(last_at, now)
    # فراموشی بین جلسات (فقط اگر جلسهٔ قبل گذشته باشد)
    decayed = score * (0.5 ** (days / HALF_LIFE_DAYS)) if days > 0 else score

    if solved:
        gain = DELTA_BASE * (
            W_SPEED * speed_term(payload.get("time_ms"))
            + W_FIRST * first_try_term(payload.get("retries"))
            + W_TOOL * tool_term(payload.get("tool_correct"))
            + W_RETENTION * retention_term(evidence, days)
        )
        new_score = min(100.0, decayed + gain)
    else:
        new_score = max(0.0, decayed - PENALTY_WRONG)

    return new_score, evidence + 1, new_score >= settings.MASTERY_THRESHOLD


def readiness_label(score_avg: float) -> str:
    """چراغ آمادگی امتحان فصل برای والد (سبز/زرد/قرمز)."""
    if score_avg >= 70:
        return "green"
    if score_avg >= 40:
        return "yellow"
    return "red"
