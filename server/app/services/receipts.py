"""کدهای رسید/تحویل یک‌بارمصرف با امضای HMAC (سبرور HMAC secret)."""
from __future__ import annotations

import hashlib
import hmac
import secrets

from ..config import settings


def make_ref_code(raw: str) -> str:
    """کد خوانا: BZ-XXXX-XXXX امضادار با HMAC تا جعل در سالن غیرممکن شود."""
    sig = hmac.new(settings.JWT_SECRET.encode(), raw.encode(),
                   hashlib.sha256).hexdigest()[:8].upper()
    return f"BZ-{sig[:4]}-{sig[4:]}"


def random_redeem_code() -> str:
    return f"RD-{secrets.token_hex(3).upper()}"
