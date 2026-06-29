# Go + Gin Scaffold Reference

## Directory Tree

```
my-service/
├── cmd/
│   └── server/
│       └── main.go          # Entry point
├── internal/
│   ├── handler/             # HTTP handlers
│   │   └── health.go
│   ├── service/             # Business logic
│   ├── repository/          # Data access
│   └── middleware/          # HTTP middleware
│       └── logger.go
├── pkg/                     # Exported packages (used by other services)
├── tests/
│   └── integration/
├── .env.example
├── .gitignore
├── Dockerfile
└── go.mod
```

## File Contents

### `go.mod`
```
module github.com/yourorg/my-service

go 1.22

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/joho/godotenv v1.5.1
    github.com/stretchr/testify v1.9.0
)
```

### `cmd/server/main.go`
```go
package main

import (
    "log"
    "os"

    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
    "github.com/yourorg/my-service/internal/handler"
)

func main() {
    if err := godotenv.Load(); err != nil {
        log.Println("No .env file found, using environment variables")
    }

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    r := gin.Default()
    handler.RegisterRoutes(r)

    log.Printf("Starting server on :%s", port)
    if err := r.Run(":" + port); err != nil {
        log.Fatalf("Failed to start server: %v", err)
    }
}
```

### `internal/handler/health.go`
```go
package handler

import (
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
)

func RegisterRoutes(r *gin.Engine) {
    r.GET("/health", healthCheck)
    // Register other routes here
}

func healthCheck(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "status":    "ok",
        "timestamp": time.Now().UTC().Format(time.RFC3339),
    })
}
```

### `internal/middleware/logger.go`
```go
package middleware

import (
    "log"
    "time"

    "github.com/gin-gonic/gin"
)

func Logger() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        c.Next()
        log.Printf("%s %s %d %v", c.Request.Method, c.Request.URL.Path,
            c.Writer.Status(), time.Since(start))
    }
}
```

### `Dockerfile`
```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server ./cmd/server

FROM scratch
COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### `.env.example`
```
PORT=8080
ENVIRONMENT=development
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
```

### `.gitignore`
```
/server
/bin/
*.exe
.env
vendor/
*.log
coverage.out
```

## Getting Started Commands

```bash
go mod tidy
cp .env.example .env
go run ./cmd/server        # development
go test ./...              # run tests
go test -cover ./...       # with coverage
go build -o server ./cmd/server  # build binary
```
