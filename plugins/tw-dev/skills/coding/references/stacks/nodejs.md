# Node.js + TypeScript Scaffold Reference

## Directory Tree

```
my-service/
├── src/
│   ├── app.ts               # Express app (no listen call — exported for testing)
│   ├── index.ts             # Entry point (calls app.listen)
│   ├── routes/
│   │   └── health.ts        # GET /health endpoint
│   ├── middleware/
│   │   ├── auth.ts          # JWT authentication middleware
│   │   └── errorHandler.ts  # Global error handler
│   ├── services/            # Business logic
│   ├── repositories/        # Data access layer
│   └── types/               # Shared TypeScript types
├── tests/
│   ├── unit/
│   └── integration/
├── .env.example
├── .gitignore
├── Dockerfile
├── jest.config.ts
├── package.json
└── tsconfig.json
```

## File Contents

### `package.json`
```json
{
  "name": "my-service",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "ts-node-dev --respawn src/index.ts",
    "build": "tsc --project tsconfig.json",
    "start": "node dist/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src --ext .ts"
  },
  "dependencies": {
    "express": "^4.18.0",
    "jsonwebtoken": "^9.0.0",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/jest": "^29.5.0",
    "@types/jsonwebtoken": "^9.0.0",
    "@types/node": "^20.0.0",
    "@types/supertest": "^6.0.0",
    "jest": "^29.7.0",
    "supertest": "^6.3.0",
    "ts-jest": "^29.1.0",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.3.0"
  }
}
```

### `tsconfig.json`
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### `jest.config.ts`
```typescript
import type { Config } from 'jest'

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageThreshold: {
    global: { branches: 80, functions: 80, lines: 80, statements: 80 }
  }
}
export default config
```

### `src/app.ts`
```typescript
import express from 'express'
import { healthRouter } from './routes/health'
import { errorHandler } from './middleware/errorHandler'

export const app = express()

app.use(express.json())
app.use('/health', healthRouter)
// Add routers here

app.use(errorHandler)
```

### `src/index.ts`
```typescript
import { app } from './app'

const PORT = process.env.PORT ?? 3000

app.listen(PORT, () => {
  console.log(`Service running on port ${PORT}`)
})
```

### `src/routes/health.ts`
```typescript
import { Router } from 'express'

export const healthRouter = Router()

healthRouter.get('/', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})
```

### `src/middleware/errorHandler.ts`
```typescript
import { Request, Response, NextFunction } from 'express'

export class AppError extends Error {
  constructor(
    message: string,
    public readonly statusCode: number = 500,
    public readonly code: string = 'INTERNAL_ERROR'
  ) {
    super(message)
    this.name = 'AppError'
  }
}

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({ error: err.code, message: err.message })
    return
  }
  console.error(err)
  res.status(500).json({ error: 'INTERNAL_ERROR', message: 'An unexpected error occurred' })
}
```

### `Dockerfile`
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS production
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### `.env.example`
```
PORT=3000
NODE_ENV=development
JWT_SECRET=change-me-in-production
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
```

### `.gitignore`
```
node_modules/
dist/
.env
*.log
coverage/
.DS_Store
```

## Getting Started Commands

```bash
npm install
cp .env.example .env
npm run dev      # development with hot reload
npm test         # run tests
npm run build    # compile TypeScript
npm start        # run compiled output
```
