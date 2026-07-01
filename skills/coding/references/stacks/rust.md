# Rust + Axum Scaffold Reference

## Directory Tree

```
my-service/
├── src/
│   ├── main.rs              # Entry point
│   ├── routes/
│   │   ├── mod.rs
│   │   └── health.rs
│   ├── handlers/            # Request handlers
│   ├── services/            # Business logic
│   └── errors.rs            # App error types
├── tests/
│   └── integration_test.rs  # Integration tests
├── .env.example
├── .gitignore
├── Dockerfile
└── Cargo.toml
```

## File Contents

### `Cargo.toml`
```toml
[package]
name = "my-service"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["full"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["trace", "cors"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
dotenvy = "0.15"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }

[dev-dependencies]
axum-test = "14"
tokio = { version = "1", features = ["full"] }
```

### `src/main.rs`
```rust
use axum::{Router, serve};
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod errors;
mod routes;

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{port}");

    let app = Router::new()
        .merge(routes::router())
        .layer(TraceLayer::new_for_http());

    let listener = TcpListener::bind(&addr).await.unwrap();
    tracing::info!("Listening on {addr}");
    serve(listener, app).await.unwrap();
}
```

### `src/routes/mod.rs`
```rust
mod health;

use axum::Router;

pub fn router() -> Router {
    Router::new().merge(health::router())
}
```

### `src/routes/health.rs`
```rust
use axum::{routing::get, Json, Router};
use serde_json::{json, Value};

pub fn router() -> Router {
    Router::new().route("/health", get(health_check))
}

async fn health_check() -> Json<Value> {
    Json(json!({ "status": "ok" }))
}
```

### `src/errors.rs`
```rust
use axum::{http::StatusCode, response::{IntoResponse, Response}, Json};
use serde_json::json;

#[derive(Debug)]
pub enum AppError {
    NotFound(String),
    InternalServer(String),
    BadRequest(String),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, msg),
            AppError::BadRequest(msg) => (StatusCode::BAD_REQUEST, msg),
            AppError::InternalServer(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg),
        };
        (status, Json(json!({ "error": message }))).into_response()
    }
}
```

### `Dockerfile`
```dockerfile
FROM rust:1.77-alpine AS builder
RUN apk add --no-cache musl-dev
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo 'fn main() {}' > src/main.rs
RUN cargo build --release
COPY src ./src
RUN touch src/main.rs && cargo build --release

FROM scratch
COPY --from=builder /app/target/release/my-service /my-service
EXPOSE 8080
ENTRYPOINT ["/my-service"]
```

### `.env.example`
```
PORT=8080
RUST_LOG=info
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
```

### `.gitignore`
```
/target
.env
Cargo.lock  # Remove this line for binary crates (keep for library crates)
```

## Getting Started Commands

```bash
cp .env.example .env
cargo run              # development
cargo test             # run tests
cargo build --release  # optimized build
cargo clippy           # lint
cargo fmt              # format
```
