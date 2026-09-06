"""کیف پول والد: مانده/تاریخچه (والد) · شارژ نقدی حضوری (ادمین) · خرید مرحله."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..db import get_db
from ..security import require_role
from ..services.wallet import PaymentError, get_or_create_wallet, spend_stage, topup_cash
from .links import linked_parent_id

router = APIRouter(prefix="/wallet", tags=["wallet"])


@router.get("/gateway_status")
def gateway_status(_: models.User = Depends(require_role(models.Role.PARENT,
                     models.Role.STAFF, models.Role.ADMIN))):
    """وضعیت درگاه پرداخت برای اپ والدین: فعلی=حضوری manual؛ بانکی=آمادهٔ فعال‌سازی."""
    from ..config import settings
    return {
        "provider": settings.GATEWAY_PROVIDER,
        "online_gateway_enabled": settings.GATEWAY_PROVIDER != "manual",
        "planned": ["iktisat_cardplus (Cardplus Sanal POS)",
                    "near_east (Virtual POS)"],
        "candidates_docs": "design/ACTION-ADVENTURE-GDD.md §۹.۳",
    }


@router.get("", response_model=schemas.WalletOut)
def my_wallet(db: Session = Depends(get_db),
              parent: models.User = Depends(require_role(models.Role.PARENT))):
    w = get_or_create_wallet(db, parent.id)
    txs = (db.query(models.Transaction).filter_by(wallet_id=w.id)
           .order_by(models.Transaction.id.desc()).limit(50).all())
    return schemas.WalletOut(balance_kurus=w.balance_kurus, currency=w.currency, history=[{
        "id": t.id, "type": t.type.value, "amount_kurus": t.amount_kurus,
        "ref_code": t.ref_code, "note": t.note} for t in txs])


@router.post("/topup_cash", response_model=schemas.TxOut)
def topup(body: schemas.TopupIn, db: Session = Depends(get_db),
          staff: models.User = Depends(require_role(models.Role.STAFF, models.Role.ADMIN))):
    """پرداخت حضوری در سالن ← شارژ لحظه‌ای. Idempotent با request_id."""
    try:
        tx = topup_cash(db, body.parent_id, body.amount_kurus, body.request_id,
                        staff.id, body.note)
    except PaymentError as e:
        raise HTTPException(400, str(e))
    return schemas.TxOut(id=tx.id, type=tx.type.value, amount_kurus=tx.amount_kurus,
                         ref_code=tx.ref_code, created_at=tx.created_at)


@router.post("/spend_stage", response_model=schemas.TxOut)
def spend(body: schemas.SpendIn, db: Session = Depends(get_db),
          parent: models.User = Depends(require_role(models.Role.PARENT))):
    if linked_parent_id(db, body.child_id) != parent.id:
        raise HTTPException(403, "این فرزند به کد خانوادهٔ شما متصل نیست")
    stage = db.get(models.Stage, body.stage_id)
    if not stage:
        raise HTTPException(404, "مرحله یافت نشد")
    try:
        tx = spend_stage(db, parent.id, body.child_id, stage, body.request_id)
    except PaymentError as e:
        raise HTTPException(402, str(e))
    return schemas.TxOut(id=tx.id, type=tx.type.value, amount_kurus=tx.amount_kurus,
                         ref_code=tx.ref_code, created_at=tx.created_at)
