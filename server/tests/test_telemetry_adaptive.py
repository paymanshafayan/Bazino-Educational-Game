"""تله‌متری واقعی روی API + پیکربندی تطبیقی (پوشش رگرسیون باگ ردیف تازهٔ Mastery)."""
import uuid

from app import models
from app.db import SessionLocal

TOPIC = "math.g8.guz.uslu"


def _player(client, make_user):
    tag = uuid.uuid4().hex[:6]
    player = make_user(f"tel-{tag}@test.dev", "secret1", "Oyuncu", "player", grade=8)
    db = SessionLocal()
    if not db.get(models.Topic, TOPIC):
        db.add(models.Topic(id=TOPIC, subject="math", grade=8, semester="guz",
                            unit="Cebir", name_tr="Üslü", name_en="Exponents",
                            name_fa="توان", source_url="", semester_estimate=True))
        db.commit()
    cid = db.query(models.Child).order_by(models.Child.id.desc()).first().id
    db.close()
    return player, cid


def test_telemetry_ingest_creates_and_grows_mastery(client, make_user):
    player, cid = _player(client, make_user)
    ev = {"type": "obstacle_solved", "topic_id": TOPIC,
          "payload": {"solved": True, "time_ms": 1500, "retries": 0,
                      "tool_correct": True}}
    r = client.post(f"/telemetry/events/{cid}", json=[ev] * 4, headers=player)
    assert r.status_code == 200 and r.json()["accepted"] == 4
    db = SessionLocal()
    m = db.get(models.Mastery, (cid, TOPIC))
    assert m is not None and m.mastered is True and m.evidence == 4
    db.close()


def test_adaptive_stage_config(client, make_user):
    player, cid = _player(client, make_user)
    r = client.get(f"/adaptive/stage/{cid}?region=math&season=1&index_no=2",
                   headers=player)
    assert r.status_code == 200
    rooms = r.json()["rooms"]
    assert rooms[-1]["type"] == "boss" and any(x["type"] == "battle" for x in rooms)


def test_tournament_eligibility(client, make_user):
    player, cid = _player(client, make_user)
    r = client.get(f"/tournament/eligibility/{cid}", headers=player)
    assert r.status_code == 200
    j = r.json()
    assert j["eligible"] is False and "avg_pct" in j and "subjects" in j
