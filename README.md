# Spark API

> **Rust/Axum backend for [Karyra Spark](https://spark.user.cloudjkt01.com)**  
> A Starknet readiness gateway — safe, structured blockchain education for local communities.

Spark API is the server-side backbone of the Karyra Spark platform. It is built in Rust with Axum, backed by PostgreSQL, and designed for self-hosted deployment. It handles authentication, session management, user data, and object storage for the [spark](https://github.com/karyra-spark/spark) SvelteKit frontend.

**Language:** Rust 99.5% · Dockerfile 0.5%  
**Status:** `PASS 46` — auth foundation complete; additional domain APIs (learning, passport, community) are in progress.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Local Infrastructure](#local-infrastructure)
  - [Installation](#installation)
  - [Environment Variables](#environment-variables)
  - [Running the Server](#running-the-server)
- [API Reference](#api-reference)
  - [Health](#health)
  - [Authentication](#authentication)
- [Security Model](#security-model)
- [Database Migrations](#database-migrations)
- [Deployment](#deployment)
  - [Docker](#docker)
- [Development Workflow](#development-workflow)
- [Scope and Roadmap](#scope-and-roadmap)
- [Related Repositories](#related-repositories)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

The Spark API serves the authenticated layer of the Karyra Spark learning platform. Its core responsibilities include:

- Registering and authenticating users with Argon2-hashed passwords
- Issuing and validating `httpOnly` session cookies (token hash only — never the raw token)
- Providing user identity and scope information to the frontend
- Bridging the SvelteKit frontend to PostgreSQL and S3-compatible object storage

The API is intentionally small and iterative. Each named pass in the commit history corresponds to a focused feature set, ensuring the codebase stays auditable as it grows.

---

## Architecture

```
┌───────────────────────────────┐
│   SvelteKit Frontend (spark)  │  ← spark.user.cloudjkt01.com
│   localhost:5173 (dev)        │
└──────────────┬────────────────┘
               │ HTTP (CORS, httpOnly cookie)
               ▼
┌───────────────────────────────┐
│      Spark API (Axum)         │  ← 0.0.0.0:8787
│      src/                     │
└──────────┬─────────┬──────────┘
           │         │
           ▼         ▼
    ┌──────────┐  ┌─────────────────────┐
    │PostgreSQL│  │ MinIO / Garage / R2  │
    │ :5432    │  │ S3-compatible store  │
    └──────────┘  └─────────────────────┘
```

- **Frontend** communicates with the API over HTTP, authenticated by the `spark_session` cookie.
- **PostgreSQL** is the primary data store for users, sessions, and application state.
- **Object storage** (MinIO or Garage locally; Cloudflare R2 in production) handles public and private assets.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | [Rust](https://www.rust-lang.org) (stable channel) |
| Web Framework | [Axum 0.7](https://github.com/tokio-rs/axum) |
| Async Runtime | [Tokio 1](https://tokio.rs) (multi-thread) |
| Database | [PostgreSQL](https://www.postgresql.org) |
| DB Client | [SQLx 0.8](https://github.com/launchbadge/sqlx) (async, compile-time verified) |
| Password Hashing | [Argon2 0.5](https://docs.rs/argon2) |
| Token Hashing | [sha2 0.10](https://docs.rs/sha2) (SHA-256) |
| Serialisation | [Serde](https://serde.rs) + [serde_json](https://docs.rs/serde_json) |
| Validation | [Zod-style](https://github.com/tokio-rs/axum) via Axum extractors |
| Date/Time | [chrono 0.4](https://docs.rs/chrono) |
| UUIDs | [uuid 1](https://docs.rs/uuid) (v4) |
| HTTP Middleware | [tower-http 0.5](https://docs.rs/tower-http) (CORS, tracing) |
| Logging | [tracing](https://docs.rs/tracing) + [tracing-subscriber](https://docs.rs/tracing-subscriber) |
| Error Handling | [anyhow](https://docs.rs/anyhow) + [thiserror](https://docs.rs/thiserror) |
| Env Config | [dotenvy 0.15](https://docs.rs/dotenvy) |
| Object Storage | MinIO / Garage (self-hosted) or Cloudflare R2 (production) |
| Containerisation | Docker (multi-stage, `debian:bookworm-slim` runtime) |
| Toolchain | Rust stable · rustfmt · clippy |

---

## Project Structure

```
spark-api/
├── .github/
│   └── workflows/          # CI/CD pipelines
├── config/                 # Application configuration modules
├── infra/
│   └── docker-compose.local.yml  # Local PostgreSQL + MinIO services
├── migrations/             # SQLx database migrations (ordered SQL files)
├── src/                    # Rust source code
│   └── main.rs             # Entry point
├── .env.example            # Environment variable template
├── .gitignore
├── Cargo.lock
├── Cargo.toml              # Dependencies and package metadata
├── Dockerfile              # Multi-stage production image
└── rust-toolchain.toml     # Pinned Rust stable + rustfmt + clippy
```

---

## Getting Started

### Prerequisites

- **Rust** (stable) — installed via [rustup](https://rustup.rs). The `rust-toolchain.toml` file automatically selects the correct channel and components.
- **Docker** and **Docker Compose** — for the local PostgreSQL and MinIO services.
- **sqlx-cli** — for running database migrations:

  ```bash
  cargo install sqlx-cli --no-default-features --features rustls,postgres
  ```

### Local Infrastructure

Start the local database and object storage before running the API:

```bash
docker compose -f infra/docker-compose.local.yml up -d postgres minio
```

This starts:
- **PostgreSQL** on `localhost:5432` with credentials from `.env`
- **MinIO** on `localhost:9000` (S3-compatible object storage)

### Installation

```bash
# Clone the repository
git clone https://github.com/karyra-spark/spark-api.git
cd spark-api

# Copy environment config
cp .env.example .env

# Run database migrations
sqlx migrate run

# Verify the build compiles cleanly
cargo fmt --check
cargo check
```

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_ENV` | `development` | Application environment (`development` / `production`) |
| `RUST_LOG` | `spark_api=info,tower_http=info` | Log filter directives |
| `SPARK_API_HOST` | `127.0.0.1` | Bind address for the API server |
| `SPARK_API_PORT` | `8787` | Listen port |
| `SPARK_WEB_ORIGIN` | `http://127.0.0.1:5173` | Allowed CORS origin (the SvelteKit frontend URL) |
| `DATABASE_URL` | `postgres://spark:spark_dev_password@127.0.0.1:5432/spark` | PostgreSQL connection string |
| `DATABASE_MAX_CONNECTIONS` | `5` | SQLx connection pool size |
| `S3_ENDPOINT` | `http://127.0.0.1:9000` | Object storage endpoint |
| `S3_BUCKET_PUBLIC` | `spark-public` | Bucket for public assets |
| `S3_BUCKET_PRIVATE` | `spark-private` | Bucket for private/user assets |
| `SPARK_SESSION_COOKIE` | `spark_session` | Name of the session cookie |
| `SPARK_SESSION_TTL_DAYS` | `14` | Session lifetime in days |
| `SPARK_COOKIE_SECURE` | `false` | Set to `true` in production (requires HTTPS) |

> **Production note:** Never commit a populated `.env` file. Pass secrets through your deployment platform's secret management and ensure `SPARK_COOKIE_SECURE=true` is set in any HTTPS environment.

### Running the Server

```bash
cargo run
```

The server will start and bind to the address and port defined in your `.env`. Verify it is running:

```bash
curl http://127.0.0.1:8787/health/live
curl http://127.0.0.1:8787/health/ready
```

> `GET /health/ready` requires a live database connection. If PostgreSQL is not running, it will return an error. `GET /health/live` confirms the process is up regardless of DB state.

---

## API Reference

All endpoints are prefixed with `/v1`. Requests and responses use `application/json`.

### Health

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/health/live` | None | Process liveness check |
| `GET` | `/health/ready` | None | Readiness check (requires DB) |

### Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/v1/auth/register` | None | Create a new user account |
| `POST` | `/v1/auth/login` | None | Authenticate and set session cookie |
| `GET` | `/v1/auth/me` | Cookie | Return the authenticated user's identity |
| `POST` | `/v1/auth/logout` | Cookie | Invalidate the current session |
| `GET` | `/v1/auth/scope` | Cookie | Return the session's permission scope |

**Session lifecycle:**

1. `POST /v1/auth/register` creates the user record with an Argon2-hashed password.
2. `POST /v1/auth/login` verifies credentials, generates a session token, stores its SHA-256 hash in `sessions.token_hash`, and sets an `httpOnly` `spark_session` cookie. The raw token is never stored.
3. Subsequent requests authenticate by presenting the cookie; the API hashes the incoming token and compares it against the stored hash.
4. `POST /v1/auth/logout` removes the session record from the database and clears the cookie.

**Example — register:**

```bash
curl -X POST http://127.0.0.1:8787/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "learner@example.com", "password": "a-strong-password"}'
```

**Example — login:**

```bash
curl -c cookies.txt -X POST http://127.0.0.1:8787/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "learner@example.com", "password": "a-strong-password"}'
```

**Example — get current user:**

```bash
curl -b cookies.txt http://127.0.0.1:8787/v1/auth/me
```

---

## Security Model

**Password storage:** Passwords are hashed with [Argon2id](https://en.wikipedia.org/wiki/Argon2) via the `argon2` crate. Plain-text passwords are never persisted.

**Session tokens:** A cryptographically random token is generated on login. Only its SHA-256 digest is stored in the `sessions` table (`token_hash`). The raw token travels to the client in an `httpOnly` cookie and is never written to the database.

**Cookie security:**
- `httpOnly` — prevents JavaScript from reading the cookie, mitigating XSS attacks.
- `SameSite` — guards against cross-site request forgery.
- `Secure` — must be set to `true` in any production (HTTPS) deployment via `SPARK_COOKIE_SECURE=true`.

**Session TTL:** Sessions expire after `SPARK_SESSION_TTL_DAYS` days (default: 14). Expired sessions are invalid at query time.

**CORS:** `SPARK_WEB_ORIGIN` defines the single allowed origin. Do not use a wildcard (`*`) in production.

---

## Database Migrations

Migrations are managed by SQLx and live in the `migrations/` directory as timestamped SQL files.

```bash
# Apply all pending migrations
sqlx migrate run

# Revert the most recent migration
sqlx migrate revert

# Check migration status
sqlx migrate info
```

SQLx compile-time query verification (`query!` / `query_as!` macros) requires a live database or an offline query cache (`sqlx prepare`). For CI environments without a database, generate the cache first:

```bash
cargo sqlx prepare
```

This writes `.sqlx/` files that allow `cargo check` and `cargo build` to succeed without a database connection.

---

## Deployment

### Docker

The `Dockerfile` uses a multi-stage build: a `rust:1-bookworm` build stage produces a release binary, which is copied into a minimal `debian:bookworm-slim` runtime image. The container runs as a non-root `spark` user.

**Build the image:**

```bash
docker build -t karyra-spark-api:latest .
```

**Run the container:**

```bash
docker run \
  --env-file .env.production \
  -p 8787:8787 \
  karyra-spark-api:latest
```

**Exposed port:** `8787`  
**Built-in healthcheck:** `curl -fsS http://127.0.0.1:8787/health/live` (every 30 s, 5 s timeout, 3 retries)

**Production environment checklist:**

- [ ] `SPARK_COOKIE_SECURE=true`
- [ ] `DATABASE_URL` points to a production PostgreSQL instance
- [ ] `S3_ENDPOINT` and bucket names configured for your object storage provider
- [ ] `SPARK_WEB_ORIGIN` set to your production frontend domain
- [ ] Database migrations applied: `sqlx migrate run`
- [ ] Secrets managed via your platform's secret store (not a committed `.env` file)

---

## Development Workflow

```bash
# Format check (must pass before commit)
cargo fmt --check

# Lint with Clippy
cargo clippy -- -D warnings

# Type-check without building
cargo check

# Full build
cargo build

# Release build (used in Docker)
cargo build --release

# Run with live-reloading (requires cargo-watch)
cargo watch -x run
```

---

## Scope and Roadmap

The current implementation covers the authentication foundation. The following features are explicitly **not yet implemented** and are planned for future passes:

- Email verification
- Password reset flow
- Rate limiting (login attempts, registration)
- Role-based access control
- Learning progress and Core curriculum APIs
- Lab session and Passport readiness APIs
- Community and inbox APIs
- Starknet wallet linkage and on-chain verification

Each future pass will be documented in the commit history with a corresponding scope note.

---

## Related Repositories

| Repository | Description |
|---|---|
| [karyra-spark/spark](https://github.com/karyra-spark/spark) | SvelteKit frontend — the public-facing Spark platform |

---

## Contributing

Contributions are welcome. Please open an issue before submitting a pull request for any non-trivial change so the scope can be aligned with the current pass.

```bash
# Fork the repo, then create a feature branch
git checkout -b feat/your-feature-name

# Ensure format and lint pass before opening a PR
cargo fmt --check
cargo clippy -- -D warnings
cargo check
```

Keep commits focused. Match the existing pass-based structure when adding new feature areas.

---

## License

This repository does not yet include an explicit license file. Until one is added, all rights remain with the contributors. Please open an issue to discuss terms before reusing or forking this project.

---

*Spark API — backend foundation for Karyra Spark.*  
*© 2026 Karyra Spark*
