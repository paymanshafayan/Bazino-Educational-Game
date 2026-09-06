"""تورنمنت فصل — بررسی واجد بودن (همهٔ موضوعات فصل ۱ تسلط‌یافته؟) + ثبت قهرمانی."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from .. import models
from ..config import settings
from ..db import get_db
from ..security import require_role

router = APIRouter(prefix="/tournament", tags=["tournament"])

_SUBJECTS = ["math", "physics", "chemistry", "biology", "english", "ict", "logic"]


@router.get("/eligibility/{child_id}")
def eligibility(child_id: int, db: Session = Depends(get_db),
                _: models.User = Depends(require_role(
                    models.Role.PLAYER, models.Role.STAFF))):
    if not db.get(models.Child, child_id):
        raise HTTPException(404, "فرزند یافت نشد")
    avg = db.execute(
        select(func.avg(models.Mastery.score)).where(
            models.Mastery.child_id == child_id)).scalar() or 0.0
    per_subject = {}
    for s in _SUBJECTS:
        a = db.execute(
            select(func.avg(models.Mastery.score)).join(
                models.Topic, models.Topic.id == models.Mastery.topic_id).where(
                models.Mastery.child_id == child_id,
                models.Topic.subject == s)).scalar()
        per_subject[s] = a if a is not None else None
    clear_count = sum(1 for v in per_subject.values()
                      if v is not None and v >= settings.MASTERY_THRESHOLD)
    return {
        "child_id": child_id,
        "season": 1,
        "avg_pct": round(avg, 1),
        "threshold": settings.MASTERY_THRESHOLD,
        "subjects": per_subject,
        "cleared_subjects": clear_count,
        "eligible": clear_count >= 3,  # لااقل ۳ درس قهرمان‌شده برای فینال فصل ۱
    }
