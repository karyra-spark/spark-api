# Commands and Workflow

## Core Commands

| Command | Purpose |
|---|---|
| `cargo fmt --check` | Check Rust formatting |
| `cargo fmt` | Format Rust code |
| `cargo check` | Type-check without producing a final binary |
| `cargo build` | Build debug binary |
| `cargo build --release` | Build optimized release binary |
| `cargo run` | Run the API locally |
| `cargo clippy -- -D warnings` | Run lints and fail on warnings |

## Local Infrastructure

Start local dependencies:

```bash
docker compose -f infra/docker-compose.local.yml up -d postgres minio
```

Stop local dependencies:

```bash
docker compose -f infra/docker-compose.local.yml down
```

Remove local volumes only when you intentionally want to reset data:

```bash
docker compose -f infra/docker-compose.local.yml down -v
```

## Migrations

```bash
sqlx migrate run
sqlx migrate revert
sqlx migrate info
```

## Recommended Development Loop

```bash
cargo fmt --check
cargo check
cargo clippy -- -D warnings
cargo run
```

Before committing:

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo check
cargo build
```

## Public Repo Hygiene

Do not commit `.env` files except `.env.example`, local database dumps, pass folders or zip artifacts, `.bak`/`.tmp`/`.orig`/`.rej` files, private deployment notes, secret values, server credentials, local screenshots, or scratch files.
