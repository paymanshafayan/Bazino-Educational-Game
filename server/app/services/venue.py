"""حالت سالن (Venue Mode) — راز روزانهٔ کوتاه به‌جای وابستگی به IP (GDD §۸.۱)."""
from __future__ import annotations

import io
import secrets
from datetime import datetime, timedelta, timezone

import qrcode
from sqlalchemy.orm import Session

from .. import models
from ..config import settings


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def issue_session(db: Session, staff_id: int, venue_name: str,
                  ttl_minutes: int | None = None) -> models.VenueSession:
    code = f"{secrets.randbelow(900000) + 100000}"  # ۶ رقم
    vs = models.VenueSession(
        venue_name=venue_name, code=code, issued_by=staff_id,
        expires_at=_utcnow() + timedelta(minutes=ttl_minutes or settings.VENUE_CODE_TTL_MIN))
    db.add(vs)
    db.commit()
    db.refresh(vs)
    return vs


def validate_code(db: Session, code: str) -> models.VenueSession | None:
    vs = db.query(models.VenueSession).filter(models.VenueSession.code == code).first()
    if not vs or not vs.active:
        return None
    exp = vs.expires_at
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    if exp < _utcnow():
        return None
    return vs


def qr_png_bytes(payload: str) -> bytes:
    img = qrcode.make(payload)
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()
