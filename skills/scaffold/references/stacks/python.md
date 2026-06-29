# Python + FastAPI Scaffold Reference

## Directory Tree

```
my-service/
├── src/
│   ├── __init__.py
│   ├── main.py              # FastAPI app + startup
│   ├── config.py            # Settings from environment
│   ├── routes/
│   │   └── health.py        # GET /health endpoint
│   ├── services/            # Business logic
│   ├── repositories/        # Data access layer
│   └── models/              # Pydantic models / DB models
├── tests/
│   ├── __init__.py
│   ├── conftest.py          # pytest fixtures
│   ├── unit/
│   └── integration/
├── .env.example
├── .gitignore
├── Dockerfile
├── pyproject.toml
└── ruff.toml
```

## File Contents

### `pyproject.toml`
```toml
[tool.poetry]
name = "my-service"
version = "0.1.0"
description = ""
authors = ["Your Name <you@example.com>"]
python = "^3.12"

[tool.poetry.dependencies]
python = "^3.12"
fastapi = "^0.110.0"
uvicorn = {extras = ["standard"], version = "^0.27.0"}
pydantic = "^2.6.0"
pydantic-settings = "^2.2.0"

[tool.poetry.dev-dependencies]
pytest = "^8.0.0"
pytest-asyncio = "^0.23.0"
pytest-cov = "^4.1.0"
httpx = "^0.27.0"

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

### `src/config.py`
```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "my-service"
    environment: str = "development"
    port: int = 8000
    database_url: str = "postgresql+asyncpg://user:password@localhost/mydb"

    class Config:
        env_file = ".env"


settings = Settings()
```

### `src/main.py`
```python
from fastapi import FastAPI
from src.config import settings
from src.routes.health import router as health_router

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    docs_url="/docs" if settings.environment != "production" else None,
)

app.include_router(health_router)
# Add routers here


@app.on_event("startup")
async def startup():
    pass  # Initialize DB connection pool, etc.


@app.on_event("shutdown")
async def shutdown():
    pass  # Clean up resources
```

### `src/routes/health.py`
```python
from datetime import datetime, timezone
from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}
```

### `tests/conftest.py`
```python
import pytest
from httpx import AsyncClient, ASGITransport
from src.main import app


@pytest.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
```

### `Dockerfile`
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install poetry
COPY pyproject.toml poetry.lock* ./
RUN poetry config virtualenvs.create false \
    && poetry install --no-dev --no-interaction

FROM python:3.12-slim AS production
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn
COPY src/ ./src/
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### `.env.example`
```
ENVIRONMENT=development
PORT=8000
DATABASE_URL=postgresql+asyncpg://user:password@localhost/mydb
SECRET_KEY=change-me-in-production
```

### `.gitignore`
```
__pycache__/
*.py[cod]
.venv/
.env
*.egg-info/
dist/
.coverage
htmlcov/
.pytest_cache/
```

### `ruff.toml`
```toml
[lint]
select = ["E", "F", "I", "N", "W", "UP"]
ignore = ["E501"]

[format]
quote-style = "double"
indent-style = "space"
```

## Getting Started Commands

```bash
poetry install
cp .env.example .env
poetry run uvicorn src.main:app --reload   # development with hot reload
poetry run pytest                           # run tests
poetry run pytest --cov                    # with coverage report
```
