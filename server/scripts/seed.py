"""سید دادهٔ نمونه: سالن، والد، بازیکن(فرزند)، جوایز فصل ۱، مراحل و موضوعات از curriculum.

اجرا:  python -m scripts.seed
"""
import json
import pathlib
import sys

from app import models, security
from app.db import SessionLocal, init_db

CURRIC = pathlib.Path(__file__).resolve().parents[2] / "curriculum" \
    / "kktc-season1-grades6-8.json"


def seed():
    init_db()
    db = SessionLocal()
    try:
        # ── موضوعات درسی ──
        if CURRIC.exists():
            data = json.loads(CURRIC.read_text(encoding="utf-8"))
            for t in data["topics"]:
                if not db.get(models.Topic, t["id"]):
                    db.add(models.Topic(**t))
            print(f"✓ topics از curriculum: {len(data['topics'])}")

        # ── کاربران نمونه ──
        def ensure_user(email, pwd, name, role):
            u = db.query(models.User).filter_by(email=email).first()
            if not u:
                u = models.User(email=email, hashed_password=security.hash_password(pwd),
                                display_name=name, role=role)
                db.add(u)
                db.flush()
            return u

        admin = ensure_user("admin@bazino.local", "admin123", "مدیر گیم‌نت", models.Role.ADMIN)
        staff = ensure_user("staff@bazino.local", "staff123", "پرسنل باجه", models.Role.STAFF)
        parent = ensure_user("parent@bazino.local", "parent123", "والد نمونه", models.Role.PARENT)
        player = ensure_user("oyuncu@bazino.local", "oyuncu123", "Yıldız Oyuncu", models.Role.PLAYER)

        if not db.query(models.Wallet).filter_by(parent_id=parent.id).first():
            db.add(models.Wallet(parent_id=parent.id, balance_kurus=0))
        child = db.query(models.Child).filter_by(player_id=player.id).first()
        if not child:
            child = models.Child(player_id=player.id, grade=8, alias="Yıldız")
            db.add(child)
            db.flush()
        if not db.query(models.FamilyLink).filter_by(child_id=child.id).first():
            db.add(models.FamilyLink(parent_id=parent.id, child_id=child.id,
                                     code="SEED01", active=True))

        # ── مراحل: مرحلهٔ ۱ رایگان ──
        for region in ["math", "physics", "chemistry", "biology", "english", "ict", "logic"]:
            for i in range(1, 4):
                if not db.query(models.Stage).filter_by(region=region, season=1,
                                                        index_no=i).first():
                    db.add(models.Stage(region=region, season=1, index_no=i,
                                        weekly=False, config={},
                                        price_kurus=0 if i == 1 else 15000))

        # ── کاتالوگ جوایز غیرنقدی فصل ۱ ──
        rewards = [
            ("🎟️ کوپن ٪۱۰ تخفیف گیم‌نت", models.RewardTier.COUPON, 50, False),
            ("🕐 یک ساعت رایگان گیم‌نت", models.RewardTier.COUPON, 30, False),
            ("🎧 هدست گیمینگ", models.RewardTier.MID, 3, True),
            ("🚲 دوچرخه قهرمان فصل ۱", models.RewardTier.GRAND, 1, True),
            ("🎮 PlayStation 5 — جایزهٔ فینال", models.RewardTier.GRAND, 1, True),
        ]
        for title, tier, stock, needs_m in rewards:
            if not db.query(models.Reward).filter_by(title=title).first():
                db.add(models.Reward(title=title, tier=tier, season=1,
                                     stock=stock, requires_mastery=needs_m))

        db.commit()
        print("✓ seed کامل شد — admin/staff/parent/oyuncu @bazino.local")
        print(f"   child_id={child.id}  parent_id={parent.id}  staff_id={staff.id} admin_id={admin.id}")
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(seed())
