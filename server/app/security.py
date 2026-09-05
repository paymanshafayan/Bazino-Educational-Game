"""احراز هویت JWT + هش رمز + نگهبان نقش‌ها."""
from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
import bcrypt
from sqlalchemy.orm import Session

from .config import settings
from .db import get_db
from . import models

oauth2 = OAuth2PasswordBearer(tokenUrl="/auth/login")
ALGO = "HS256"


def hash_password(p: str) -> str:
    return bcrypt.hashpw(p.encode()[:72], bcrypt.gensalt()).decode()


def verify_password(p: str, h: str) -> bool:
    try:
        return bcrypt.checkpw(p.encode()[:72], h.encode())
    except ValueError:
        return False


def _make_token(sub: str, kind: str, ttl: timedelta) -> str:
    now = datetime.now(timezone.utc)
    return jwt.encode({"sub": sub, "kind": kind, "iat": now, "exp": now + ttl},
                      settings.JWT_SECRET, algorithm=ALGO)


def make_token_pair(user_id: int) -> dict:
    return {
        "access_token": _make_token(str(user_id), "access", timedelta(minutes=settings.ACCESS_TOKEN_MIN)),
        "refresh_token": _make_token(str(user_id), "refresh", timedelta(days=settings.REFRESH_TOKEN_DAYS)),
        "token_type": "bearer",
    }


def get_current_user(token: str = Depends(oauth2), db: Session = Depends(get_db)) -> models.User:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[ALGO])
        if payload.get("kind") != "access":
            raise ValueError
        user_id = int(payload["sub"])
    except (JWTError, ValueError, KeyError):
        raise HTTPException(401, "توکن نامعتبر است")
    user = db.get(models.User, user_id)
    if not user:
        raise HTTPException(401, "کاربر یافت نشد")
    return user


def require_role(*roles: models.Role):
    def guard(user: models.User = Depends(get_current_user)) -> models.User:
        if user.role not in roles:
            raise HTTPException(403, "مجاز نیستید")
        return user
    return guard
