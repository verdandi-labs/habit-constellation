import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_me(client: AsyncClient, make_user):
    user = await make_user()
    response = await client.get(
        "/me",
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == user["id"]
    assert data["email"] == user["email"]
    assert data["tooltip_log_seen"] is False


@pytest.mark.asyncio
async def test_patch_me(client: AsyncClient, make_user):
    user = await make_user()
    response = await client.patch(
        "/me",
        json={"tooltip_log_seen": True, "tooltip_comment_seen": True},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    assert response.json()["tooltip_log_seen"] is True
    assert response.json()["tooltip_comment_seen"] is True


@pytest.mark.asyncio
async def test_patch_me_partial(client: AsyncClient, make_user):
    user = await make_user()
    response = await client.patch(
        "/me",
        json={"tooltip_log_seen": True},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 200
    assert response.json()["tooltip_log_seen"] is True
    assert response.json()["tooltip_comment_seen"] is False


@pytest.mark.asyncio
async def test_patch_me_rejects_unknown_fields(client: AsyncClient, make_user):
    user = await make_user()
    response = await client.patch(
        "/me",
        json={"unknown_field": "value"},
        headers={"Authorization": f"Bearer {user['token']}"}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_unauthenticated_me(client: AsyncClient):
    response = await client.get("/me")
    assert response.status_code == 403
