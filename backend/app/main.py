from fastapi import FastAPI
from app.core.database import init_db
from app.routers import auth, habits, logs, users


def create_app() -> FastAPI:
    init_db()
    app = FastAPI(title="Habit Constellation API", version="0.1.0")

    app.include_router(auth.router)
    app.include_router(users.router)
    app.include_router(habits.router)
    app.include_router(logs.router)

    @app.get("/health")
    async def health():
        return {"status": "ok"}

    return app


app = create_app()
