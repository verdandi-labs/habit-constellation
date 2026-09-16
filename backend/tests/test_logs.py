import pytest
from httpx import AsyncClient
from datetime import date, timedelta


@pytest.mark.asyncio
async def test_create_log(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    today = date.today().isoformat()

    response = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["log_date"] == today
    assert data["comment"] is None


@pytest.mark.asyncio
async def test_upsert_idempotent(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    today = date.today().isoformat()

    response1 = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    response2 = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response1.json()["id"] == response2.json()["id"]


@pytest.mark.asyncio
async def test_upsert_preserves_comment(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    today = date.today().isoformat()

    response1 = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    log_id = response1.json()["id"]

    await client.patch(
        f"/habit_logs/{log_id}",
        json={"comment": "Felt great"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    response2 = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response2.json()["comment"] == "Felt great"


@pytest.mark.asyncio
async def test_delete_log(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    today = date.today().isoformat()

    await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    response = await client.delete(
        f"/habits/{habit['id']}/logs/{today}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 204


@pytest.mark.asyncio
async def test_delete_nonexistent_log_is_idempotent(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])

    response = await client.delete(
        f"/habits/{habit['id']}/logs/2025-01-01",
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 204


@pytest.mark.asyncio
async def test_delete_log_archived_habit_404(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    today = date.today().isoformat()

    await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    await client.delete(
        f"/habits/{habit['id']}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    response = await client.delete(
        f"/habits/{habit['id']}/logs/{today}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_future_date_plus_2_rejected(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    future_date = (date.today() + timedelta(days=2)).isoformat()

    response = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": future_date},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_future_date_plus_1_accepted(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    future_date = (date.today() + timedelta(days=1)).isoformat()

    response = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": future_date},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 201


@pytest.mark.asyncio
async def test_past_date_accepted(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    past_date = (date.today() - timedelta(days=5)).isoformat()

    response = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": past_date},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 201


@pytest.mark.asyncio
async def test_patch_comment(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    today = date.today().isoformat()

    response = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    log_id = response.json()["id"]

    response = await client.patch(
        f"/habit_logs/{log_id}",
        json={"comment": "Felt great"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    assert response.json()["comment"] == "Felt great"


@pytest.mark.asyncio
async def test_patch_comment_clear(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    today = date.today().isoformat()

    response = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    log_id = response.json()["id"]

    await client.patch(
        f"/habit_logs/{log_id}",
        json={"comment": "Felt great"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    response = await client.patch(
        f"/habit_logs/{log_id}",
        json={"comment": None},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    assert response.json()["comment"] is None


@pytest.mark.asyncio
async def test_patch_comment_too_long(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])
    today = date.today().isoformat()

    response = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    log_id = response.json()["id"]

    response = await client.patch(
        f"/habit_logs/{log_id}",
        json={"comment": "A" * 501},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_cross_user_log_id(client: AsyncClient, db_session, make_user, make_habit):
    user1 = await make_user()
    user2 = await make_user()
    habit = await make_habit(user1["id"])
    today = date.today().isoformat()

    response = await client.post(
        f"/habits/{habit['id']}/logs",
        json={"log_date": today},
        headers={"Authorization": f"Bearer {user1['token']}"}
    )
    log_id = response.json()["id"]

    response = await client.patch(
        f"/habit_logs/{log_id}",
        json={"comment": "Stolen"},
        headers={"Authorization": f"Bearer {user2['token']}"}
    )
    assert response.status_code == 404
