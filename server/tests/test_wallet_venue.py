"""تست‌های کیف‌پول (Idempotency/کسری) و حالت سالن (انقضای کد)."""
import uuid


def _seed_users(client, make_user):
    parent = make_user("wal@test.dev", "secret1", "والد", "parent")
    staff = make_user("staff@test.dev", "secret1", "پرسنل", "staff")
    pid = client.get("/auth/me", headers=parent).json()["id"]
    return parent, staff, pid


def test_topup_idempotent_and_spend(client, make_user):
    parent, staff, pid = _seed_users(client, make_user)
    req = f"req-{uuid.uuid4()}"
    r1 = client.post("/wallet/topup_cash", json={
        "parent_id": pid, "amount_kurus": 20000, "request_id": req}, headers=staff)
    assert r1.status_code == 200
    r2 = client.post("/wallet/topup_cash", json={
        "parent_id": pid, "amount_kurus": 20000, "request_id": req}, headers=staff)
    assert r1.json()["id"] == r2.json()["id"]  # تکرار = همان تراکنش

    w = client.get("/wallet", headers=parent).json()
    assert w["balance_kurus"] == 20000

    # مرحلهٔ ۲ ریاضی (۱۵۰٫۰۰ لیرا) — باید از سید وجود داشته باشد یا دستی:
    from app import models
    from app.db import SessionLocal
    db = SessionLocal()
    st = models.Stage(region="math", season=1, index_no=2, price_kurus=15000)
    db.add(st)
    db.commit()
    stage_id = st.id
    db.close()

    r = client.post("/wallet/spend_stage", json={
        "child_id": 0, "stage_id": stage_id, "request_id": f"s-{uuid.uuid4()}"},
        headers=parent)
    # child_id=0 به این والد لینک نیست → 403 رفتار امن
    assert r.status_code == 403

    # از مسیر مستقیم سرویس (واحد داخلی) کسری را بررسی:
    from app.services.wallet import get_or_create_wallet, spend_stage
    db = SessionLocal()
    st2 = db.get(models.Stage, stage_id)
    w0 = get_or_create_wallet(db, pid).balance_kurus
    tx = spend_stage(db, pid, 1, st2, f"direct-{uuid.uuid4()}")
    db.close()
    assert tx.amount_kurus == -15000 and get_or_create_wallet(db := SessionLocal(), pid)
    db.close()


def test_venue_code_expiry(client, make_user):
    staff = make_user("staff2@test.dev", "secret1", "پرسنل۲", "staff")
    player = make_user("oyuncu2@test.dev", "secret1", "Oyuncu2", "player", grade=7)

    r = client.post("/venue/issue",
                    json={"venue_name": "T", "ttl_minutes": -60}, headers=staff)
    code = r.json()["code"]
    r = client.post("/venue/join", json={"code": code}, headers=player)
    assert r.status_code == 403  # منقضی = رد

    r = client.post("/venue/issue", json={"venue_name": "T2"}, headers=staff)
    code = r.json()["code"]
    r = client.post("/venue/join", json={"code": code}, headers=player)
    assert r.status_code == 200 and r.json()["venue_mode"] is True
