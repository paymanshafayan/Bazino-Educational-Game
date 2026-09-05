"""استخراج موضوعات از PDF رسمی Öğretim Programı (TTD).

اجرا:
    python extract_programs.py --pdf program8_fen.pdf --subject physics --grade 8
خروجی: خطوط واحد/موضوع استخراج‌شده روی stdout → به JSON در kktc-season1-grades6-8.json اضافه شود
(بررسی انسانی + نقل به دورِ بازبینی kitapچه آزمون).

وابستگی زمان اجرا: pip install requests pdfplumber
"""
import argparse
import sys

ASCII_HINT = " Unicode حفظ می‌شود؛ ترتیب واحدها = ترتیب نیمسال."


def extract_pdf(pdf_path: str) -> list[str]:
    try:
        import pdfplumber  # noqa: WPS433
    except ImportError:
        sys.exit("pdfplumber نصب نیست: pip install pdfplumber")
    lines: list[str] = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text() or ""
            for line in text.splitlines():
                s = line.strip()
                if s:
                    lines.append(s)
    return lines


def guess_units(lines: list[str]) -> list[str]:
    """خطوطی که شبیه عنوان واحد/موضوع‌اند (Ünite … یا سرخط بزرگ‌ترکی)."""
    out = []
    for ln in lines:
        up = ln.upper()
        if ("ÜNİTE" in up) or ("KONULAR" in up) or ("KAZANIM" in up):
            out.append(ln)
    return out or lines[:50]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", required=True, help="مسیر PDF دانلودشده از ttd.mebnet.net")
    ap.add_argument("--subject", required=True)
    ap.add_argument("--grade", type=int, required=True)
    args = ap.parse_args()
    lines = extract_pdf(args.pdf)
    units = guess_units(lines)
    print(f"# {args.subject} — پایه {args.grade} — {len(units)} مورد نامزد:")
    for u in units:
        print(" -", u)


if __name__ == "__main__":
    main()
