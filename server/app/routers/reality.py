"""Reality Bridge: ثبت نمرات واقعی مدرسه (والد) ← بوف درون‌بازی.

بوف متوسط و سقف‌دار (ضد تورم امتیاز — GDD §۱۰). تأیید حضوری کارنامه در سالن = بوف قوی‌تر.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..security import require_role
from .links import linked_parent_id

router = APIRouter(prefix="/reality", tags=["reality-bridge"])

# سقف عدد بوف در هفته — ضد حجم‌رانی خودگزارشانهٔ والد
WEEK_BUFF_CAP = 5


def _buff_for(score: float, verified: bool) -> tuple[str, int]:
    if not verified:
        if score >= 90:
            return "energy_boost", 1
        if score >= 75:
            return "extra_life", 1
        return "none", 0
    # تأیید حضوری کارنامه در گیم‌نت → قوی‌تر + اسکین افتخاری
    if score >= 90:
        return "honor_skin", 1
    if score >= 75:
        return "energy_boost", 3
    if score >= 60:
        return "extra_life", 2
    return "none", 0


@router.post("/grades", response_model=schemas.BuffOut)
def submit_grade(body: schemas.SchoolGradeIn, db: Session = Depends(get_db),
                 parent: models.User = Depends(require_role(models.Role.PARENT))):
    if linked_parent_id(db, body.child_id) != parent.id:
        raise HTTPException(403, "این فرزند به کد خانوادهٔ شما متصل نیست")
    g = models.SchoolGrade(child_id=body.child_id, subject=body.subject,
                           grade_tr=f"{body.score:.0f}", score=body.score)
    db.add(g)
    db.commit()
    buff, amount = _buff_for(body.score, verified=False)
    return schemas.BuffOut(child_id=body.child_id, buff=buff, amount=amount)


@router.post("/verify", response_model=schemas.BuffOut)
def verify_grade(body: schemas.VerifyGradeIn, db: Session = Depends(get_db),
                 staff: models.User = Depends(require_role(models.Role.STAFF, models.Role.ADMIN))):
    """تأیید حضوری کارنامه توسط پرسنل سالن (سینرژی تجاری GDD §۱۰)."""
    g = db.get(models.SchoolGrade, body.grade_id)
    if not g:
        raise HTTPException(404, "نمره‌ای ثبت نشده")
    if g.verified_by_staff:
        raise HTTPException(409, "قبلاً تأیید شده")
    g.verified_by_staff = True
    db.commit()
    buff, amount = _buff_for(g.score, verified=True)
    return schemas.BuffOut(child_id=g.child_id, buff=buff, amount=amount)
