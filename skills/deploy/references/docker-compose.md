# Docker Compose Reference

## Base `docker-compose.yml` (production-ready)

```yaml
version: "3.9"

services:
  api:
    image: ${IMAGE:-my-service:latest}
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - PORT=3000
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    env_file:
      - .env
    ports:
      - "${API_PORT:-3000}:3000"
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - backend
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-mydb}
      POSTGRES_USER: ${POSTGRES_USER:-user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-user}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --maxmemory 128mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

volumes:
  postgres_data:
  redis_data:

networks:
  backend:
    driver: bridge
```

## Dev Override: `docker-compose.override.yml`

This file is automatically merged by `docker compose up` in development.

```yaml
version: "3.9"

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    image: my-service:dev
    environment:
      - NODE_ENV=development
    volumes:
      - ./src:/app/src:ro    # Hot reload: mount source for development
    command: npm run dev
    ports:
      - "9229:9229"          # Node.js debugger port

  db:
    ports:
      - "5432:5432"          # Expose DB to host for local DB tools

  redis:
    ports:
      - "6379:6379"          # Expose Redis to host for redis-cli
```

## `.env.example`

```bash
# Required — copy to .env and fill in real values
# NEVER commit .env to version control

# Application
IMAGE=my-service:latest
API_PORT=3000
NODE_ENV=production

# Database
POSTGRES_DB=mydb
POSTGRES_USER=myuser
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD

# Redis
REDIS_PASSWORD=CHANGE_ME_REDIS_PASSWORD
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0

# Connection string used by the app
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
```

## Commands

```bash
# Development (with hot reload)
docker compose up

# Production (use explicit override to avoid dev mount)
docker compose -f docker-compose.yml up -d

# View logs
docker compose logs -f api

# Scale the API service
docker compose up -d --scale api=3

# Run database migrations
docker compose exec api npm run migrate

# Stop everything
docker compose down

# Stop and remove volumes (WARNING: deletes data)
docker compose down -v
```

## Multi-service with nginx reverse proxy

Add this to `docker-compose.yml` to proxy API + serve frontend:

```yaml
  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./frontend/dist:/usr/share/nginx/html:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - api
    networks:
      - backend
```

## Key Patterns

- `depends_on: condition: service_healthy` — waits for the DB health check to pass before starting the API (prevents connection-refused errors on startup)
- `env_file: .env` + `${VAR:-default}` — reads from `.env` file with sensible defaults; nothing is hardcoded
- `docker-compose.override.yml` — automatically merged in dev, ignored in production (when using `-f docker-compose.yml` explicitly)
- `resources.limits` — prevents a single container from starving others on the host
