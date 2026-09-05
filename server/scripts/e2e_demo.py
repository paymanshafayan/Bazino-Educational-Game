"""سناریوی End-to-End: از ثبت‌نام تا Venue Mode و Reality Bridge (ارائه‌شده در تعهد فاز ۲).

پیش‌نیاز: API در حال اجرا (uvicorn) + سید انجام‌شده.
اجرا:   python -m scripts.e2e_demo           → http://localhost:8000
"""
import uuid

import httpx

BASE = "http://localhost:8000"


def login(email, pwd) -> dict:
    r = httpx.post(f"{BASE}/auth/login", json={"email": email, "password": pwd})
    r.raise_for_status()
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def main():
    # ۱) سلامت
    print("1) health:", httpx.get(f"{BASE}/health").json())

    # ۲) لاگین نقش‌ها
    staff = login("staff@bazino.local", "staff123")
    parent = login("parent@bazino.local", "parent123")
    player = login("oyuncu@bazino.local", "oyuncu123")
    print("2) login: ✓ staff/parent/player")

    # ۳) ارسال تله‌متری مانع ریاضی (بازیکن تند/دقیق و بدون تلاش دوباره)
    events = [{"type": "obstacle_solved", "topic_id": "math.g8.guz.uslu",
               "payload": {"solved": True, "time_ms": 1800, "retries": 0,
                           "tool_correct": True}} for _ in range(4)]
    r = httpx.post(f"{BASE}/telemetry/events/1", json=events, headers=player)
    print("3) telemetry:", r.json())

    # ۴) گزارش تسلط (والد) — باید master شود
    r = httpx.get(f"{BASE}/mastery/1", headers=parent)
    m = r.json()
    print("4) mastery:", m["rows"][0], "| readiness:", m["exam_readiness"])

    # ۵) پیکربندی تطبیقی مرحله (کلاینت Godot)
    r = httpx.get(f"{BASE}/adaptive/stage/1?region=math&season=1&index_no=2", headers=player)
    print("5) adaptive rooms:", [room["type"] for room in r.json()["rooms"]])

    # ۶) شارژ نقدی حضوری کیف‌پول توسط ادمین (Idempotent)
    req = f"demo-{uuid.uuid4()}"
    r = httpx.post(f"{BASE}/wallet/topup_cash",
                   json={"parent_id": 3, "amount_kurus": 50000, "request_id": req,
                         "note": "شارژ حضوری باجه"}, headers=staff)
    print("6) topup:", r.json()["ref_code"], r.json()["amount_kurus"], "قرش")
    r2 = httpx.post(f"{BASE}/wallet/topup_cash",
                    json={"parent_id": 3, "amount_kurus": 50000, "request_id": req},
                    headers=staff)
    assert r.json()["id"] == r2.json()["id"], "Idempotency شکست خورد!"
    print("   idempotent retry → همان تراکنش ✓")

    # ۷) خرید مرحلهٔ ۲ ریاضی توسط والد (قیمت ۱۵۰٫۰۰ لیرا)
    r = httpx.post(f"{BASE}/wallet/spend_stage",
                   json={"child_id": 1, "stage_id": 2,
                         "request_id": f"spend-{uuid.uuid4()}"}, headers=parent)
    print("7) spend stage:", r.json()["amount_kurus"], "قرش")

    # ۸) صدور کد سالن + ورود بازیکن به Venue Mode
    r = httpx.post(f"{BASE}/venue/issue", json={"venue_name": "Bazino GameNet Lefkoşa"},
                   headers=staff)
    code = r.json()["code"]
    r = httpx.post(f"{BASE}/venue/join", json={"code": code}, headers=player)
    print("8) venue join:", r.json()["venue"], "→ venue_mode:", r.json()["venue_mode"])

    # ۹) Reality Bridge: والد نمرهٔ واقعی ۹۲ ثبت می‌کند
    r = httpx.post(f"{BASE}/reality/grades",
                   json={"child_id": 1, "subject": "math", "score": 92}, headers=parent)
    print("9) reality bridge buff:", r.json())

    # ۱۰) قرعة کاتالوگ جوایز + صدور کوپن
    r = httpx.get(f"{BASE}/rewards/catalog")
    coupon = [x for x in r.json() if x["tier"] == "coupon"][0]
    r = httpx.post(f"{BASE}/rewards/redeem",
                   json={"child_id": 1, "reward_id": coupon["id"]}, headers=player)
    print("10) coupon code:", r.json()["code"])
    print("\n🎉 E2E کامل شد.")


if __name__ == "__main__":
    main()
