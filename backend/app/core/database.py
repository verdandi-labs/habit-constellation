from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine, AsyncSession
from sqlalchemy.orm import DeclarativeBase
from app.core.config import get_settings


class Base(DeclarativeBase):
    pass


engine = None
async_session_factory = None


def init_db(url: str | None = None):
    global engine, async_session_factory
    settings = get_settings()
    db_url = url or settings.DATABASE_URL
    engine = create_async_engine(db_url, echo=False)
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_db():
    if async_session_factory is None:
        init_db()
    async with async_session_factory() as session:
        try:
            yield session
        finally:
            await session.close()
