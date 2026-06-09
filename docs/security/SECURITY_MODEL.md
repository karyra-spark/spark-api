# Security Model

Spark API is designed around safe onboarding and readiness, not financial execution.

## Core Security Principles

- Never store plain-text passwords.
- Never store raw session tokens.
- Never request seed phrases or private keys.
- Never commit production secrets.
- Keep CORS limited to the trusted frontend origin.
- Use `Secure` cookies in HTTPS environments.
- Keep admin/editor surfaces out of the public API unless explicitly reviewed.

## Password Handling

Passwords are hashed using Argon2. Plain-text passwords are accepted only during registration or login and are never persisted.

## Session Handling

- login generates a session token;
- the raw token is sent to the browser in an `httpOnly` cookie;
- the database stores only a SHA-256 token hash;
- logout invalidates the stored session;
- expired sessions are rejected.

## Cookie Flags

| Flag | Purpose |
|---|---|
| `httpOnly` | Prevent JavaScript access to the cookie |
| `Secure` | Require HTTPS transport |
| `SameSite` | Reduce cross-site request risk |
| `Path` | Scope cookie to the app/API path as needed |
| Expiry/Max-Age | Enforce session lifetime |

Set `SPARK_COOKIE_SECURE=true` in HTTPS deployments.

## CORS

`SPARK_WEB_ORIGIN` defines the allowed frontend origin. Production should not use `*` as an allowed origin.

## Object Storage

Do not expose private buckets publicly. Recommended split: public bucket for public assets, private bucket for user/restricted assets, signed or controlled access for private media.

## Sensitive Values

Do not commit production `DATABASE_URL`, S3 access keys, provider tokens, populated `.env` files, database dumps, server credentials, or private operational notes.
