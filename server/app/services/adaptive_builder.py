"""سازندهٔ پیکربندی مرحلهٔ تطبیقی (GDD §۷.۲ — تزریق تطبیقی مباحث ضعیف).

دادهٔ ورودی: نقشهٔ تسلط فرزند ⇐ خروجی: StageConfig که کلاینت Godot با آن اتاق‌ها را می‌سازد.
بازیکن چیزی از این «تطبیق» نمی‌فهمد — دنیا فقط «متنوع‌تر» می‌شود.
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models

ROOM_TEMPLATES = {
    "obstacle": {"type": "obstacle", "ref_time_ms": 3000},
    "battle":   {"type": "battle", "enemies": 3},
    "treasure": {"type": "treasure"},
    "boss":     {"type": "boss"},
}


def weak_topics(db: Session, child_id: int, subject: str, limit: int = 3) -> list[str]:
    stmt = (
        select(models.Mastery.topic_id)
        .join(models.Topic, models.Topic.id == models.Mastery.topic_id)
        .where(models.Mastery.child_id == child_id,
               models.Topic.subject == subject,
               models.Mastery.score < 70.0)
        .order_by(models.Mastery.score.asc())
        .limit(limit)
    )
    return [r[0] for r in db.execute(stmt).all()]


def next_unseen_topics(db: Session, child_id: int, subject: str, semester: str,
                       limit: int = 2) -> list[str]:
    seen = select(models.Mastery.topic_id).where(models.Mastery.child_id == child_id)
    stmt = (
        select(models.Topic.id)
        .where(models.Topic.subject == subject,
               models.Topic.semester == semester,
               models.Topic.id.not_in(seen))
        .order_by(models.Topic.unit, models.Topic.id)
        .limit(limit)
    )
    return [r[0] for r in db.execute(stmt).all()]


def build_stage_config(db: Session, child_id: int, region: str, season: int = 1,
                       index_no: int = 1) -> dict:
    """اتاق‌های مرحله: [مانع(مبحث)?, مانع?, نبرد, گنجینه/فرمول, باس]."""
    subjects = {region: region for region in
                ["math", "physics", "chemistry", "biology", "english", "ict", "logic"]}
    subject = subjects.get(region, region)

    semester = "guz" if season == 1 else "bahar"
    weak = weak_topics(db, child_id, subject)
    fresh = next_unseen_topics(db, child_id, subject, semester)
    picks = (weak + [t for t in fresh if t not in weak])[:3]

    rooms: list[dict] = []
    for t in picks:
        rooms.append({**ROOM_TEMPLATES["obstacle"], "topic_id": t,
                      "reinjection": t in weak})  # تزریق تطبیقی = re در قالب تازه
    rooms.append(dict(ROOM_TEMPLATES["battle"]))
    rooms.append({**ROOM_TEMPLATES["treasure"], "topic_id": picks[0] if picks else None})
    rooms.append({**ROOM_TEMPLATES["boss"], "topics": picks})

    return {"region": region, "season": season, "index_no": index_no,
            "rooms": rooms, "weak_topics": weak}
