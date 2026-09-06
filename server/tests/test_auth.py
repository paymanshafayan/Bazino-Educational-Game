def test_register_and_me(client, make_user):
    h = make_user("p1@test.dev", "secret1", "والد تست", "parent")
    r = client.get("/auth/me", headers=h)
    assert r.status_code == 200
    assert r.json()["role"] == "parent"


def test_register_player_creates_child(client, make_user):
    h = make_user("oyuncu1@test.dev", "secret1", "Oyuncu", "player", grade=8)
    me = client.get("/auth/me", headers=h).json()
    assert me["role"] == "player"


def test_wrong_role_rejected(client):
    r = client.post("/auth/register", json={
        "email": "x@test.dev", "password": "secret1",
        "display_name": "x", "role": "superuser"})
    assert r.status_code == 400


def test_duplicate_email_conflict(client, make_user):
    make_user("dup@test.dev", "secret1", "a", "parent")
    r = client.post("/auth/register", json={
        "email": "dup@test.dev", "password": "secret1",
        "display_name": "b", "role": "parent"})
    assert r.status_code == 409


def test_me_player_profile(client, make_user):
    import uuid
    tag = uuid.uuid4().hex[:6]
    h = make_user(f"mepl-{tag}@test.dev", "secret1", "Oyuncu", "player", grade=7)
    r = client.get("/auth/me/player", headers=h)
    assert r.status_code == 200
    assert r.json()["grade"] == 7 and r.json()["child_id"] > 0
