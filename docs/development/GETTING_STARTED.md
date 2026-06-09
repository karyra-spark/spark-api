# Getting Started

This guide helps developers run Spark API locally.

Spark API is a Rust/Axum backend backed by PostgreSQL and S3-compatible object storage. It serves the authenticated backend layer for Karyra Spark.

## Prerequisites

Install:

- Rust stable, preferably through `rustup`;
- Docker and Docker Compose;
- Git;
- `sqlx-cli` for migrations.

Install `sqlx-cli`:

```bash
cargo install sqlx-cli --no-default-features --features rustls,postgres
```

## Clone the Repository

```bash
git clone https://github.com/karyra-spark/spark-api.git
cd spark-api
```

## Configure Environment

```bash
cp .env.example .env
```

The default `.env.example` values are for local development only.

## Start Local Infrastructure

```bash
docker compose -f infra/docker-compose.local.yml up -d postgres minio
```

This starts PostgreSQL on `127.0.0.1:5432`, MinIO on `127.0.0.1:9000`, and MinIO console on `127.0.0.1:9001` depending on compose configuration.

## Apply Database Migrations

```bash
sqlx migrate run
```

## Run Checks

```bash
cargo fmt --check
cargo check
```

Optional lint:

```bash
cargo clippy -- -D warnings
```

## Run the API

```bash
cargo run
```

The server listens on `http://127.0.0.1:8787` unless overridden by `SPARK_API_HOST` and `SPARK_API_PORT`.

## Health Checks

```bash
curl http://127.0.0.1:8787/health/live
curl http://127.0.0.1:8787/health/ready
```

`/health/live` checks process liveness. `/health/ready` requires the database to be reachable.

## Frontend Integration

The frontend should set its API base URL to:

```env
PUBLIC_SPARK_API_URL="http://127.0.0.1:8787"
```

Spark API allows the frontend origin configured by:

```env
SPARK_WEB_ORIGIN="http://127.0.0.1:5173"
```

Do not use wildcard CORS in production.
