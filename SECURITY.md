# Security Policy

Spark API is a beta-stage backend for Karyra Spark. It supports education-first onboarding and readiness features, not trading or financial execution.

## Supported Status

```text
BETA / early production-readiness work
```

Security behavior may evolve as the API matures.

## Public Security Principles

Spark API should not:

- ask users for seed phrases;
- ask users for private keys;
- store wallet secrets;
- perform onchain writes by default;
- expose public admin or Studio writer routes;
- frame the product as financial advice or a trading tool;
- commit production credentials or populated `.env` files.

Spark API may:

- authenticate users;
- issue httpOnly session cookies;
- store hashed session tokens;
- persist learning, lab, passport, community, media, and hub-related application records;
- connect to PostgreSQL and S3-compatible object storage;
- expose health and version/status surfaces for deployment checks.

## Authentication and Sessions

Spark API uses password hashing and cookie-based sessions.

Expected security posture:

- passwords are hashed with Argon2;
- raw session tokens are not stored in the database;
- token hashes are stored for lookup and invalidation;
- cookies should be `httpOnly`;
- cookies should be `Secure` in HTTPS environments;
- production CORS should allow only the trusted frontend origin.

## Reporting a Vulnerability

Please do not publicly disclose exploitable details before maintainers have reviewed the issue.

When reporting, include the affected endpoint/component, expected behavior, observed behavior, reproduction steps, impact assessment, and safe logs/screenshots if useful.

Do not include private keys, seed phrases, production tokens, server credentials, full `.env` files, real user personal data, or private grant/budget/operations notes.

## Production Secret Handling

Use deployment secret management for `DATABASE_URL`, object storage credentials, session/cookie settings, origin/domain values, and provider-specific tokens. Only `.env.example` should be committed.
