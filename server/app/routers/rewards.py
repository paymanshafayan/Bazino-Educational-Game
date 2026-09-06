"""کاتالوگ جوایز غیرنقدی فصل (D9) + صدور کد تحویل در سالن."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..security import require_role
from ..services.receipts import random_redeem_code

router = APIRouter(prefix="/rewards", tags=["rewards"])


@router.get("/catalog", response_model=list[schemas.RewardOut])
def catalog(db: Session = Depends(get_db)):
    rewards = db.query(models.Reward).filter_by(active=True, season=1).all()
    return [schemas.RewardOut(id=r.id, title=r.title, tier=r.tier.value, stock=r.stock,
                              requires_mastery=r.requires_mastery) for r in rewards]


def _mastery_ratio(db: Session, child_id: int) -> float:
    scores = db.execute(
        select(func.avg(models.Mastery.score)).where(
            models.Mastery.child_id == child_id)).scalar()
    return (scores or 0.0) / 100.0


@router.post("/redeem", response_model=schemas.RedeemOut)
def redeem(body: schemas.RedeemIn, db: Session = Depends(get_db),
           _: models.User = Depends(require_role(models.Role.PLAYER, models.Role.STAFF))):
    reward = db.get(models.Reward, body.reward_id)
    if not reward or not reward.active:
        raise HTTPException(404, "جایزه یافت نشد")
    if reward.stock <= 0:
        raise HTTPException(409, "موجودی جایزه تمام شده")
    if reward.requires_mastery and _mastery_ratio(db, body.child_id) < 0.7:
        raise HTTPException(403, "برای این جایزهٔ بزرگ باید فصل را «قهرمان» شوید (تسلط ≥ ۷۰٪)")
    dup = db.query(models.Redemption).filter_by(
        reward_id=reward.id, child_id=body.child_id).first()
    if dup:
        raise HTTPException(409, "این جایزه قبلاً برای این بازیکن صادر شده")
    reward.stock -= 1
    red = models.Redemption(reward_id=reward.id, child_id=body.child_id,
                            code=random_redeem_code())
    db.add(red)
    db.commit()
    return schemas.RedeemOut(code=red.code, reward_id=reward.id)
