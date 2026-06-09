# Local Infrastructure

Spark API depends on PostgreSQL and S3-compatible object storage.

For local development, these are provided by Docker Compose.

## Start Services

```bash
docker compose -f infra/docker-compose.local.yml up -d postgres minio
```

## PostgreSQL

Typical local database URL:

```env
DATABASE_URL=postgres://spark:spark_dev_password@127.0.0.1:5432/spark
```

These credentials are local-only development values.

## MinIO

Default local endpoint:

```env
S3_ENDPOINT=http://127.0.0.1:9000
```

Bucket names:

```env
S3_BUCKET_PUBLIC=spark-public
S3_BUCKET_PRIVATE=spark-private
```

## Stop Services

```bash
docker compose -f infra/docker-compose.local.yml down
```

## Reset Local Data

This removes local volumes and deletes local database/object-storage data:

```bash
docker compose -f infra/docker-compose.local.yml down -v
```

Then restart and re-run migrations:

```bash
docker compose -f infra/docker-compose.local.yml up -d postgres minio
sqlx migrate run
```

## Troubleshooting

If `/health/ready` fails, check PostgreSQL:

```bash
docker compose -f infra/docker-compose.local.yml ps
sqlx migrate info
```

If the API starts but frontend cannot call it, check `SPARK_WEB_ORIGIN`, frontend `PUBLIC_SPARK_API_URL`, CORS settings, cookie settings, and whether browser/API are using compatible hostnames (`localhost` vs `127.0.0.1`).
