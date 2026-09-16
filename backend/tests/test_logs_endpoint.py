import pytest
from httpx import AsyncClient
from datetime import date, timedelta


@pytest.mark.asyncio
async def test_get_logs_registry_order(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    await make_habit(user["id"], name="First")
    await make_habit(user["id"], name="Second")

    from_date = date.today().isoformat()
    to_date = date.today().isoformat()

    response = await client.get(
        "/logs",
        params={"from": from_date, "to": to_date},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    habits = response.json()["habits"]
    assert len(habits) == 2
    assert habits[0]["name"] == "First"
    assert habits[1]["name"] == "Second"


@pytest.mark.asyncio
async def test_get_logs_includes_archived(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    await make_habit(user["id"], name="Active")
    habit2 = await make_habit(user["id"], name="Archived")

    await client.delete(
        f"/habits/{habit2['id']}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    from_date = date.today().isoformat()
    to_date = date.today().isoformat()

    response = await client.get(
        "/logs",
        params={"from": from_date, "to": to_date},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    habits = response.json()["habits"]
    assert len(habits) == 2
    archived = next(h for h in habits if h["name"] == "Archived")
    assert archived["archived"] is True


@pytest.mark.asyncio
async def test_get_logs_lane_stability(client: AsyncClient, db_session, make_user, make_habit):
    user = await make_user()
    h1 = await make_habit(user["id"], name="First")
    h2 = await make_habit(user["id"], name="Second")

    from_date = date.today().isoformat()
    to_date = date.today().isoformat()

    response1 = await client.get(
        "/logs",
        params={"from": from_date, "to": to_date},
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    await client.delete(
        f"/habits/{h1['id']}",
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    response2 = await client.get(
        "/logs",
        params={"from": from_date, "to": to_date},
        headers={"Authorization": f"Bearer {user['token']}"}
    )

    names1 = [h["name"] for h in response1.json()["habits"]]
    names2 = [h["name"] for h in response2.json()["habits"]]
    assert names1 == names2


@pytest.mark.asyncio
async def test_get_logs_from_gt_to_rejected(client: AsyncClient, db_session, make_user):
    user = await make_user()
    response = await client.get(
        "/logs",
        params={"from": "2026-12-01", "to": "2026-11-01"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_get_logs_span_too_long_rejected(client: AsyncClient, db_session, make_user):
    user = await make_user()
    response = await client.get(
        "/logs",
        params={"from": "2026-01-01", "to": "2027-01-03"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_get_logs_only_in_range(client: AsyncClient, db_session, make_user, make_habit, make_log):
    user = await make_user()
    habit = await make_habit(user["id"])

    today = date.today()
    await make_log(user["id"], habit["id"], log_date=today)
    await make_log(user["id"], habit["id"], log_date=today - timedelta(days=5))

    from_date = (today - timedelta(days=1)).isoformat()
    to_date = today.isoformat()

    response = await client.get(
        "/logs",
        params={"from": from_date, "to": to_date},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    logs = response.json()["logs"]
    assert len(logs) == 1
