from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.auth import create_access_token, create_refresh_token, hash_token
from app.core.google import verify_google_token, InvalidGoogleToken
from app.core.config import get_settings
from app.models.models import User, RefreshToken
from app.schemas.schemas import (
    GoogleAuthRequest, TokenResponse, RefreshRequest, RefreshResponse, UserResponse
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/google", response_model=TokenResponse)
async def auth_google(req: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    settings = get_settings()
    try:
        payload = await verify_google_token(req.id_token, settings.GOOGLE_CLIENT_ID)
    except InvalidGoogleToken:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_google_token", "message": "Google token verification failed"}
        )

    google_sub = payload["sub"]
    email = payload.get("email", "")
    name = payload.get("name", "")

    result = await db.execute(select(User).where(User.google_sub == google_sub))
    user = result.scalar_one_or_none()

    if user is None:
        result = await db.execute(select(User).where(User.email == email))
        existing = result.scalar_one_or_none()
        if existing is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={"code": "account_exists", "message": "An account with this email already exists"}
            )
        user = User(
            email=email,
            name=name,
            google_sub=google_sub,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    access_token = create_access_token(str(user.id))
    raw_refresh, hashed_refresh = create_refresh_token()

    refresh_row = RefreshToken(
        user_id=user.id,
        token_hash=hashed_refresh,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_EXPIRE_DAYS),
    )
    db.add(refresh_row)
    await db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh,
        expires_in=settings.JWT_ACCESS_EXPIRE_MINUTES * 60,
        user=UserResponse.model_validate(user),
    )


@router.post("/refresh", response_model=RefreshResponse)
async def refresh_token(req: RefreshRequest, db: AsyncSession = Depends(get_db)):
    settings = get_settings()
    hashed = hash_token(req.refresh_token)

    result = await db.execute(
        select(RefreshToken).where(RefreshToken.token_hash == hashed)
    )
    token_row = result.scalar_one_or_none()

    if token_row is None or token_row.revoked_at is not None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_refresh_token", "message": "Invalid refresh token"}
        )

    if token_row.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_refresh_token", "message": "Refresh token expired"}
        )

    token_row.revoked_at = datetime.now(timezone.utc)

    access_token = create_access_token(str(token_row.user_id))
    raw_refresh, hashed_refresh = create_refresh_token()

    new_refresh_row = RefreshToken(
        user_id=token_row.user_id,
        token_hash=hashed_refresh,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_EXPIRE_DAYS),
    )
    db.add(new_refresh_row)
    await db.commit()

    return RefreshResponse(
        access_token=access_token,
        refresh_token=raw_refresh,
        expires_in=settings.JWT_ACCESS_EXPIRE_MINUTES * 60,
    )
