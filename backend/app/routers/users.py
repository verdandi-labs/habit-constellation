from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.models import User
from app.schemas.schemas import UserResponse, UserPatchRequest

router = APIRouter(tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_me(user: User = Depends(get_current_user)):
    return UserResponse.model_validate(user)


@router.patch("/me", response_model=UserResponse)
async def patch_me(
    req: UserPatchRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if req.tooltip_log_seen is not None:
        user.tooltip_log_seen = req.tooltip_log_seen
    if req.tooltip_comment_seen is not None:
        user.tooltip_comment_seen = req.tooltip_comment_seen
    await db.commit()
    await db.refresh(user)
    return UserResponse.model_validate(user)
