"""Reality Bridge + کاتالوگ جوایز."""
import uuid

from app import models
from app.db import SessionLocal


def _link_family(client, make_user):
    tag = uuid.uuid4().hex[:6]
    parent = make_user(f"rb-parent-{tag}@test.dev", "secret1", "والد", "parent")
    player = make_user(f"rb-player-{tag}@test.dev", "secret1", "Oyuncu", "player", grade=8)
    link = client.post("/links/create", json={}, headers=parent).json()
    client.post("/links/accept", json={"code": link["code"]}, headers=player)
    db = SessionLocal()
    child = db.query(models.Child).order_by(models.Child.id.desc()).first()
    cid = child.id
    db.close()
    return parent, player, cid


def test_reality_bridge_self_report_buff(client, make_user):
    parent, _, cid = _link_family(client, make_user)
    r = client.post("/reality/grades",
                    json={"child_id": cid, "subject": "math", "score": 92},
                    headers=parent)
    assert r.status_code == 200
    assert r.json()["buff"] == "energy_boost"  # تأییدنشده → متوسط


def test_reward_grand_requires_mastery(client, make_user):
    parent, player, cid = _link_family(client, make_user)
    db = SessionLocal()
    grand = models.Reward(title="PS5 تست", tier=models.RewardTier.GRAND, season=1,
                          stock=1, requires_mastery=True)
    db.add(grand)
    db.commit()
    rid = grand.id
    db.close()
    r = client.post("/rewards/redeem", json={"child_id": cid, "reward_id": rid},
                    headers=player)
    assert r.status_code == 403  # بدون تسلط → رد


def test_coupon_redeem_one_per_child(client, make_user):
    parent, player, cid = _link_family(client, make_user)
    db = SessionLocal()
    c = models.Reward(title="کوپن تست", tier=models.RewardTier.COUPON, season=1, stock=2)
    db.add(c)
    db.commit()
    rid = c.id
    db.close()
    r1 = client.post("/rewards/redeem", json={"child_id": cid, "reward_id": rid},
                     headers=player)
    assert r1.status_code == 200 and r1.json()["code"].startswith("RD-")
    r2 = client.post("/rewards/redeem", json={"child_id": cid, "reward_id": rid},
                     headers=player)
    assert r2.status_code == 409  # فقط یک‌بار


def test_parent_cannot_see_foreign_mastery(client, make_user):
    _, _, cid = _link_family(client, make_user)
    intruder = make_user("intruder@test.dev", "secret1", "غریبه", "parent")
    r = client.get(f"/mastery/{cid}", headers=intruder)
    assert r.status_code == 403
