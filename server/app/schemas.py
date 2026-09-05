"""قراردادهای API (Pydantic) — مرجع کلاینت Godot و اپ Flutter."""
from datetime import datetime

from pydantic import BaseModel, Field

# ── Auth ──────────────────────────────────────────────
class RegisterIn(BaseModel):
    email: str
    password: str = Field(min_length=6)
    display_name: str
    role: str = "player"          # player|parent|staff (admin با سید)
    grade: int | None = None      # برای player: پایهٔ تحصیلی ۶–۱۲

class LoginIn(BaseModel):
    email: str
    password: str

class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class UserOut(BaseModel):
    id: int
    email: str
    display_name: str
    role: str

# ── Links ─────────────────────────────────────────────
class LinkCreateIn(BaseModel):
    pass  # کد تولید می‌شود

class LinkOut(BaseModel):
    code: str
    active: bool
    child_id: int | None

class LinkAcceptIn(BaseModel):
    code: str

# ── Telemetry & Mastery ───────────────────────────────
class EventIn(BaseModel):
    type: str                     # obstacle_solved | boss_phase | tool_acquired | ...
    topic_id: str | None = None
    payload: dict = {}            # time_ms, retries, tool_correct, solved ...
    client_ts: datetime | None = None

class MasteryRow(BaseModel):
    topic_id: str
    subject: str
    name_tr: str
    score: float
    mastered: bool
    evidence: int

class MasteryReport(BaseModel):
    child_id: int
    season: int
    rows: list[MasteryRow]
    exam_readiness: dict          # subject -> green|yellow|red

# ── Adaptive ──────────────────────────────────────────
class StageConfig(BaseModel):
    region: str
    season: int
    index_no: int
    rooms: list[dict]
    weak_topics: list[str]

# ── Venue ─────────────────────────────────────────────
class VenueIssueIn(BaseModel):
    venue_name: str = "Bazino GameNet"
    ttl_minutes: int | None = None

class VenueIssueOut(BaseModel):
    code: str
    expires_at: datetime

class VenueJoinIn(BaseModel):
    code: str

# ── Wallet ────────────────────────────────────────────
class TopupIn(BaseModel):
    parent_id: int
    amount_kurus: int = Field(gt=0)
    request_id: str
    note: str = ""

class SpendIn(BaseModel):
    child_id: int
    stage_id: int
    request_id: str

class WalletOut(BaseModel):
    balance_kurus: int
    currency: str
    history: list[dict]

class TxOut(BaseModel):
    id: int
    type: str
    amount_kurus: int
    ref_code: str
    created_at: datetime

# ── Reality Bridge ────────────────────────────────────
class SchoolGradeIn(BaseModel):
    child_id: int
    subject: str
    score: float = Field(ge=0, le=100)
    term: str = "2026-güz"

class VerifyGradeIn(BaseModel):
    grade_id: int

class BuffOut(BaseModel):
    child_id: int
    buff: str                    # extra_life | energy_boost | honor_skin
    amount: int

# ── Rewards ───────────────────────────────────────────
class RewardOut(BaseModel):
    id: int
    title: str
    tier: str
    stock: int
    requires_mastery: bool

class RedeemIn(BaseModel):
    child_id: int
    reward_id: int

class RedeemOut(BaseModel):
    code: str
    reward_id: int
