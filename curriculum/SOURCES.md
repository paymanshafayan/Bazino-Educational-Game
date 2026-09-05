# منابع رسمی استخراج سرفصل‌های KKTC

> این فایل «دفترچهٔ منابع» فاز ۲ است: هر موضوع در `kktc-season1-grades6-8.json` باید با یکی از اسناد زیر راستی‌آزمایی شود.
> ⚠️ قانون صداقت داده: هر جت تخصیص موضوع به **نیمسال Güz** بدون مدرک است، فیلد `semester_estimate=true` باقی می‌ماند.

## اسناد اول (بر اساس `research/02` و `research/07`)
| منبع | URL | کاربرد |
|---|---|---|
| Talim ve Terbiye Dairesi (TTD) | https://ttd.mebnet.net/ | ✅ **تأیید دسترسی (۲۰۲۶-۰۹)** — سایت زنده و قابل خواندن |
| 📋 برنامه‌های رسمی Temel Eğitim (۱–۸) | https://ttd.mebnet.net/temel-egitim/ | ✅ فهرست تأییدشده: ریاضی ۱–۸، Fen ve Teknoloji ۴–۸، انگلیسی، Teknoloji ve Tasarım، **Zeka Oyunları ۶–۸**، Bilim Uygulamaları ۶–۸ |
| 📋 برنامه‌های Lise (Genel Ortaöğretim) | https://ttd.mebnet.net/genel-ortaogretim/ | منابع پایه ۹–۱۲ |
| 📅 **Örnek Yıllık Planlar** (کلید پخش نیمسال!) | https://ttd.mebnet.net/ornek-yillik-planlar/ | ✅ صفحه در دسترس — طرح سالانهٔ نمونه (حاوی ترتیب ترم‌به‌ترم واحدها) |
| 📅 تقویم آکادمیک | https://ttd.mebnet.net/akademik-takvimler/ | مرز رسمی Güz/Bahar |
| چارت توزیع دروس | https://ttd.mebnet.net/ders-dagilim-cizelgeleri-2/ | فهرست دروس هر پایه |
| کتاب‌چهٔ ۲۰۲۶ Kol Ortaokul Yerleştirme | bkz. `research/02-curriculum-middle-school.md` §۳ | فهرست موضوعات **پایه ۸** (اعتبار بالا — مبنای بانک سؤال quiz اول) |

> ⚠️ یافتهٔ فنی ۲۰۲۶-۰۹: PDFهای برنامه در داخل تب‌های WP گنجانده‌اند (پیوند مستقیم در markdown دیده نمی‌شود؛ بعضی با الگوی `?r3d=slug` ریدایرکت می‌شوند). اسکریپت استخراج باید روی دستگاه توسعه این فهرست‌ها را بخواند، لینک‌های سند/تصویر ضمیمه را بگردد و PDF/DOCX دانلود کند — سپس `extract_programs.py` واحدها را عصار می‌گیرد و پخش ترم را با **Yıllık Plan** تطبیق می‌دهد ← آن‌گاه `semester_estimate:false`.

## نحوهٔ راستی‌آزمایی (رویهٔ استخراج)
1. `extract_programs.py` را روی PDF برنامهٔ سالانهٔ هر درس (از TTD) اجرا کنید → متن واحدها.
2. واحدها به موضوع نگاشت می‌شوند و `id` سبک-متعارف (`subject.g6.guz.slug`) می‌گیرند.
3. مرز نیمسال: واحدهای «ترم ۱» در تقویم درس → `semester_estimate:false`.
4. وابستگی‌های زمان اجرای اسکریپت: `pip install requests pdfplumber` (خارج از نیازمندی‌های سرور).

## وضعیت
- JSON فعلی = **draft1**: پایه ۸ از کتاب‌چهٔ رسمی؛ سایر پایه‌ها بر پایهٔ ترتیب متداول ترکیه‌محور. پس از دانلود PDFهای رسمی به‌روز می‌شود.
- در دسترس‌بودن شبکه در محیط اجرا لازم است؛ در غیر این صورت اسکریپت خروجی نیمه‌کاره نمی‌سازد.
