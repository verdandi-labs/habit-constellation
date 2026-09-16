from pydantic import BaseModel, Field
from datetime import date, datetime
from uuid import UUID


class GoogleAuthRequest(BaseModel):
    id_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int
    user: "UserResponse"


class RefreshRequest(BaseModel):
    refresh_token: str


class RefreshResponse(BaseModel):
    access_token: str
    refresh_token: str
    expires_in: int


class UserResponse(BaseModel):
    id: UUID
    email: str
    name: str
    tooltip_log_seen: bool
    tooltip_comment_seen: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserPatchRequest(BaseModel):
    tooltip_log_seen: bool | None = None
    tooltip_comment_seen: bool | None = None


class HabitCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=60)


class HabitRenameRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=60)


class HabitResponse(BaseModel):
    id: UUID
    name: str
    created_at: datetime

    model_config = {"from_attributes": True}


class HabitWithTodayLog(BaseModel):
    id: UUID
    name: str
    today_log: "TodayLog | None"

    model_config = {"from_attributes": True}


class TodayLog(BaseModel):
    id: UUID
    log_date: date
    comment: str | None

    model_config = {"from_attributes": True}


class HabitsWithTodayResponse(BaseModel):
    habits: list[HabitWithTodayLog]


class LogCreateRequest(BaseModel):
    log_date: date


class LogResponse(BaseModel):
    id: UUID
    habit_id: UUID
    log_date: date
    comment: str | None

    model_config = {"from_attributes": True}


class LogPatchRequest(BaseModel):
    comment: str | None = None


class LogRegistryItem(BaseModel):
    id: UUID
    name: str
    archived: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class LogEntry(BaseModel):
    id: UUID
    habit_id: UUID
    habit_name: str
    habit_archived: bool
    log_date: date
    comment: str | None

    model_config = {"from_attributes": True}


class LogsResponse(BaseModel):
    habits: list[LogRegistryItem]
    logs: list[LogEntry]
