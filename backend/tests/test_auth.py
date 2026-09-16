import pytest
from unittest.mock import patch, AsyncMock
from httpx import AsyncClient
from app.core.google import InvalidGoogleToken


@pytest.mark.asyncio
async def test_auth_google_valid_token(client: AsyncClient, db_session):
    mock_payload = {
        "sub": "google_user_123",
        "email": "test@example.com",
        "name": "Test User",
    }
    with patch("app.routers.auth.verify_google_token", new_callable=AsyncMock, return_value=mock_payload):
        response = await client.post(
            "/auth/google",
            json={"id_token": "valid_google_token"}
        )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["expires_in"] == 3600
    assert data["user"]["email"] == "test@example.com"
    assert data["user"]["tooltip_log_seen"] is False
    assert data["user"]["tooltip_comment_seen"] is False


@pytest.mark.asyncio
async def test_auth_google_invalid_token(client: AsyncClient):
    with patch("app.routers.auth.verify_google_token", side_effect=InvalidGoogleToken("Invalid")):
        response = await client.post(
            "/auth/google",
            json={"id_token": "invalid_token"}
        )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_auth_google_existing_user(client: AsyncClient, db_session):
    mock_payload = {
        "sub": "google_existing",
        "email": "existing@example.com",
        "name": "Existing User",
    }
    with patch("app.routers.auth.verify_google_token", new_callable=AsyncMock, return_value=mock_payload):
        response1 = await client.post(
            "/auth/google",
            json={"id_token": "token1"}
        )
    assert response1.status_code == 200

    with patch("app.routers.auth.verify_google_token", new_callable=AsyncMock, return_value=mock_payload):
        response2 = await client.post(
            "/auth/google",
            json={"id_token": "token2"}
        )
    assert response2.status_code == 200
    assert response1.json()["user"]["id"] == response2.json()["user"]["id"]


@pytest.mark.asyncio
async def test_refresh_token_rotation(client: AsyncClient, db_session, make_user):
    user = await make_user()
    token_response = await client.post(
        "/auth/google",
        json={"id_token": "token_for_refresh"}
    )

    with patch("app.routers.auth.verify_google_token", new_callable=AsyncMock, return_value={
        "sub": "google_for_refresh",
        "email": "refresh@example.com",
        "name": "Refresh User",
    }):
        token_response = await client.post(
            "/auth/google",
            json={"id_token": "token_for_refresh"}
        )

    refresh_token = token_response.json()["refresh_token"]

    response = await client.post(
        "/auth/refresh",
        json={"refresh_token": refresh_token}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["refresh_token"] != refresh_token

    response2 = await client.post(
        "/auth/refresh",
        json={"refresh_token": refresh_token}
    )
    assert response2.status_code == 401


@pytest.mark.asyncio
async def test_refresh_invalid_token(client: AsyncClient):
    response = await client.post(
        "/auth/refresh",
        json={"refresh_token": "nonexistent_token"}
    )
    assert response.status_code == 401
