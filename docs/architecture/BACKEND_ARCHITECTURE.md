# Backend Architecture

Spark API is the backend service for Karyra Spark.

It provides authenticated API surfaces for the Spark frontend and persists application state in PostgreSQL. It is designed to work with self-hosted S3-compatible object storage for media and asset workflows.

## Repository Role

```text
spark      → public SvelteKit frontend
spark-api  → Rust/Axum backend API and deployment stack
hub        → Starknet ecosystem gateway
```

This repository contains the backend API only.

## High-Level Flow

```text
SvelteKit frontend
        │
        │ HTTP + httpOnly session cookie
        ▼
Rust/Axum API
        │
        ├── PostgreSQL via SQLx
        └── S3-compatible object storage
```

## Runtime Responsibilities

Spark API handles account registration/login, password hashing, httpOnly session cookies, token-hash session persistence, profile/account data, learning and lab progress records, readiness/passport records, proof/readiness event records, media lifecycle metadata, community and hub participation signals, and deployment health checks.

Spark API should not handle seed phrases, private keys, browser wallet signing, trading or financial execution, public admin/Studio writer surfaces, or committed production secrets.

## Main Modules

| Area | Role |
|---|---|
| `auth` | Registration, login, session identity |
| `profile` | Account/profile data |
| `learning` | Learning progress |
| `lab` | Practice/Lab progress |
| `passport` | Readiness Passport records |
| `proof` | Readiness/proof event records |
| `media` | Media metadata and lifecycle |
| `community` | Participation signals |
| `hub` | Ecosystem exploration signals |
| `health` | Liveness/readiness endpoints |
| `config` | Environment configuration |
| `state` | Shared application state |
| `http` | Router and middleware assembly |

## Router Shape

Public HTTP routes are grouped under:

```text
/health/*
/v1/auth/*
/v1/profile/*
/v1/learning/*
/v1/lab/*
/v1/media/*
/v1/proof/*
/v1/passport/*
/v1/community/*
/v1/hub/*
/v1/social/*
```

Route contracts may evolve while the product remains in beta.

## State and Database

`AppState` owns shared runtime state, including parsed configuration and the SQLx PostgreSQL pool. Database-backed routes and readiness checks require PostgreSQL to be available.

## CORS

CORS should allow the configured Spark frontend origin only. Production should not use wildcard origins.
