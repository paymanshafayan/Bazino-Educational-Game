# 🖥️ Bazino Backend — «قلب گیم‌نت»

بک‌اند بازی اکشن-ادونچر آموزشی Bazino (GDD §۱۱.۲) — **FastAPI + PostgreSQL** (SQLite برای توسعه/تست).

## راه‌اندازی سریع

### الف) محلی (بدون داکر — SQLite خودکار)
```bash
cd server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python -m scripts.seed         # سید: کاربران/جوایز/مراحل/موضوعات
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- 📖 مستندات تعاملی: **http://localhost:8000/docs**
- 🎬 سناریوی کامل: `python -m scripts.e2e_demo`

### ب) کامپوز (PostgreSQL)
```bash
cd server && docker compose up --build
docker compose exec api python -m scripts.seed
```
نمای دیتابیس: `docker compose --profile tools up pgweb` → http://localhost:8081

## نقشهٔ API
| گروه | Endpointها |رول |
|---|---|---|
| `/auth` | register · login · me | عمومی |
| `/links` | create (کد خانواده) · accept · mine | parent / player |
| `/telemetry` | POST events/{child_id} (انبوه) | player/staff |
| `/mastery` | GET {child_id} با چراغ آمادگی امتحان | parent(خانواده)/staff |
| `/adaptive` | GET stage/{child_id}?region=…(پیکربندی Godot) | player/staff |
| `/venue` | issue · qr/{code} · join (حالت سالن) | staff / player |
| `/wallet` | GET · topup_cash (ادمین) · spend_stage | parent/staff |
| `/rewards` | catalog · redeem (کوپن و جوایز غیرنقدی) | player/staff |
| `/reality` | grades (ثبت نمره واقعی) · verify (تأیید حضوری ← بوف قوی‌تر) | parent/staff |
| `/admin` | stats · transactions · redemptions | staff/admin |

## قوانین اعمال‌شده از GDD
- **مرحلهٔ ۱ هر منطقه رایگان** (سید `price_kurus=0`).
- **تراکنش‌ها Idempotent** با `request_id` یکتا — تکرار شبکه، شارژ دوبرابر نمی‌کند.
- **رسید HMAC** (`BZ-XXXX-XXXX`) ضدجعل برای باجهٔ گیم‌نت.
- **جایزهٔ بزرگ فصل فقط با تسلط ≥ ۷۰٪** (مهارت‌محوری، GDD §۸.۳).
- بازیکن نمرهٔ تسلط را **هرگز** نمی‌بیند (فقط `/mastery` برای والد/کارکنان).
- درگاه بانکی = `BankGatewayStub` خاموش (`GATEWAY_PROVIDER=manual`) تا مدارک شرکتی (بلاکر مالک — HANDOFF).

## تست
```bash
pytest -q          # auth, ریاضی موتور تسلط، کیف‌پول، حالت سالن، Reality Bridge، جوایز
```
