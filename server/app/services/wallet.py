"""کیف پول والد — D11: شارژ حضوری در گیم‌نت پیش‌فرض؛ درگاه آنلاین آمادهٔ فعال‌سازی."""
from __future__ import annotations

from sqlalchemy.orm import Session

from .. import models
from ..config import settings
from .receipts import make_ref_code


class PaymentError(Exception):
    pass


# ── لایهٔ انتزاعی درگاه (پیوست پرداخت GDD §۹.۳) ─────────────
class IPaymentGateway:
    name = "abstract"

    def create_charge(self, amount_kurus: int, **kw) -> dict:  # pragma: no cover
        raise NotImplementedError

    def verify(self, payment_id: str) -> bool:  # pragma: no cover
        raise NotImplementedError


class ManualCashGateway(IPaymentGateway):
    """سازوکار اصلی فعلی: پرداخت نقدی در سالن ← شارژ لحظه‌ای توسط ادمین."""
    name = "manual"

    def create_charge(self, amount_kurus: int, **kw) -> dict:
        return {"status": "ok", "provider": self.name, "amount_kurus": amount_kurus}


class BankGatewayStub(IPaymentGateway):
    """اسکلت‌های خاموش İktisat Bank (Cardplus) و Near East Bank (Virtual POS).

    فعال‌سازی = نیازمند مدارک ثبتی شرکت + تایید بانک (بلاکر مالک — HANDOFF).
    تا آن زمان GATEWAY_PROVIDER=manual باقی می‌ماند و این کلاس‌ها فقط قرارداد API را
    مستند می‌کنند تا سوییچ آینده بدون تغییر معماری انجام شود.
    """
    name = "bank-stub"

    def create_charge(self, amount_kurus: int, **kw) -> dict:
        raise PaymentError("درگاه بانکی هنوز فعال نشده است (بلاکر مالک: مدارک ثبت شرکت)")

    def verify(self, payment_id: str) -> bool:
        return False


def get_gateway() -> IPaymentGateway:
    match settings.GATEWAY_PROVIDER:
        case "manual":
            return ManualCashGateway()
        case "iktisat" | "neareast":
            return BankGatewayStub()
        case _:
            return ManualCashGateway()


# ── عملیات کیف پول ──────────────────────────────────────────
def get_or_create_wallet(db: Session, parent_id: int) -> models.Wallet:
    w = db.query(models.Wallet).filter_by(parent_id=parent_id).first()
    if not w:
        w = models.Wallet(parent_id=parent_id, balance_kurus=0)
        db.add(w)
        db.commit()
        db.refresh(w)
    return w


def _inject_tx(db: Session, w: models.Wallet, ttype: models.TxType, amount: int,
               request_id: str, issued_by: int | None, note: str) -> models.Transaction:
    """Idempotent: request_id یکتا → تکرار درخواست، تراکنش قبلی را برمی‌گرداند."""
    existing = db.query(models.Transaction).filter_by(request_id=request_id).first()
    if existing:
        return existing
    gateway = get_gateway()
    if amount > 0:
        gateway.create_charge(amount)  # در حالت manual همیشه ok است
    tx = models.Transaction(wallet_id=w.id, type=ttype, amount_kurus=amount,
                            request_id=request_id, issued_by=issued_by, note=note)
    tx.ref_code = make_ref_code(f"{request_id}:{amount}")
    w.balance_kurus += amount
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx


def topup_cash(db: Session, parent_id: int, amount_kurus: int,
               request_id: str, staff_id: int, note: str = "") -> models.Transaction:
    if amount_kurus <= 0:
        raise PaymentError("مبلغ نامعتبر")
    w = get_or_create_wallet(db, parent_id)
    return _inject_tx(db, w, models.TxType.TOPUP_CASH, amount_kurus,
                      request_id, staff_id, note or "شارژ حضوری در گیم‌نت")


def spend_stage(db: Session, parent_id: int, child_id: int, stage: models.Stage,
                request_id: str) -> models.Transaction:
    w = get_or_create_wallet(db, parent_id)
    if stage.price_kurus <= 0:
        # مرحلهٔ رایگان — بدون تراکنش مالی، ولی برای ردگیری ثبت صفر
        return _inject_tx(db, w, models.TxType.SPEND_STAGE, 0, request_id, None,
                          f"مرحلهٔ رایگان {stage.id}")
    if w.balance_kurus < stage.price_kurus:
        raise PaymentError("موجودی کافی نیست — لطفاً کیف پول را حضوری شارژ کنید")
    return _inject_tx(db, w, models.TxType.SPEND_STAGE, -stage.price_kurus,
                      request_id, None, f"بازکردن مرحلهٔ {stage.id} برای فرزند {child_id}")
