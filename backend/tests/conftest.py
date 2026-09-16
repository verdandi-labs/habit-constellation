import asyncio
import os
import uuid
from datetime import datetime, date, timezone, timedelta
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine, AsyncSession
from sqlalchemy import text

from app.core.database import Base, get_db
from app.core.config import get_settings
from app.core.auth import create_access_token, hash_token
from app.models.models import User, Habit, HabitLog
from app.main import app


from dotenv import load_dotenv
load_dotenv()

TEST_DB_URL = os.environ.get(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@localhost:5432/habit_constellation_test"
)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def setup_db():
    settings = get_settings()
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()
    yield
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
    await engine.dispose()


@pytest_asyncio.fixture(autouse=True)
async def truncate_tables():
    yield
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.execute(text("TRUNCATE TABLE refresh_tokens, habit_logs, habits, users CASCADE"))
    await engine.dispose()


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    engine = create_async_engine(TEST_DB_URL, echo=False)
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session_factory() as session:
        yield session
    await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


async def _make_user(db: AsyncSession, **kwargs) -> dict:
    user = User(
        id=kwargs.get("id", uuid.uuid4()),
        email=kwargs.get("email", f"test_{uuid.uuid4().hex[:8]}@example.com"),
        name=kwargs.get("name", "Test User"),
        google_sub=kwargs.get("google_sub", f"google_{uuid.uuid4().hex[:8]}"),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(str(user.id))
    return {"id": str(user.id), "email": user.email, "name": user.name, "token": token}


async def _make_habit(db: AsyncSession, user_id: str, **kwargs) -> dict:
    habit = Habit(
        id=kwargs.get("id", uuid.uuid4()),
        user_id=user_id,
        name=kwargs.get("name", "Test Habit"),
    )
    db.add(habit)
    await db.commit()
    await db.refresh(habit)
    return {"id": str(habit.id), "name": habit.name, "user_id": user_id}


async def _make_log(db: AsyncSession, user_id: str, habit_id: str, **kwargs) -> dict:
    log = HabitLog(
        id=kwargs.get("id", uuid.uuid4()),
        habit_id=habit_id,
        user_id=user_id,
        log_date=kwargs.get("log_date", date.today()),
        comment=kwargs.get("comment", None),
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return {"id": str(log.id), "habit_id": habit_id, "log_date": str(log.log_date), "comment": log.comment}


@pytest_asyncio.fixture
async def make_user(db_session: AsyncSession):
    async def factory(**kwargs):
        return await _make_user(db_session, **kwargs)
    return factory


@pytest_asyncio.fixture
async def make_habit(db_session: AsyncSession):
    async def factory(user_id: str, **kwargs):
        return await _make_habit(db_session, user_id, **kwargs)
    return factory


@pytest_asyncio.fixture
async def make_log(db_session: AsyncSession):
    async def factory(user_id: str, habit_id: str, **kwargs):
        return await _make_log(db_session, user_id, habit_id, **kwargs)
    return factory
