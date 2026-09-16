import pytest
from httpx import AsyncClient
from datetime import date


@pytest.mark.asyncio
async def test_ownership_habits(client: AsyncClient, db_session, make_user, make_habit):
    user1 = await make_user()
    user2 = await make_user()

    habit = await make_habit(user1["id"], name="Private")

    response = await client.get(
        "/habits",
        params={"date": date.today().isoformat()},
        headers={"Authorization": f"Bearer {user2['token']}"}
    )
    assert response.status_code == 200
    assert len(response.json()["habits"]) == 0


@pytest.mark.asyncio
async def test_ownership_logs(client: AsyncClient, db_session, make_user, make_habit, make_log):
    user1 = await make_user()
    user2 = await make_user()

    habit = await make_habit(user1["id"])
    await make_log(user1["id"], habit["id"], log_date=date.today())

    response = await client.get(
        "/logs",
        params={"from": date.today().isoformat(), "to": date.today().isoformat()},
        headers={"Authorization": f"Bearer {user2['token']}"}
    )
    assert response.status_code == 200
    assert len(response.json()["logs"]) == 0


@pytest.mark.asyncio
async def test_ownership_patch_log(client: AsyncClient, db_session, make_user, make_habit, make_log):
    user1 = await make_user()
    user2 = await make_user()

    habit = await make_habit(user1["id"])
    log = await make_log(user1["id"], habit["id"], log_date=date.today())

    response = await client.patch(
        f"/habit_logs/{log['id']}",
        json={"comment": "Stolen"},
        headers={"Authorization": f"Bearer {user2['token']}"}
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_ownership_delete_log(client: AsyncClient, db_session, make_user, make_habit, make_log):
    user1 = await make_user()
    user2 = await make_user()

    habit = await make_habit(user1["id"])
    await make_log(user1["id"], habit["id"], log_date=date.today())

    response = await client.delete(
        f"/habits/{habit['id']}/logs/{date.today().isoformat()}",
        headers={"Authorization": f"Bearer {user2['token']}"}
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_ownership_rename_habit(client: AsyncClient, db_session, make_user, make_habit):
    user1 = await make_user()
    user2 = await make_user()

    habit = await make_habit(user1["id"])

    response = await client.put(
        f"/habits/{habit['id']}",
        json={"name": "Stolen"},
        headers={"Authorization": f"Bearer {user2['token']}"}
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_ownership_delete_habit(client: AsyncClient, db_session, make_user, make_habit):
    user1 = await make_user()
    user2 = await make_user()

    habit = await make_habit(user1["id"])

    response = await client.delete(
        f"/habits/{habit['id']}",
        headers={"Authorization": f"Bearer {user2['token']}"}
    )
    assert response.status_code == 404
