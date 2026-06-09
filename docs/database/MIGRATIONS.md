# Database Migrations

Spark API uses SQLx migrations.

Migrations live in:

```text
migrations/
```

## Apply Migrations

```bash
sqlx migrate run
```

## Revert the Latest Migration

```bash
sqlx migrate revert
```

## Check Migration Status

```bash
sqlx migrate info
```

## Creating a Migration

```bash
sqlx migrate add <migration_name>
```

Use descriptive names, for example:

```bash
sqlx migrate add create_sessions_table
sqlx migrate add add_learning_progress_records
```

## Migration Guidelines

- Keep migrations focused.
- Avoid mixing unrelated schema changes.
- Prefer additive changes when possible.
- Make destructive changes explicit and review carefully.
- Include indexes for lookup-heavy fields.
- Keep auth/session migrations especially easy to audit.

## SQLx Query Checking

SQLx compile-time query verification may require a live database or offline query cache.

For offline query metadata:

```bash
cargo sqlx prepare
```

This generates `.sqlx/` metadata that can be used in CI-like environments without a live database.

## Local Reset

Only reset local volumes when you intentionally want to delete local development data:

```bash
docker compose -f infra/docker-compose.local.yml down -v
docker compose -f infra/docker-compose.local.yml up -d postgres minio
sqlx migrate run
```

Do not run destructive commands against production databases.
