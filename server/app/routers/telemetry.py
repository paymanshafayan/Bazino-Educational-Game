"""دریافت رویدادهای خام گیم‌پلی + به‌روزرسانی لحظه‌ای موتور تسلط (پنهان از بازیکن)."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..security import require_role
from ..services import mastery_engine

router = APIRouter(prefix="/telemetry", tags=["telemetry"])

_RATE_TYPES = {"obstacle_solved", "boss_phase", "obstacle_attempt"}


@router.post("/events/{child_id}")
def ingest_events(child_id: int, events: list[schemas.EventIn],
                  db: Session = Depends(get_db),
                  _: models.User = Depends(require_role(models.Role.PLAYER, models.Role.STAFF))):
    child = db.get(models.Child, child_id)
    if not child:
        raise HTTPException(404, "فرزند یافت نشد")
    now = datetime.now(timezone.utc)
    batch: dict[tuple, models.Mastery] = {}   # کش دسته‌ای — ردیف تازه بین رویدادها تکرار نشود
    for ev in events:
        row = models.Event(child_id=child_id, type=ev.type, topic_id=ev.topic_id,
                           payload=ev.payload or {})
        db.add(row)
        if ev.type in _RATE_TYPES and ev.topic_id:
            key = (child_id, ev.topic_id)
            m = batch.get(key) or db.get(models.Mastery, key)
            if not m:
                m = models.Mastery(child_id=child_id, topic_id=ev.topic_id,
                                   score=0.0, evidence=0, mastered=False)
                db.add(m)
            batch[key] = m
            m.score, m.evidence, m.mastered = mastery_engine.apply_event(
                m.score, m.evidence, m.last_event_at, ev.payload or {}, now)
            m.last_event_at = now
    db.commit()
    return {"accepted": len(events)}
