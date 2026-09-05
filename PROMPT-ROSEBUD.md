# 🎮 پرامت‌های آماده برای ساخت «Bazino» در Rosebud.ai

> روش استفاده: اول پرامت پایه را بفرست → هر بار که ساخته را بهتر خواستی، تک‌تک پرامت‌های ادامه را بفرست. در Rosebud پرامت‌های کوتاه پی در پی بهتر از یک پرامت غول‌پیکر جواب می‌دهد.

---

## ✅ پرامت پایه (کپی و ارسال)

```
Build a dark-fantasy 2D action-platformer in the style of Hollow Knight, called "Bazino: Secret of the Island". 

STORY: A small cloaked kid knight with a glowing nail-sword lands on a cursed island with 7 magical regions. Each region is corrupted by a Stone Computer boss. To save the island, the kid must solve ancient rune gates and defeat all 7 bosses.

CORE FEEL (most important):
- Tight responsive platforming: run fast, jump with coyote time and jump buffering, air dash with brief invincibility frames
- A light-saber-style 3-hit melee combo with satisfying hit-stop and camera shake on hits
- Painterly dark atmosphere: glowing crystals, fog, moody parallax backgrounds, silhouette foreground
- Retro chiptune SFX for jump/dash/attack, ambient dark synth music, tense boss music

START with ONE region: "Crystal Number Cavern" (math-themed, glowing blue crystals).

THE KEY MECHANIC — Rune Gates (this is what makes learning invisible):
At certain doors the path is blocked. In front of the door, 4 glowing stone pads appear on the ground, each showing a number/expression (like "12", "-7", "3/4", "16"). A riddle floats above the door (like "2x + 6 = 14 → stand on x" or "EBOB(12,18) = ?"). The player must PHYSICALLY STAND on the correct pad to open the door. Wrong pad: the pads shuffle and the door asks a slightly different riddle. No menus, no quiz UI — it must feel like a magical puzzle mechanic, never like a school test.

ENEMIES: floating "number wisps" (glowing ghosts) that chase slowly and die in 2-3 hits.

MINI BOSS for the start region: "Eski Hesapçı" (an old broken stone calculator golem). It walks slowly. Above its head a riddle appears and 4 pads spawn — stand on the right answer to shatter its shield, then hit it 3 times. 3 phases with harder riddles (powers, square roots, identities). After defeat it drops a glowing "Formula Scroll" that grants a permanent ability (like a stronger dash).

COLLECTIBLES: glowing "Lum" orbs from enemies and hidden spots; Formula Scrolls as collectibles with a small book UI showing which ones you found.

HUD: hearts at top-left, lum counter, small boss HP bar during boss fight.

Make it work on keyboard (arrows/A,D move, Space jump, Shift dash, J attack) and touch buttons for mobile.
```

---

## 🧩 پرامت‌های ادامه (به ترتیب، هرکدام یک بار)

**#2 — اضافه‌کردن منطقهٔ دوم:**
```
Great. Now add a second region: "Copper Transformer Citadel" (physics-themed): warm orange glow, big copper coils, electric arcs. Its rune gates ask physics riddles (density = mass/volume, pressure = force/area, Ohm's law V=IR). Add a "lever scale" puzzle: put weights on a balance to tip a bridge open. Boss: "Trafoo" — a rusted transformer robot; solve riddles like "P = F/A → put 100N over 2m²" to break its shield.
```

**#3 — منطقهٔ سوم (انگلیسی) + تنوع پرسش:**
```
Add a third region: "Foggy Captain's Harbor" (English-language-themed): moonlit docks, lanterns, ships. Its gates show ENGLISH grammar riddles in-world ("Yesterday we ___ to the shore." with pads: went / go / goed / going). No translations shown anywhere — the world itself teaches through context. Boss: "Captain" — a ghost ship captain who speaks only in riddles like "The red boat is ___ than the blue one (faster/fastest/fest/fast)".
```

