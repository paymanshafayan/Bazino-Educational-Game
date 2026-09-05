"""کد خانواده: والد می‌سازد ← بازیکن در کلاینت بازی وارد می‌کند (اتصال امن)."""
import secrets

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..security import get_current_user, require_role

router = APIRouter(prefix="/links", tags=["family-link"])


@router.post("/create", response_model=schemas.LinkOut)
def create_link(_: schemas.LinkCreateIn | None = None,
                db: Session = Depends(get_db),
                parent: models.User = Depends(require_role(models.Role.PARENT))):
    code = secrets.token_hex(3).upper()  # ۶ کاراکتر
    link = models.FamilyLink(parent_id=parent.id, code=code, active=False)
    db.add(link)
    db.commit()
    db.refresh(link)
    return schemas.LinkOut(code=link.code, active=link.active, child_id=link.child_id)


@router.post("/accept", response_model=schemas.LinkOut)
def accept_link(body: schemas.LinkAcceptIn,
                db: Session = Depends(get_db),
                player: models.User = Depends(require_role(models.Role.PLAYER))):
    link = db.query(models.FamilyLink).filter_by(code=body.code.upper()).first()
    if not link or link.active:
        raise HTTPException(404, "کد خانواده نامعتبر یا قبلاً مصرف شده")
    child = db.query(models.Child).filter_by(player_id=player.id).first()
    if not child:
        raise HTTPException(400, "پروفایل بازیکن یافت نشد")
    link.child_id = child.id
    link.active = True
    db.commit()
    return schemas.LinkOut(code=link.code, active=True, child_id=child.id)


@router.get("/mine", response_model=list[schemas.LinkOut])
def my_links(db: Session = Depends(get_db),
             parent: models.User = Depends(require_role(models.Role.PARENT))):
    links = db.query(models.FamilyLink).filter_by(parent_id=parent.id).all()
    return [schemas.LinkOut(code=l.code, active=l.active, child_id=l.child_id) for l in links]


def linked_parent_id(db: Session, child_id: int) -> int | None:
    l = db.query(models.FamilyLink).filter_by(child_id=child_id, active=True).first()
    return l.parent_id if l else None
