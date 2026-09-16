import pytest
from httpx import AsyncClient
from datetime import date


@pytest.mark.asyncio
async def test_create_habit(client: AsyncClient, db_session, make_user):
    user = await make_user()
    response = await client.post(
        "/habits",
        json={"name": "Meditate"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Meditate"
    assert "id" in data


@pytest.mark.asyncio
async def test_create_habit_empty_name(client: AsyncClient, db_session, make_user):
    user = await make_user()
    response = await client.post(
        "/habits",
        json={"name": ""},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_create_habit_whitespace_only(client: AsyncClient, db_session, make_user):
    user = await make_user()
    response = await client.post(
        "/habits",
        json={"name": "   "},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_create_habit_too_long(client: AsyncClient, db_session, make_user):
    user = await make_user()
    response = await client.post(
        "/habits",
        json={"name": "A" * 61},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_rename_habit(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"], name="Old Name")

    response = await client.put(
        f"/habits/{habit['id']}",
        json={"name": "New Name"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    assert response.json()["name"] == "New Name"


@pytest.mark.asyncio
async def test_rename_habit_propagates_to_logs(client: AsyncClient, db_session, make_user, make_habit, make_log):
    user = await make_user()
    habit = await make_habit(user["id"], name="Read")
    await make_log(user["id"], habit["id"], log_date=date.today())

    await client.put(
        f"/habits/{habit['id']}",
        json={"name": "Reading"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    today_str = date.today().isoformat()
    response = await client.get(
        f"/logs?from={today_str}&to={today_str}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    logs = response.json()["logs"]
    assert len(logs) == 1
    assert logs[0]["habit_name"] == "Reading"


@pytest.mark.asyncio
async def test_delete_habit(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])

    response = await client.delete(
        f"/habits/{habit['id']}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 204

    response = await client.get(
        "/habits",
        params={"date": date.today().isoformat()},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    assert len(response.json()["habits"]) == 0


@pytest.mark.asyncio
async def test_delete_habit_archived_returns_404(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    habit = await make_habit(user["id"])

    await client.delete(
        f"/habits/{habit['id']}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    response = await client.delete(
        f"/habits/{habit['id']}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_list_habits(client: AsyncClient, db_session, make_user, make_habit, make_log):
    user = await make_user()
    await make_habit(user["id"], name="Habit 1")
    await make_habit(user["id"], name="Habit 2")

    response = await client.get(
        "/habits",
        params={"date": date.today().isoformat()},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    habits = response.json()["habits"]
    assert len(habits) == 2
    assert habits[0]["name"] == "Habit 1"
    assert habits[1]["name"] == "Habit 2"


@pytest.mark.asyncio
async def test_cross_user_habit_id(client: AsyncClient, db_session, make_user, make_habit):
    user1 = await make_user()
    user2 = await make_user()
    habit = await make_habit(user1["id"])

    response = await client.put(
        f"/habits/{habit['id']}",
        json={"name": "Stolen"},
        headers={"Authorization": f"Bearer {user2['token']}"}
    )
    assert response.status_code == 404
