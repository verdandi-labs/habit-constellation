from datetime import date, datetime, timezone, timedelta
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.models import User, Habit, HabitLog
from app.schemas.schemas import (
    LogCreateRequest, LogResponse, LogPatchRequest,
    LogsResponse, LogRegistryItem, LogEntry
)

router = APIRouter(tags=["logs"])


@router.post("/habits/{habit_id}/logs", response_model=LogResponse, status_code=status.HTTP_201_CREATED)
async def create_log(
    habit_id: UUID,
    req: LogCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Habit).where(Habit.id == habit_id, Habit.user_id == user.id)
    )
    habit = result.scalar_one_or_none()
    if habit is None or habit.archived_at is not None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "not_found", "message": "Habit not found"}
        )

    today_utc = datetime.now(timezone.utc).date()
    max_allowed = today_utc + timedelta(days=1)
    if req.log_date > max_allowed:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "invalid_date_range", "message": "log_date cannot exceed server UTC date + 1 day"}
        )

    existing = await db.execute(
        select(HabitLog).where(
            HabitLog.habit_id == habit_id,
            HabitLog.log_date == req.log_date,
        )
    )
    existing_log = existing.scalar_one_or_none()

    if existing_log:
        return LogResponse(
            id=existing_log.id,
            habit_id=existing_log.habit_id,
            log_date=existing_log.log_date,
            comment=existing_log.comment,
        )

    log = HabitLog(
        habit_id=habit_id,
        user_id=user.id,
        log_date=req.log_date,
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return LogResponse.model_validate(log)


@router.delete("/habits/{habit_id}/logs/{log_date}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_log(
    habit_id: UUID,
    log_date: date,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Habit).where(Habit.id == habit_id, Habit.user_id == user.id)
    )
    habit = result.scalar_one_or_none()
    if habit is None or habit.archived_at is not None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "not_found", "message": "Habit not found"}
        )

    result = await db.execute(
        select(HabitLog).where(
            HabitLog.habit_id == habit_id,
            HabitLog.log_date == log_date,
            HabitLog.user_id == user.id,
        )
    )
    log = result.scalar_one_or_none()
    if log:
        await db.delete(log)
        await db.commit()


@router.patch("/habit_logs/{log_id}", response_model=LogResponse)
async def patch_log(
    log_id: UUID,
    req: LogPatchRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HabitLog).where(HabitLog.id == log_id, HabitLog.user_id == user.id)
    )
    log = result.scalar_one_or_none()
    if log is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "not_found", "message": "Log not found"}
        )

    log.comment = req.comment
    await db.commit()
    await db.refresh(log)
    return LogResponse.model_validate(log)


@router.get("/logs", response_model=LogsResponse)
async def list_logs(
    from_date: date = Query(..., alias="from"),
    to_date: date = Query(..., alias="to"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if from_date > to_date:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "invalid_date_range", "message": "from must be <= to"}
        )
    if (to_date - from_date).days > 366:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "invalid_date_range", "message": "Date range cannot exceed 366 days"}
        )

    habits_result = await db.execute(
        select(Habit)
        .where(Habit.user_id == user.id, Habit.created_at <= datetime.combine(to_date, datetime.max.time(), tzinfo=timezone.utc))
        .order_by(Habit.created_at.asc())
    )
    habits = habits_result.scalars().all()

    registry = [
        LogRegistryItem(
            id=h.id,
            name=h.name,
            archived=h.archived_at is not None,
            created_at=h.created_at,
        )
        for h in habits
    ]

    logs_result = await db.execute(
        select(HabitLog)
        .where(
            HabitLog.user_id == user.id,
            HabitLog.log_date >= from_date,
            HabitLog.log_date <= to_date,
        )
    )
    logs = logs_result.scalars().all()

    habit_map = {h.id: h for h in habits}
    log_entries = []
    for log in logs:
        h = habit_map.get(log.habit_id)
        if h:
            log_entries.append(LogEntry(
                id=log.id,
                habit_id=log.habit_id,
                habit_name=h.name,
                habit_archived=h.archived_at is not None,
                log_date=log.log_date,
                comment=log.comment,
            ))

    return LogsResponse(habits=registry, logs=log_entries)
