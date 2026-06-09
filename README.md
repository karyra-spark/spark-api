# Spark API

> **Rust/Axum backend for [Karyra Spark](https://spark.user.cloudjkt01.com)**  
> A Starknet readiness gateway — safe, structured blockchain education for local communities.

Spark API is the server-side backbone of the Karyra Spark platform. It is built in Rust with Axum, backed by PostgreSQL, and designed for self-hosted deployment. It handles authentication, session management, user data, readiness records, progress signals, and object-storage integration for the [spark](https://github.com/karyra-spark/spark) SvelteKit frontend and the broader Karyra Spark stack.

**Language:** Rust 99.5% · Dockerfile 0.5%  
**Status:** `BETA 0.1` — authentication foundation is implemented; profile, learning, lab, passport, proof, media, community, hub, and social APIs are evolving as beta domain surfaces.

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
  - [Beta Domain Surfaces](#beta-domain-surfaces)
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
- Issuing and validating `httpOnly` session cookies
- Storing only session token hashes, never raw session tokens
- Providing user identity and scope information to the frontend
- Supporting profile, learning, lab, passport, proof, community, hub, and social readiness records
- Bridging the SvelteKit frontend to PostgreSQL and S3-compatible object storage

The API is intentionally small and iterative. New domain surfaces are added in focused, reviewable increments so authentication, progress, readiness, media, and community behavior remain auditable as the platform grows.

---

## Architecture

```text
┌───────────────────────────────┐
│   SvelteKit Frontend (spark)  │
│   localhost:5173 (dev)        │
└──────────────┬────────────────┘
               │ HTTP (CORS, httpOnly cookie)
               ▼
┌───────────────────────────────┐
│      Spark API (Axum)         │
│      0.0.0.0:8787             │
└──────────┬─────────┬──────────┘
           │         │
           ▼         ▼
    ┌──────────┐  ┌─────────────────────┐
    │PostgreSQL│  │ MinIO / Garage / R2  │
    │ :5432    │  │ S3-compatible store  │
    └──────────┘  └─────────────────────┘
```

- **Frontend** communicates with the API over HTTP and is authenticated by the `spark_session` cookie.
- **PostgreSQL** is the primary data store for users, sessions, progress, readiness, and domain records.
- **Object storage** supports public and private assets through an S3-compatible interface.
- **Hub and Spark** remain separate public-facing applications, while the API owns authenticated persistence and trust-critical backend behavior.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | [Rust](https://www.rust-lang.org) (stable channel) |
| Web Framework | [Axum 0.7](https://github.com/tokio-rs/axum) |
| Async Runtime | [Tokio 1](https://tokio.rs) (multi-thread) |
| Database | [PostgreSQL](https://www.postgresql.org) |
| DB Client | [SQLx 0.8](https://github.com/launchbadge/sqlx) |
| Password Hashing | [Argon2 0.5](https://docs.rs/argon2) |
| Token Hashing | [sha2 0.10](https://docs.rs/sha2) (SHA-256) |
| Serialisation | [Serde](https://serde.rs) + [serde_json](https://docs.rs/serde_json) |
| Date/Time | [chrono 0.4](https://docs.rs/chrono) |
| UUIDs | [uuid 1](https://docs.rs/uuid) (v4) |
| HTTP Middleware | [tower-http 0.5](https://docs.rs/tower-http) (CORS, tracing) |
| Logging | [tracing](https://docs.rs/tracing) + [tracing-subscriber](https://docs.rs/tracing-subscriber) |
| Error Handling | [anyhow](https://docs.rs/anyhow) + [thiserror](https://docs.rs/thiserror) |
| Env Config | [dotenvy 0.15](https://docs.rs/dotenvy) |
| Object Storage | MinIO / Garage / Cloudflare R2 or any S3-compatible storage |
| Containerisation | Docker (multi-stage, `debian:bookworm-slim` runtime) |
| Toolchain | Rust stable · rustfmt · clippy |

---

## Project Structure

```text
spark-api/
├── infra/
│   └── docker-compose.local.yml  # Local PostgreSQL + MinIO services
├── migrations/                   # SQLx database migrations
├── src/
│   ├── auth/                     # Registration, login, sessions, auth scope
│   ├── community/                # Community participation signals
│   ├── config.rs                 # Environment-backed runtime config
│   ├── error.rs                  # API error mapping
│   ├── health/                   # Liveness and readiness checks
│   ├── http/                     # Axum router and middleware
│   ├── hub/                      # Hub exploration signals
│   ├── lab/                      # Lab progress records
│   ├── learning/                 # Learning progress records
│   ├── media/                    # Media lifecycle metadata
│   ├── passport/                 # Readiness Passport read models
│   ├── proof/                    # Proof/readiness event records
│   ├── profile/                  # Account and profile state
│   ├── social/                   # Social/community interaction signals
│   ├── state.rs                  # Shared application state
│   └── main.rs                   # Entry point
├── .env.example                  # Safe local environment template
├── .gitignore
├── Cargo.lock
├── Cargo.toml
├── Dockerfile
└── README.md
```

---

## Getting Started

### Prerequisites

- **Rust** stable, installed via [rustup](https://rustup.rs)
- **Docker** and **Docker Compose**, for local PostgreSQL and MinIO
- **sqlx-cli**, for running database migrations

Install `sqlx-cli` with PostgreSQL support:

```bash
cargo install sqlx-cli --no-default-features --features rustls,postgres
```

### Local Infrastructure

Start local database and object storage before running the API:

```bash
docker compose -f infra/docker-compose.local.yml up -d postgres minio
```

This starts:

- **PostgreSQL** on `localhost:5432`
- **MinIO** on `localhost:9000`
- **MinIO console** on `localhost:9001`, depending on local compose configuration

### Installation

```bash
git clone https://github.com/karyra-spark/spark-api.git
cd spark-api

cp .env.example .env

docker compose -f infra/docker-compose.local.yml up -d postgres minio

sqlx migrate run

cargo fmt --check
cargo check
```

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_ENV` | `development` | Application environment (`development` or `production`) |
| `RUST_LOG` | `spark_api=info,tower_http=info` | Log filter directives |
| `SPARK_API_HOST` | `127.0.0.1` | Bind address for the API server |
| `SPARK_API_PORT` | `8787` | Listen port |
| `SPARK_WEB_ORIGIN` | `http://127.0.0.1:5173` | Allowed CORS origin for the frontend |
| `DATABASE_URL` | `postgres://spark:spark_dev_password@127.0.0.1:5432/spark` | Local PostgreSQL connection string |
| `DATABASE_MAX_CONNECTIONS` | `5` | SQLx connection pool size |
| `S3_ENDPOINT` | `http://127.0.0.1:9000` | Local or deployed object storage endpoint |
| `S3_BUCKET_PUBLIC` | `spark-public` | Bucket for public assets |
| `S3_BUCKET_PRIVATE` | `spark-private` | Bucket for private/user assets |
| `SPARK_SESSION_COOKIE` | `spark_session` | Name of the session cookie |
| `SPARK_SESSION_TTL_DAYS` | `14` | Session lifetime in days |
| `SPARK_COOKIE_SECURE` | `false` | Set to `true` in HTTPS environments |

> **Production note:** Never commit a populated `.env` file. Use deployment secrets for `DATABASE_URL`, object-storage credentials, and any future service tokens. Set `SPARK_COOKIE_SECURE=true` in any HTTPS environment.

### Running the Server

```bash
cargo run
```

The server binds to the address and port defined in `.env`.

Health checks:

```bash
curl http://127.0.0.1:8787/health/live
curl http://127.0.0.1:8787/health/ready
```

`GET /health/live` confirms the process is running.  
`GET /health/ready` requires a working database connection.

---

## API Reference

All JSON API endpoints use `application/json`.

### Health

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/health/live` | None | Process liveness check |
| `GET` | `/health/ready` | None | Readiness check requiring database access |

### Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/v1/auth/register` | None | Create a new user account |
| `POST` | `/v1/auth/login` | None | Authenticate and set session cookie |
| `GET` | `/v1/auth/me` | Cookie | Return the authenticated user's identity |
| `POST` | `/v1/auth/logout` | Cookie | Invalidate the current session |
| `GET` | `/v1/auth/scope` | Cookie | Return the session's permission scope |

Session lifecycle:

1. `POST /v1/auth/register` creates a user record with an Argon2-hashed password.
2. `POST /v1/auth/login` verifies credentials, generates a session token, stores its SHA-256 hash, and sets an `httpOnly` `spark_session` cookie.
3. Subsequent requests authenticate by presenting the cookie. The API hashes the incoming token and compares it with the stored hash.
4. `POST /v1/auth/logout` removes the session record and clears the cookie.

Example — register:

```bash
curl -X POST http://127.0.0.1:8787/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "learner@example.com", "password": "a-strong-password"}'
```

Example — login:

```bash
curl -c cookies.txt -X POST http://127.0.0.1:8787/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "learner@example.com", "password": "a-strong-password"}'
```

Example — get current user:

```bash
curl -b cookies.txt http://127.0.0.1:8787/v1/auth/me
```

### Beta Domain Surfaces

The API also exposes beta domain routes for authenticated Spark features:

| Prefix | Role |
|---|---|
| `/v1/profile` | Account and profile records |
| `/v1/learning` | Learning progress records |
| `/v1/lab` | Practice Lab progress records |
| `/v1/media` | Media lifecycle metadata |
| `/v1/proof` | Readiness/proof event records |
| `/v1/passport` | Readiness Passport read models |
| `/v1/community` | Community participation records |
| `/v1/hub` | Hub exploration signals |
| `/v1/social` | Social/community interaction signals |

These routes are part of the beta platform surface and may evolve while the API matures.

---

## Security Model

**Password storage:** Passwords are hashed with Argon2id via the `argon2` crate. Plain-text passwords are never persisted.

**Session tokens:** A cryptographically random token is generated on login. Only its SHA-256 digest is stored in the database. The raw token is sent to the client as an `httpOnly` cookie and is never written to the database.

**Cookie security:**

- `httpOnly` prevents JavaScript from reading the cookie.
- `SameSite` helps reduce cross-site request forgery risk.
- `Secure` must be set to `true` in HTTPS deployments via `SPARK_COOKIE_SECURE=true`.

**Session TTL:** Sessions expire after `SPARK_SESSION_TTL_DAYS` days.

**CORS:** `SPARK_WEB_ORIGIN` defines the allowed frontend origin. Do not use wildcard CORS in production.

**Wallet safety:** Spark API does not handle seed phrases, private keys, wallet signing, or onchain writes.

---

## Database Migrations

Migrations are managed by SQLx and live in the `migrations/` directory as timestamped SQL files.

```bash
sqlx migrate run
sqlx migrate revert
sqlx migrate info
```

SQLx compile-time query verification may require a live database or an offline query cache. For CI environments without a database, generate the cache first:

```bash
cargo sqlx prepare
```

This writes `.sqlx/` metadata that can support compile-time checking without a live database.

---

## Deployment

### Docker

The `Dockerfile` uses a multi-stage build. A Rust builder image produces a release binary, which is copied into a smaller Debian runtime image. The container runs as a non-root `spark` user.

Build:

```bash
docker build -t karyra-spark-api:latest .
```

Run:

```bash
docker run \
  --env-file .env.production \
  -p 8787:8787 \
  karyra-spark-api:latest
```

Exposed port:

```text
8787
```

Built-in healthcheck:

```text
curl -fsS http://127.0.0.1:8787/health/live
```

Production checklist:

- [ ] `SPARK_COOKIE_SECURE=true`
- [ ] `DATABASE_URL` points to a production PostgreSQL instance
- [ ] `S3_ENDPOINT` and bucket names are configured for your object storage provider
- [ ] `SPARK_WEB_ORIGIN` is set to the production frontend origin
- [ ] Database migrations have been applied with `sqlx migrate run`
- [ ] Secrets are provided by deployment secret management, not committed `.env` files

---

## Development Workflow

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo check
cargo build
cargo build --release
cargo run
```

Optional live-reload:

```bash
cargo install cargo-watch
cargo watch -x run
```

---

## Scope and Roadmap

The current implementation includes the authentication foundation and beta domain surfaces for profile, learning, lab, media, proof, passport, community, hub, and social records.

The following areas are still evolving:

- Email verification
- Password reset flow
- Rate limiting for login and registration
- Role-based access control
- More detailed public API contracts for beta domain routes
- Stronger media/object-storage access policies
- Starknet wallet linkage and onchain verification milestones

Future work should keep the API safe by default: no seed phrase handling, no private key handling, no wallet signing, and no onchain writes unless introduced as an explicit reviewed milestone.

---

## Related Repositories

| Repository | Description |
|---|---|
| [karyra-spark/spark](https://github.com/karyra-spark/spark) | SvelteKit frontend — the public-facing Spark platform |
| [karyra-spark/hub](https://github.com/karyra-spark/hub) | Starknet ecosystem gateway and resource hub |

---

## Contributing

Contributions are welcome. Please open an issue before submitting a pull request for any non-trivial change so the scope can be aligned with the current beta roadmap.

```bash
git checkout -b feat/your-feature-name

cargo fmt --check
cargo clippy -- -D warnings
cargo check
```

Keep commits focused and describe the domain area being changed, such as auth, profile, learning, lab, passport, media, community, hub, or deployment.

---

## License

This repository does not yet include an explicit license file. Until one is added, all rights remain with the contributors. Please open an issue to discuss terms before reusing or forking this project.

---

*Spark API — backend foundation for Karyra Spark.*  
*© 2026 Karyra Spark*
