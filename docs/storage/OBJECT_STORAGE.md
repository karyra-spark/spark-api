# Object Storage

Spark API is designed to work with S3-compatible object storage.

Supported deployment styles include MinIO for local/self-hosted development, Garage for self-hosted production-style storage, and Cloudflare R2 or other S3-compatible providers for future hosted storage.

## Environment Variables

```env
S3_ENDPOINT=http://127.0.0.1:9000
S3_BUCKET_PUBLIC=spark-public
S3_BUCKET_PRIVATE=spark-private
```

Provider credentials should be supplied through deployment secrets, not committed files.

## Bucket Roles

| Bucket | Purpose |
|---|---|
| Public bucket | Public assets that can be safely exposed |
| Private bucket | User or restricted assets requiring controlled access |

## Local Development

Start MinIO:

```bash
docker compose -f infra/docker-compose.local.yml up -d minio
```

Default local endpoint:

```text
http://127.0.0.1:9000
```

MinIO console is commonly exposed at `http://127.0.0.1:9001` depending on local compose configuration.

## Public Safety Rules

Do not expose private buckets to the public internet, commit storage access keys, use production buckets for local tests, store private user data in public buckets, or assume object URLs are private unless access controls enforce it.

## Future Notes

As media workflows mature, document upload lifecycle, signed URL behavior, file size limits, MIME validation, retention policy, and privacy expectations.
