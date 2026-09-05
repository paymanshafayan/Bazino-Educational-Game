"""lint ایستا برای پروژهٔ Godot (جایگزین headless موتور در محیط فعلی):
  ۱) توازن پرانتز/کروشه/آکولاد خارج از رشته/کامنت
  ۲) تورفتگی فقط با تب (قاعدهٔ GDScript پروژه)
  ۳) یکتایی class_name
  ۴) وجود مسیرهای res:// ارجاع‌شده
  ۵) وجود کلیدهای tr("...") در i18n.csv
  ۶) اعتبار JSON داده‌ها
اجرا: python3 tools/godot_lint.py  (از ریشهٔ مخزن؛ خروج غیرصفر = خطا)
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)
    print(" ❌", msg)


def strip_strings(line: str) -> str:
    out, in_s, q, i = [], False, "", 0
    while i < len(line):
        c = line[i]
        if in_s:
            if c == "\\":
                i += 2
                continue
            if c == q:
                in_s = False
        elif c in ("'", '"'):
            in_s, q = True, c
        elif c == "#":
            break
        else:
            out.append(c)
        i += 1
    return "".join(out)


def check_balance(path: Path, src: str) -> None:
    stack: list[tuple[str, int]] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for ln, raw in enumerate(src.splitlines(), 1):
        line = strip_strings(raw)
        for c in line:
            if c in "([{":
                stack.append((c, ln))
            elif c in ")]}":
                if not stack or stack[-1][0] != pairs[c]:
                    err(f"{path.name}:{ln} عدم توازن '{c}'")
                    return
                stack.pop()
    if stack:
        c, ln = stack[-1]
        err(f"{path.name}:{ln} '{c}' بسته نشده")


def check_indent(path: Path, src: str) -> None:
    for ln, raw in enumerate(src.splitlines(), 1):
        if raw.startswith(" ") and raw.strip():
            err(f"{path.name}:{ln} فاصله به‌جای تب در آغاز خط")


def check_class_names(all_src: dict[Path, str]) -> None:
    seen: dict[str, Path] = {}
    for path, src in all_src.items():
        for m in re.finditer(r"^class_name\s+(\w+)", src, re.M):
            name = m.group(1)
            if name in seen:
                err(f"class_name تکراری «{name}» در {path.name} و {seen[name].name}")
            seen[name] = path


def check_res_paths(all_src: dict[Path, str]) -> None:
    for path, src in all_src.items():
        for m in re.finditer(r'res://[^"\')\s]+', src):
            ref = m.group(0)
            if not (GODOT / ref[6:]).exists():
                err(f"{path.name}: مسیر گم‌شدهٔ {ref}")


def check_i18n(all_src: dict[Path, str]) -> None:
    csv = GODOT / "data" / "i18n.csv"
    keys = set()
    if csv.exists():
        lines = csv.read_text(encoding="utf-8").splitlines()[1:]
        keys = {ln.split(",")[0].strip() for ln in lines if ln.strip()}
    for path, src in all_src.items():
        for m in re.finditer(r'tr\(\s*"([a-z_0-9]+)"\s*\)', src):
            k = m.group(1)
            if k not in keys:
                err(f"{path.name}: کلید i18n ناشناختهٔ «{k}»")


def check_jsons() -> None:
    for j in (GODOT / "data").glob("*.json"):
        try:
            json.loads(j.read_text(encoding="utf-8"))
            print(f" ✓ JSON {j.name}")
        except json.JSONDecodeError as e:
            err(f"{j.name}: JSON نامعتبر {e}")


def main() -> int:
    gd_files = sorted(GODOT.rglob("*.gd"))
    print(f"🔎 {len(gd_files)} فایل .gd")
    all_src = {p: p.read_text(encoding="utf-8") for p in gd_files}
    for p, src in all_src.items():
        check_balance(p, src)
        check_indent(p, src)
    check_class_names(all_src)
    check_res_paths(all_src)
    check_i18n(all_src)
    check_jsons()
    if errors:
        print(f"\n⛔ {len(errors)} خطا")
        return 1
    print("\n✅ lint پاک — ساختار معتبر است")
    return 0


if __name__ == "__main__":
    sys.exit(main())
