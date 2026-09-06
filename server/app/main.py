"""Bazino Backend — ورود اصلی FastAPI (GDD §۱۱.۲).

راه‌اندازی:
  محلی:   uvicorn app.main:app --reload      (SQLite خودکار)
  کامپوز: docker compose up --build          (PostgreSQL)
مستندات تعاملی: http://localhost:8000/docs
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .db import init_db
from .routers import (admin, adaptive, auth, links, mastery, reality,
                      rewards, telemetry, tournament, venue, wallet)


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()  # v1: create_all؛ مهاجرت Alembic در نسخهٔ بعد (اسکلت در alembic/)
    yield


app = FastAPI(title="Bazino Backend", version="0.1.0", lifespan=lifespan,
              description="بک‌اند بازی اکشن-ادونچر آموزشی Bazino — گیم‌نت قبرس شمالی")

app.add_middleware(
    CORSMiddleware, allow_origins=["*"],   # v1: باز؛ در استقرار: دامنه‌ها محدود شود
    allow_methods=["*"], allow_headers=["*"])

for r in (auth, links, telemetry, mastery, adaptive, venue, wallet,
          rewards, reality, tournament, admin):
    app.include_router(r.router)


@app.get("/health")
def health():
    return {"status": "ok", "service": "bazino-backend", "season": 1}
