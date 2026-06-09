# API Reference

Spark API exposes JSON HTTP endpoints for Karyra Spark.

This document describes the stable public contract areas. Some beta domain routes may evolve as the product matures.

## Base URL

Local development:

```text
http://127.0.0.1:8787
```

Production/staging depends on deployment topology.

## Content Type

Use JSON for request and response bodies:

```http
Content-Type: application/json
```

## Health

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/health/live` | None | Process liveness check |
| `GET` | `/health/ready` | None | Readiness check, including database availability |

## Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/v1/auth/register` | None | Create a new account |
| `POST` | `/v1/auth/login` | None | Authenticate and set session cookie |
| `GET` | `/v1/auth/me` | Cookie | Return the current authenticated user |
| `POST` | `/v1/auth/logout` | Cookie | Invalidate the current session |
| `GET` | `/v1/auth/scope` | Cookie | Return session scope information |

## Session Lifecycle

1. A user registers or logs in.
2. The API verifies credentials and creates a session token.
3. The raw token is sent to the client as an `httpOnly` cookie.
4. Only the SHA-256 hash of the token is stored in the database.
5. Later requests authenticate through the cookie.
6. Logout removes the session record and clears the cookie.

## Example: Register

```bash
curl -X POST http://127.0.0.1:8787/v1/auth/register   -H "Content-Type: application/json"   -d '{"email":"learner@example.com","password":"a-strong-password"}'
```

## Example: Login

```bash
curl -c cookies.txt -X POST http://127.0.0.1:8787/v1/auth/login   -H "Content-Type: application/json"   -d '{"email":"learner@example.com","password":"a-strong-password"}'
```

## Example: Current User

```bash
curl -b cookies.txt http://127.0.0.1:8787/v1/auth/me
```

## Beta Domain Areas

| Domain | Prefix | Purpose |
|---|---|---|
| Profile | `/v1/profile` | Account/profile data |
| Learning | `/v1/learning` | Core learning progress |
| Lab | `/v1/lab` | Practice Lab state |
| Media | `/v1/media` | Media metadata and lifecycle |
| Proof | `/v1/proof` | Readiness/proof events |
| Passport | `/v1/passport` | Readiness Passport data |
| Community | `/v1/community` | Participation signals |
| Hub | `/v1/hub` | Ecosystem exploration signals |
| Social | `/v1/social` | Social/community-related state |

Detailed contracts for beta routes should be documented as they stabilize.
