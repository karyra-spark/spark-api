# Contributing to Spark API

Thank you for your interest in Spark API.

Spark API is the Rust/Axum backend for Karyra Spark, a Starknet readiness gateway focused on safe, structured blockchain education for local communities.

## Project Principles

- Keep the API secure by default.
- Do not commit secrets, private `.env` files, local database dumps, pass artifacts, or backup files.
- Keep authentication and session logic explicit and reviewable.
- Do not introduce wallet signing, onchain writes, or financial/trading behavior without discussion.
- Keep public documentation clear enough for external reviewers and contributors.
- Prefer small, focused pull requests over broad rewrites.

## Development Setup

```bash
git clone https://github.com/karyra-spark/spark-api.git
cd spark-api

cp .env.example .env
docker compose -f infra/docker-compose.local.yml up -d postgres minio

cargo fmt --check
cargo check
cargo run
```

Health checks:

```bash
curl http://127.0.0.1:8787/health/live
curl http://127.0.0.1:8787/health/ready
```

`/health/ready` requires PostgreSQL to be reachable.

## Recommended Checks

Run these before opening a pull request:

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo check
cargo build
```

If your change touches database schema or query behavior, also run:

```bash
sqlx migrate run
```

## Branch and Commit Style

Use focused branch names:

```bash
git checkout -b feat/add-profile-endpoint
git checkout -b fix/session-cookie-flags
git checkout -b docs/update-api-reference
```

Prefer clear commit messages:

```text
feat: add profile readiness endpoint
fix: harden session cookie clearing
docs: describe local infrastructure setup
```

## Pull Request Checklist

- [ ] The change has a clear scope.
- [ ] `cargo fmt --check` passes.
- [ ] `cargo clippy -- -D warnings` passes.
- [ ] `cargo check` passes.
- [ ] No secrets, private `.env` files, or local artifacts are committed.
- [ ] Database migrations are included when schema changes are required.
- [ ] Public docs are updated if routes, environment variables, or deployment behavior changed.
- [ ] Security-sensitive changes are described clearly in the PR.

## Security-Sensitive Changes

Please discuss first before changing password hashing, session token behavior, cookie security flags, CORS behavior, database migration safety, object storage access controls, authentication boundaries, or wallet/onchain behavior.

## License

This repository currently has no explicit license file. Until one is added, all rights remain with the contributors.
