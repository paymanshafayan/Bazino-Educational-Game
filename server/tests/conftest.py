"""فیکسچر تست: دیتابیس SQLite ایزوله + اپ FastAPI با JWT نمونه."""
import os
import tempfile

os.environ["DATABASE_URL"] = f"sqlite:///{tempfile.mkdtemp()}/test.db"
os.environ["JWT_SECRET"] = "test-secret"

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import pytest
from fastapi.testclient import TestClient

from app.db import init_db
from app.main import app


@pytest.fixture(scope="session")
def client():
    init_db()
    with TestClient(app) as c:
        yield c


@pytest.fixture(scope="session")
def make_user(client):
    def _mk(email, pwd, name, role, grade=None):
        r = client.post("/auth/register", json={
            "email": email, "password": pwd, "display_name": name,
            "role": role, "grade": grade})
        assert r.status_code == 200, r.text
        return {"Authorization": f"Bearer {r.json()['access_token']}"}
    return _mk
