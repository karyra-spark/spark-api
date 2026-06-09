# Docker Deployment

Spark API includes a Dockerfile for building a production-style container image.

## Image Structure

The Dockerfile uses a Rust builder stage, a slim Debian runtime stage, a non-root `spark` user, and a built-in healthcheck.

## Build

```bash
docker build -t karyra-spark-api:latest .
```

## Run

```bash
docker run   --env-file .env.production   -p 8787:8787   karyra-spark-api:latest
```

## Required Runtime Configuration

Production-like deployments should provide:

```env
APP_ENV=production
SPARK_API_HOST=0.0.0.0
SPARK_API_PORT=8787
SPARK_WEB_ORIGIN=https://your-frontend-domain.example
DATABASE_URL=postgres://...
S3_ENDPOINT=https://...
S3_BUCKET_PUBLIC=...
S3_BUCKET_PRIVATE=...
SPARK_SESSION_COOKIE=spark_session
SPARK_SESSION_TTL_DAYS=14
SPARK_COOKIE_SECURE=true
```

## Healthcheck

The container healthcheck calls:

```text
http://127.0.0.1:8787/health/live
```

Use `/health/ready` when the deployment system needs database readiness.

## Reverse Proxy

A reverse proxy may route:

```text
/health/* → Spark API
/v1/*     → Spark API
```

The frontend and Hub may be served separately depending on deployment topology.

## Production Checklist

- [ ] `SPARK_COOKIE_SECURE=true`
- [ ] `SPARK_WEB_ORIGIN` matches the deployed frontend origin
- [ ] `DATABASE_URL` comes from secret management
- [ ] Object storage credentials come from secret management
- [ ] Migrations have been applied
- [ ] Health checks pass
- [ ] API logs do not expose secrets
- [ ] Public reverse proxy does not expose internal tools
