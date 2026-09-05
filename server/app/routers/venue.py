"""حالت سالن: صدور کد/QR روزانه (ادمین) ← ورود بازیکن با کد."""
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..security import require_role
from ..services import venue as venue_svc

router = APIRouter(prefix="/venue", tags=["venue-mode"])


@router.post("/issue", response_model=schemas.VenueIssueOut)
def issue(body: schemas.VenueIssueIn,
          db: Session = Depends(get_db),
          staff: models.User = Depends(require_role(models.Role.STAFF, models.Role.ADMIN))):
    vs = venue_svc.issue_session(db, staff.id, body.venue_name, body.ttl_minutes)
    return schemas.VenueIssueOut(code=vs.code, expires_at=vs.expires_at)


@router.get("/qr/{code}")
def qr_image(code: str, db: Session = Depends(get_db),
             _: models.User = Depends(require_role(models.Role.STAFF, models.Role.ADMIN))):
    if not venue_svc.validate_code(db, code):
        raise HTTPException(404, "کد منقضی یا نامعتبر است")
    png = venue_svc.qr_png_bytes(f"BZ-VENUE:{code}")
    return Response(content=png, media_type="image/png")


@router.post("/join")
def join(body: schemas.VenueJoinIn, db: Session = Depends(get_db),
         _: models.User = Depends(require_role(models.Role.PLAYER))):
    vs = venue_svc.validate_code(db, body.code)
    if not vs:
        raise HTTPException(403, "کد سالن منقضی یا نامعتبر است — کد تازه از باجه بگیرید")
    return {"venue_mode": True, "venue": vs.venue_name, "expires_at": vs.expires_at}
