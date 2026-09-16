from datetime import date, datetime, timezone
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.models import User, Habit, HabitLog
from app.schemas.schemas import (
    HabitCreateRequest, HabitRenameRequest, HabitResponse,
    HabitsWithTodayResponse, HabitWithTodayLog, TodayLog
)

router = APIRouter(prefix="/habits", tags=["habits"])


@router.get("", response_model=HabitsWithTodayResponse)
async def list_habits(
    date: date = Query(..., alias="date"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Habit)
        .where(Habit.user_id == user.id, Habit.archived_at.is_(None))
        .order_by(Habit.created_at.asc())
    )
    habits = result.scalars().all()

    today_log_result = await db.execute(
        select(HabitLog)
        .where(
            HabitLog.user_id == user.id,
            HabitLog.log_date == date,
        )
    )
    today_logs = {log.habit_id: log for log in today_log_result.scalars().all()}

    habit_list = []
    for h in habits:
        log = today_logs.get(h.id)
        today_log = TodayLog(id=log.id, log_date=log.log_date, comment=log.comment) if log else None
        habit_list.append(HabitWithTodayLog(id=h.id, name=h.name, today_log=today_log))

    return HabitsWithTodayResponse(habits=habit_list)


@router.post("", response_model=HabitResponse, status_code=status.HTTP_201_CREATED)
async def create_habit(
    req: HabitCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    name = req.name.strip()
    if not name or len(name) > 60:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "validation_error", "message": "Name must be 1-60 characters after trim"}
        )

    habit = Habit(user_id=user.id, name=name)
    db.add(habit)
    await db.commit()
    await db.refresh(habit)
    return HabitResponse.model_validate(habit)


@router.put("/{habit_id}", response_model=HabitResponse)
async def rename_habit(
    habit_id: UUID,
    req: HabitRenameRequest,
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

    name = req.name.strip()
    if not name or len(name) > 60:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "validation_error", "message": "Name must be 1-60 characters after trim"}
        )

    habit.name = name
    await db.commit()
    await db.refresh(habit)
    return HabitResponse.model_validate(habit)


@router.delete("/{habit_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_habit(
    habit_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Habit).where(Habit.id == habit_id, Habit.user_id == user.id)
    )
    habit = result.scalar_one_or_none()
    if habit is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "not_found", "message": "Habit not found"}
        )
    if habit.archived_at is not None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "not_found", "message": "Habit already archived"}
        )

    habit.archived_at = datetime.now(timezone.utc)
    await db.commit()
