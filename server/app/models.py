"""مدل‌های دیتابیس — منعکس‌کنندهٔ GDD §۱۱.۲ (جداول کلیدی)."""
from datetime import datetime, timezone
import enum

from sqlalchemy import (JSON, Boolean, DateTime, Enum, Float, ForeignKey,
                        Integer, String, Text, UniqueConstraint)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


def utcnow():
    return datetime.now(timezone.utc)


class Role(str, enum.Enum):
    PLAYER = "player"   # بازیکن (فرزند)
    PARENT = "parent"   # والد
    STAFF = "staff"     # پرسنل گیم‌نت
    ADMIN = "admin"


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    display_name: Mapped[str] = mapped_column(String(120))
    role: Mapped[Role] = mapped_column(Enum(Role))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    child: Mapped["Child"] = relationship(back_populates="player", uselist=False)


class Child(Base):
    """پروفایل بازیکن — بدون نام واقعی؛ فقط نام‌نمایشی (حریم کودک)."""
    __tablename__ = "children"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True)
    grade: Mapped[int] = mapped_column(Integer)  # 6..12
    alias: Mapped[str] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    player: Mapped[User] = relationship(back_populates="child")


class FamilyLink(Base):
    """کد خانواده: والد می‌سازد ← بازیکن می‌پذیرد."""
    __tablename__ = "family_links"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    parent_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    child_id: Mapped[int | None] = mapped_column(ForeignKey("children.id"), nullable=True)
    code: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    active: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Topic(Base):
    __tablename__ = "topics"
    id: Mapped[str] = mapped_column(String(64), primary_key=True)  # e.g. math.g8.guz.uslu
    subject: Mapped[str] = mapped_column(String(32), index=True)
    grade: Mapped[int] = mapped_column(Integer, index=True)
    semester: Mapped[str] = mapped_column(String(8))  # guz | bahar
    unit: Mapped[str] = mapped_column(String(120))
    name_tr: Mapped[str] = mapped_column(String(200))
    name_en: Mapped[str] = mapped_column(String(200))
    name_fa: Mapped[str] = mapped_column(String(200))
    source_url: Mapped[str] = mapped_column(Text, default="")
    semester_estimate: Mapped[bool] = mapped_column(Boolean, default=False)


class Event(Base):
    """رویداد خام گیم‌پلی (تله‌متری) — مبنای موتور تسلط."""
    __tablename__ = "events"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    child_id: Mapped[int] = mapped_column(ForeignKey("children.id"), index=True)
    type: Mapped[str] = mapped_column(String(48), index=True)
    topic_id: Mapped[str | None] = mapped_column(ForeignKey("topics.id"), nullable=True, index=True)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class Mastery(Base):
    __tablename__ = "mastery"
    child_id: Mapped[int] = mapped_column(ForeignKey("children.id"), primary_key=True)
    topic_id: Mapped[str] = mapped_column(ForeignKey("topics.id"), primary_key=True)
    score: Mapped[float] = mapped_column(Float, default=0.0)
    evidence: Mapped[int] = mapped_column(Integer, default=0)
    mastered: Mapped[bool] = mapped_column(Boolean, default=False)
    last_event_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class Stage(Base):
    __tablename__ = "stages"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    region: Mapped[str] = mapped_column(String(32), index=True)  # math/physics/...
    season: Mapped[int] = mapped_column(Integer, default=1)
    index_no: Mapped[int] = mapped_column(Integer)  # مرحلهٔ ۱، ۲، …
    weekly: Mapped[bool] = mapped_column(Boolean, default=False)  # مرحلهٔ هفتگی گیم‌نت؟
    config: Mapped[dict] = mapped_column(JSON, default=dict)
    price_kurus: Mapped[int] = mapped_column(Integer, default=0)  # مرحلهٔ ۱ = رایگان


class VenueSession(Base):
    """جلسهٔ «حالت سالن» — کد روزانهٔ کوتاه (به‌جای IP)."""
    __tablename__ = "venue_sessions"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    venue_name: Mapped[str] = mapped_column(String(120))
    code: Mapped[str] = mapped_column(String(8), unique=True, index=True)
    issued_by: Mapped[int] = mapped_column(ForeignKey("users.id"))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Wallet(Base):
    __tablename__ = "wallets"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    parent_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True)
    balance_kurus: Mapped[int] = mapped_column(Integer, default=0)  # ۱ لیرا = ۱۰۰ قرش
    currency: Mapped[str] = mapped_column(String(4), default="TRY")


class TxType(str, enum.Enum):
    TOPUP_CASH = "topup_cash"        # شارژ نقدی حضوری در سالن
    TOPUP_POS = "topup_pos"          # درگاه آنلاین (آینده — غیرفعال)
    SPEND_STAGE = "spend_stage"      # خرید بازکردن مرحله
    REWARD_REDEEM = "reward_redeem"  # تبدیل اعتبار جوایز


class Transaction(Base):
    __tablename__ = "transactions"
    __table_args__ = (UniqueConstraint("request_id", name="uq_tx_request"),)
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    wallet_id: Mapped[int] = mapped_column(ForeignKey("wallets.id"), index=True)
    type: Mapped[TxType] = mapped_column(Enum(TxType))
    amount_kurus: Mapped[int] = mapped_column(Integer)  # +شارژ / -مصرف
    request_id: Mapped[str] = mapped_column(String(64), index=True)  # Idempotency-Key
    ref_code: Mapped[str] = mapped_column(String(24), default="")    # کد رسید HMAC
    issued_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    note: Mapped[str] = mapped_column(String(255), default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class RewardTier(str, enum.Enum):
    COUPON = "coupon"      # کوپن تخفیف/ساعت رایگان
    MID = "mid"            # جایزهٔ متوسط فصل
    GRAND = "grand"        # جایزهٔ بزرگ فینال فصل (دوچرخه/PS5)


class Reward(Base):
    __tablename__ = "rewards"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    tier: Mapped[RewardTier] = mapped_column(Enum(RewardTier))
    season: Mapped[int] = mapped_column(Integer, default=1)
    stock: Mapped[int] = mapped_column(Integer, default=0)
    requires_mastery: Mapped[bool] = mapped_column(Boolean, default=False)  # جایزهٔ بزرگ ← تسلط
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Redemption(Base):
    __tablename__ = "redemptions"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    reward_id: Mapped[int] = mapped_column(ForeignKey("rewards.id"))
    child_id: Mapped[int] = mapped_column(ForeignKey("children.id"), index=True)
    code: Mapped[str] = mapped_column(String(24), unique=True)  # کد یک‌بارمصرف تحویل در سالن
    redeemed: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class SchoolGrade(Base):
    """Reality Bridge: نمرهٔ واقعی ثبت‌شده توسط والد — بوف درون‌بازی."""
    __tablename__ = "school_grades"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    child_id: Mapped[int] = mapped_column(ForeignKey("children.id"), index=True)
    subject: Mapped[str] = mapped_column(String(32))
    grade_tr: Mapped[str] = mapped_column(String(8))   # نمرهٔ سیستم ۱۰۰/۵ مدرسه
    score: Mapped[float] = mapped_column(Float)        # عددی ۰..۱۰۰
    verified_by_staff: Mapped[bool] = mapped_column(Boolean, default=False)  # تأیید حضوری کارنامه
    buff_claimed: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