**#4 — اسکرول‌ها و پیشرفت:**
```
Now expand the Formula Scroll system: hide 2 scrolls behind secret walls in each region. Collecting shows a small glowing page in a "Notebook" (press Tab) with the rule inside the world ("√(ab) = √a·√b" styled as an ancient rune, not a school note). Add a shrine in each region where spending 50 Lum heals and gives a 20-minute "Blessing" buff (faster dash cooldown).
```

**#5 — زمزمهٔ مخفی درس (ارزیابی پنهان — موتور هوشمند):**
```
Important subtle feature, make it INVISIBLE to the player: silently track which riddle topics the player answers correctly. When a topic was missed twice, secretly schedule that riddle again at the next gate as a "different gate". Never show scores, never say "test", never give grades. The world simply "re-asks" forgotten knowledge in new clothes.
```

**#6 — مسابقهٔ هفتگی و فینال:**
```
Add a "Weekly Arena" portal (a glowing banner): a timed gauntlet mixing riddles from all unlocked regions, best of 3 rounds, with a crown-ranking badge (Gold/Silver/Bronze) shown on the main menu. Add a "Season Final" mode unlocked after all bosses: a Boss Rush of all bosses back-to-back with one shared health bar.
```

**#7 — آب و تاب (juice):**
```
Polish pass: dust particles on landing, light trail on dash, screen shake scaled by hit combo, slow-motion flash when breaking a boss shield, glowing edges on the nearest interactive object, and a short slow-mo intro cutscene when each boss appears the first time.
```

---

## 🧊 نسخهٔ ۳بعدی (اگر ۲بعدی هنوز دلت نینداخت — به‌جای پرامت پایه)

```
Build a low-poly stylized 3D action-adventure, "Bazino", like a kid-friendly Legend of Zelda / Hollow Knight mix: third-person camera over the shoulder, one floating crystal island, a small cloaked kid knight with a glowing sword.

Feeling: smooth character controller (walk, run, jump with coyote time, dash with i-frames), 3-hit sword combo with hit-stop, dark moody fog, glowing crystals, painterly low-poly lighting.

Mechanic that shows everything (build it first!): a Rune Gate — a huge stone doorway, 4 glowing rune pads on the floor with numbers ("12", "-7", "16", "3"), riddle floating above ("2x+6=14 → find x"). The player walks ONTO the right pad; pad rings, door opens with dust and light. Wrong: pads shuffle, riddle changes. Then one floating ghost enemy (2 hits) and a stone-calculator golem boss with the same pad-shield mechanic in 3 phases.

Chiptune SFX + dark ambient music. It must feel like a magical adventure, not a math game. Only AFTER this island feels great, we expand.
```

---

## ⚠️ محدودیت‌های Rosebud — بدان چه انتظاری داشته باشی
| کار | می‌کند؟ |
|---|---|
| نمونهٔ قابل‌بازی فوری + دانلود/لینک برای بچه‌ها | ✅ عالی |
| گرافیک و صدا auto-tune بدون دست‌کاری فایل | ✅ نسبتاً خوب |
| بک‌اند واقعی ما (FastAPI، کیف‌پول سالن، QR، نمرهٔ مخفی سمت سرور) | ❌ — آن در اکوسیستم فعلی می‌ماند؛ اگر ساختش برق زد، route API اتصالش را خودم باز می‌کنم |
| دقت طراحی بازی عمیق (احساس پرش، تعادل باس‌ها) | ⚠️ نیاز به تکرارهامت زیاد |

> اگر نمونهٔ Rosebud به نتیجهٔ خوب رسید، بهترین جاده: **نشان‌دهندهٔ جهت محصول** می‌شود و ما محتوی/اقتصاد را پیرامونش جمع می‌کنیم. اگر نشد، همان موتور Godot خودمان با پوست‌های رایگان ادامه می‌یابد. her دو راه باز است.
