"""تنظیمات محیطی بک‌اند Bazino (FastAPI)."""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./dev.db"
    JWT_SECRET: str = "dev-secret-change-me"
    ACCESS_TOKEN_MIN: int = 60
    REFRESH_TOKEN_DAYS: int = 7
    # ارائه‌دهندهٔ درگاه پرداخت: manual | iktisat | neareast  (D11 — پیش‌فرض نقدی حضوری)
    GATEWAY_PROVIDER: str = "manual"
    VENUE_CODE_TTL_MIN: int = 60 * 12  # اعتبار راز روزانهٔ سالن
    MASTERY_THRESHOLD: float = 70.0

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
