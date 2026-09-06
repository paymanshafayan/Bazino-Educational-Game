"""احراز هویت: ثبت‌نام/ورود/ریفرش."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas, security
from ..db import get_db

router = APIRouter(prefix="/auth", tags=["auth"])

_ALLOWED_ROLES = {"player": models.Role.PLAYER, "parent": models.Role.PARENT,
                  "staff": models.Role.STAFF}


@router.post("/register", response_model=schemas.TokenPair)
def register(body: schemas.RegisterIn, db: Session = Depends(get_db)):
    if db.query(models.User).filter_by(email=body.email).first():
        raise HTTPException(409, "این ایمیل قبلاً ثبت شده است")
    role = _ALLOWED_ROLES.get(body.role)
    if role is None:
        raise HTTPException(400, "رول نامعتبر")
    user = models.User(email=body.email, hashed_password=security.hash_password(body.password),
                       display_name=body.display_name, role=role)
    db.add(user)
    db.flush()
    if role == models.Role.PLAYER:
        grade = body.grade if body.grade in range(6, 13) else 8
        db.add(models.Child(player_id=user.id, grade=grade, alias=body.display_name))
    if role == models.Role.PARENT:
        db.add(models.Wallet(parent_id=user.id, balance_kurus=0))
    db.commit()
    return security.make_token_pair(user.id)


@router.post("/login", response_model=schemas.TokenPair)
def login(body: schemas.LoginIn, db: Session = Depends(get_db)):
    user = db.query(models.User).filter_by(email=body.email).first()
    if not user or not security.verify_password(body.password, user.hashed_password):
        raise HTTPException(401, "ایمیل یا رمز نادرست است")
    return security.make_token_pair(user.id)


@router.get("/me", response_model=schemas.UserOut)
def me(user: models.User = Depends(security.get_current_user)):
    return schemas.UserOut(id=user.id, email=user.email,
                           display_name=user.display_name, role=user.role.value)


@router.get("/me/player")
def me_player(user: models.User = Depends(security.get_current_user),
              db: Session = Depends(get_db)):
    """پروفایل بازیکن برای کلاینت Godot (شناسهٔ Child + پایه)."""
    child = db.query(models.Child).filter_by(player_id=user.id).first()
    if not child:
        raise HTTPException(404, "پروفایل بازیکن یافت نشد")
    return {"child_id": child.id, "grade": child.grade, "alias": child.alias}
