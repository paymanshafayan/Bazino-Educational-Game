"""پنل مدیریت پایه: شاخص‌های سلامت + فهرست تراکنش‌ها + صدور/تأیید کدهای سالن."""
from fastapi import APIRouter, Depends
from fastapi.responses import FileResponse
from sqlalchemy import func
from sqlalchemy.orm import Session

from .. import models
from ..db import get_db
from ..security import require_role

router = APIRouter(prefix="/admin", tags=["admin-panel"])

import pathlib
_STATIC = pathlib.Path(__file__).resolve().parents[1] / "static" / "admin.html"


@router.get("/ui", include_in_schema=False)
def admin_ui():
    """صفحهٔ باجهٔ گیم‌نت (احراز هویت داخل صفحه با JWT کارکنان)."""
    return FileResponse(_STATIC)


@router.get("/stats")
def stats(db: Session = Depends(get_db),
          _: models.User = Depends(require_role(models.Role.STAFF, models.Role.ADMIN))):
    return {
        "users": db.scalar(select_count(db, models.User)),
        "children": db.scalar(select_count(db, models.Child)),
        "events": db.scalar(select_count(db, models.Event)),
        "mastery_rows": db.scalar(select_count(db, models.Mastery)),
        "wallet_total_kurus": db.scalar(
            func.coalesce(func.sum(models.Wallet.balance_kurus), 0)),
    }


def select_count(db, model):
    from sqlalchemy import func as f, select
    return select(f.count()).select_from(model)


@router.get("/transactions")
def transactions(db: Session = Depends(get_db),
                 _: models.User = Depends(require_role(models.Role.STAFF, models.Role.ADMIN))):
    txs = (db.query(models.Transaction)
           .order_by(models.Transaction.id.desc()).limit(100).all())
    return [{"id": t.id, "wallet_id": t.wallet_id, "type": t.type.value,
             "amount_kurus": t.amount_kurus, "ref_code": t.ref_code,
             "note": t.note} for t in txs]


@router.get("/redemptions")
def redemptions(db: Session = Depends(get_db),
                _: models.User = Depends(require_role(models.Role.STAFF, models.Role.ADMIN))):
    reds = db.query(models.Redemption).order_by(models.Redemption.id.desc()).limit(100).all()
    return [{"id": r.id, "reward_id": r.reward_id, "child_id": r.child_id,
             "code": r.code, "redeemed": r.redeemed} for r in reds]
