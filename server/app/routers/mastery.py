"""گزارش تسلط برای والد/ادمین — بازیکن به این endpoint دسترسی ندارد (حریم آموزش پنهان)."""
from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..security import require_role
from ..services.mastery_engine import readiness_label
from .links import linked_parent_id

router = APIRouter(prefix="/mastery", tags=["mastery"])


@router.get("/{child_id}", response_model=schemas.MasteryReport)
def mastery_report(child_id: int, db: Session = Depends(get_db),
                   user: models.User = Depends(require_role(
                       models.Role.PARENT, models.Role.STAFF, models.Role.ADMIN))):
    if user.role == models.Role.PARENT and linked_parent_id(db, child_id) != user.id:
        raise HTTPException(403, "این فرزند به کد خانوادهٔ شما متصل نیست")

    stmt = (select(models.Mastery, models.Topic)
            .join(models.Topic, models.Topic.id == models.Mastery.topic_id)
            .where(models.Mastery.child_id == child_id))
    rows, by_subject = [], defaultdict(list)
    for m, t in db.execute(stmt).all():
        rows.append(schemas.MasteryRow(topic_id=t.id, subject=t.subject, name_tr=t.name_tr,
                                       score=round(m.score, 1), mastered=m.mastered,
                                       evidence=m.evidence))
        by_subject[t.subject].append(m.score)
    readiness = {s: readiness_label(sum(v) / len(v)) for s, v in by_subject.items()}
    return schemas.MasteryReport(child_id=child_id, season=1, rows=rows,
                                 exam_readiness=readiness)
