---
name: phase-secrets
description: >
  Comprehensive Phase CLI secrets manager for the self-hosted Redleif-Dev instance.
  Use for ALL secrets operations: listing, getting, creating, updating, deleting, importing,
  exporting, runtime injection, dynamic secrets, and account management.
  Triggers on: "get secret", "list secrets", "phase run", "inject secrets", "dynamic secrets",
  "create secret", "update secret", "delete secret", "import .env", "export secrets",
  "phase auth", "phase init", "whoami", "switch user", "phase shell".
---

# Phase Secrets Manager

## When to Use

Use this skill whenever the user asks to:
- Retrieve, list, create, update, or delete secrets
- Inject secrets at runtime into a command or shell
- Import secrets from a `.env` file or export them
- Manage dynamic secrets and leases
- Authenticate, switch users/orgs, or check account status
- Set up a new project to use Phase (`phase init`)

## Instance Context

| Field         | Value                                         |
|---------------|-----------------------------------------------|
| Host          | `https://secrets.redleif.dev`                 |
| Org           | Phi Security Inc.                             |
| Server        | Redleif-Dev Contabo VPS (Docker + Cloudflare) |
| Auth user     | `service` (service account, stored in `~/.phase/config.json`) |
| Auth mode     | Token (`pss_service:v2:...`)                  |

### Configured Apps

| App Name    | Description / Project                       |
|-------------|---------------------------------------------|
| `global`    | Global/shared secrets across all projects   |
| `openclaw`  | OpenClaw project                            |
| `mancave`   | Mancave project                             |
| `memory`    | Memory project                              |
| `pscollect` | PSCollect project (`~/projects/pscollect`)  |

> **CRITICAL**: Always pass `--host https://secrets.redleif.dev` in every command.
> This is a self-hosted instance — omitting `--host` will fail or hit the wrong endpoint.

---

## Safety Rules

1. **Never print/log secret values** in output, commits, or logs
2. **Always use `phase run`** instead of manually exporting secrets to the shell
3. **Never `echo` or `cat` secret values** directly to stdout
4. **Don't commit `.phase.json`** files that may contain sensitive project bindings; add to `.gitignore`
5. **Never commit `.phase/config.json`** or any file containing service tokens
6. **Use `phase run`** not `phase shell` in production (shell is BETA and leaves secrets in env)
7. **Prefer `--app`** flag over relying on `.phase.json` in scripts for explicit targeting
8. **Rotate tokens** if they appear in logs or are accidentally exposed

---

## Authentication & Setup

### `phase auth` — Authenticate with Phase

```bash
# Web browser auth (default)
phase auth --host https://secrets.redleif.dev

# Token-based auth (for service accounts / CI)
phase auth --mode token --host https://secrets.redleif.dev

# AWS IAM auth
phase auth --mode aws-iam \
  --service-account-id <SA_ID> \
  --ttl 3600 \
  --host https://secrets.redleif.dev

# Print token without storing (for piping/scripting)
phase auth --mode aws-iam \
  --service-account-id <SA_ID> \
  --no-store \
  --host https://secrets.redleif.dev
```

### `phase init` — Link project to a Phase app

Run this once in a project directory to create `.phase.json`:

```bash
cd ~/projects/myproject
phase init --host https://secrets.redleif.dev
# Interactive: select app and default environment
```

This creates `.phase.json`:
```json
{
  "version": "2",
  "phaseApp": "myapp",
  "appId": "...",
  "defaultEnv": "production"
}
```

### `phase users whoami` — Show current user info

```bash
phase users whoami --host https://secrets.redleif.dev
```

### `phase users switch` — Switch users, orgs, or hosts

```bash
phase users switch --host https://secrets.redleif.dev
# Interactive: select from stored credentials
```

### `phase users logout` — Log out

```bash
phase users logout --host https://secrets.redleif.dev
```

### `phase users keyring` — Show keyring info

```bash
phase users keyring --host https://secrets.redleif.dev
```

### `phase update` — Update the CLI

```bash
phase update
```

### `phase docs` / `phase console`

```bash
phase docs      # Opens CLI docs in browser
phase console   # Opens Phase web console in browser
```

---

## Runtime Injection

### `phase run` — Inject secrets at runtime (PREFERRED METHOD)

Secrets are injected into the subprocess environment only — they never touch the parent shell or history.

```bash
# Basic usage (uses .phase.json if present)
phase run --host https://secrets.redleif.dev -- npm start

# Specify app and environment explicitly
phase run \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  -- python manage.py runserver

# Target a specific path within secrets
phase run \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --path /database \
  -- ./migrate.sh

# Filter by tags
phase run \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env staging \
  --tags "api,backend" \
  -- node server.js

# Fetch from all paths (not just root)
phase run \
  --host https://secrets.redleif.dev \
  --app memory \
  --env production \
  --path "" \
  -- ./start.sh

# Control dynamic secret lease generation
phase run \
  --host https://secrets.redleif.dev \
  --app pscollect \
  --env production \
  --generate-leases true \
  --lease-ttl 3600 \
  -- ./app

# Using app-id instead of app name (takes precedence)
phase run \
  --host https://secrets.redleif.dev \
  --app-id 441db810-38ce-4b0b-a910-71402223e093 \
  --env production \
  -- docker-compose up
```

**Flags:**
| Flag | Description |
|------|-------------|
| `--env` | Environment: `dev`, `staging`, `production` |
| `--app` | App name (overrides `.phase.json`) |
| `--app-id` | App UUID (takes precedence over `--app`) |
| `--path` | Secret path prefix; default `/`; `""` = all paths |
| `--tags` | Comma-separated tag filter (partial match, case-insensitive) |
| `--generate-leases` | Auto-generate dynamic secret leases: `true`/`false` (default: `true`) |
| `--lease-ttl` | Lease TTL in seconds |

### `phase shell` — Subshell with secrets (BETA)

> **Warning:** BETA feature. Secrets persist in the subshell environment. Use `phase run` in production.

```bash
# Launch subshell with all production secrets
phase shell \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Specify shell type
phase shell \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --shell bash

# With path and tags filters
phase shell \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env staging \
  --path /api \
  --tags "backend"
```

**Flags:** same as `phase run` plus `--shell <bash|zsh|sh|fish|powershell>`

---

## Secrets Management

### `phase secrets list` — List all secrets

```bash
# List secrets (values censored by default)
phase secrets list \
  --host https://secrets.redleif.dev \
  --app global \
  --env production

# Show uncensored values (also generates dynamic secret leases)
phase secrets list \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  --show

# Filter by path
phase secrets list \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env production \
  --path /database

# Filter by tags
phase secrets list \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --tags "api,config"
```

**Value indicators in output:**
| Symbol | Meaning |
|--------|---------|
| 🔗 | References another secret (same env) |
| ⛓️ | Cross-environment reference |
| 🏷️ | Has a tag |
| 💬 | Has a comment |
| 🔏 | Personal secret (only visible to you) |
| ⚡️ | Dynamic secret |

### `phase secrets get` — Fetch a specific secret (JSON output)

```bash
# Get a single secret by key
phase secrets get DATABASE_URL \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Get from a specific path
phase secrets get API_KEY \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --path /integrations

# Filter by tag
phase secrets get TOKEN \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env staging \
  --tags "auth"

# Disable dynamic secret lease generation
phase secrets get MY_DYNAMIC_SECRET \
  --host https://secrets.redleif.dev \
  --app pscollect \
  --env production \
  --generate-leases false
```

### `phase secrets create` — Create a new secret

```bash
# Interactive (prompts for value)
phase secrets create API_KEY \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Pipe value from stdin (great for multiline values like SSH keys)
cat ~/.ssh/id_rsa | phase secrets create SSH_PRIVATE_KEY \
  --host https://secrets.redleif.dev \
  --app global \
  --env production

# Generate random value
phase secrets create SESSION_SECRET \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env production \
  --random hex \
  --length 32

# Random value types: hex, alphanumeric, base64, base64url, key128, key256
phase secrets create ENCRYPTION_KEY \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --random key256

# Create in a specific path
phase secrets create DB_PASSWORD \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  --path /database

# Create as personal override
phase secrets create MY_DEV_TOKEN \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env development \
  --override
```

**Random types:**
| Type | Description |
|------|-------------|
| `hex` | Hex string (default length 32) |
| `alphanumeric` | Letters + digits |
| `base64` | Standard base64 |
| `base64url` | URL-safe base64 |
| `key128` | 128-bit key (length ignored) |
| `key256` | 256-bit key (length ignored) |

### `phase secrets update` — Update an existing secret

```bash
# Interactive (prompts for new value)
phase secrets update DATABASE_URL \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Pipe new value from stdin
echo "new-password" | phase secrets update DB_PASSWORD \
  --host https://secrets.redleif.dev \
  --app global \
  --env production

# Pipe SSH key update
cat ~/.ssh/id_ed25519 | phase secrets update SSH_PRIVATE_KEY \
  --host https://secrets.redleif.dev \
  --app global \
  --env production

# Generate new random value
phase secrets update SESSION_SECRET \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env production \
  --random hex \
  --length 64

# Update secret in a specific path
phase secrets update API_KEY \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  --path /integrations

# Move secret to a new path
phase secrets update API_KEY \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  --path /old-path \
  --updated-path /new-path

# Update personal override value
phase secrets update MY_TOKEN \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env development \
  --override

# Toggle override active/inactive
phase secrets update MY_TOKEN \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env development \
  --toggle-override
```

### `phase secrets delete` — Delete secrets

```bash
# Delete a single secret
phase secrets delete API_KEY \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Delete multiple secrets at once
phase secrets delete KEY1 KEY2 KEY3 \
  --host https://secrets.redleif.dev \
  --app global \
  --env production

# Delete within a specific path
phase secrets delete DB_PASSWORD \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env production \
  --path /database/credentials
```

### `phase secrets import` — Import from `.env` file

```bash
# Import all secrets from a .env file
phase secrets import .env \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Import to a specific path
phase secrets import .env.database \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --path /database
```

`.env` file format:
```env
DATABASE_URL=postgres://user:pass@host:5432/db
API_KEY=sk-abc123
SECRET_KEY=my-secret-value
```

### `phase secrets export` — Export secrets

```bash
# Export as dotenv (default)
phase secrets export \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Export specific keys only
phase secrets export DATABASE_URL API_KEY \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Export as JSON
phase secrets export \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --format json

# Export as YAML
phase secrets export \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env staging \
  --format yaml

# Export from all paths
phase secrets export \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --path ""

# Export from specific path
phase secrets export \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  --path /database

# Filter by tags during export
phase secrets export \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --tags "api,backend"

# Export to file (redirect output)
phase secrets export \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  --format dotenv > .env.exported
```

**Export formats:** `dotenv` (default), `json`, `csv`, `yaml`, `xml`, `toml`, `hcl`, `ini`, `java_properties`, `kv`

---

## Dynamic Secrets

Dynamic secrets are auto-generated credentials with TTLs (e.g., DB credentials, API tokens).

### `phase dynamic-secrets list` — List dynamic secrets

```bash
# List all dynamic secrets in an app/env
phase dynamic-secrets list \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# Filter by path
phase dynamic-secrets list \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --path /database
```

### `phase dynamic-secrets lease get` — Get leases for a dynamic secret

```bash
phase dynamic-secrets lease get <secret_id> \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production
```

### `phase dynamic-secrets lease generate` — Generate a new lease

Creates fresh credentials for a dynamic secret:

```bash
phase dynamic-secrets lease generate <secret_id> \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production

# With custom TTL (in seconds)
phase dynamic-secrets lease generate <secret_id> \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  --lease-ttl 7200
```

### `phase dynamic-secrets lease renew` — Renew a lease

```bash
phase dynamic-secrets lease renew <lease_id> <ttl_seconds> \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production
```

### `phase dynamic-secrets lease revoke` — Revoke a lease

```bash
phase dynamic-secrets lease revoke <lease_id> \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production
```

---

## Secret Referencing

Phase supports referencing other secrets within values:

```
# Same-environment reference
${API_BASE_URL}/v1/endpoint

# Cross-environment reference
${staging.DATABASE_URL}

# Path-scoped reference
${/database/PASSWORD}
```

When listing, referenced secrets show 🔗 (same env) or ⛓️ (cross-env).

---

## Common Workflows

### CI/CD: Run app with injected secrets

```bash
# In a CI script, no .phase.json needed
phase run \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  -- ./deploy.sh
```

### Migrate `.env` to Phase

```bash
# 1. Import existing .env
phase secrets import .env \
  --host https://secrets.redleif.dev \
  --app myapp \
  --env production

# 2. Verify import
phase secrets list \
  --host https://secrets.redleif.dev \
  --app myapp \
  --env production

# 3. Replace app startup
# Before: source .env && node server.js
# After:
phase run \
  --host https://secrets.redleif.dev \
  --app myapp \
  --env production \
  -- node server.js
```

### Generate a secure random secret

```bash
# 256-bit encryption key
phase secrets create ENCRYPTION_KEY \
  --host https://secrets.redleif.dev \
  --app global \
  --env production \
  --random key256

# 64-char hex session secret
phase secrets create SESSION_SECRET \
  --host https://secrets.redleif.dev \
  --app mancave \
  --env production \
  --random hex \
  --length 64
```

### Check what's stored in an app

```bash
phase secrets list \
  --host https://secrets.redleif.dev \
  --app global \
  --env production
```

### Rotate a secret

```bash
# Generate new value
phase secrets update API_KEY \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  --random alphanumeric \
  --length 48
```

---

## Global Flags Reference

| Flag | Description |
|------|-------------|
| `--host <url>` | Phase server URL — **ALWAYS** `https://secrets.redleif.dev` |
| `--app <name>` | App name: `global`, `openclaw`, `mancave`, `memory`, `pscollect` |
| `--app-id <uuid>` | App UUID (takes precedence over `--app`) |
| `--env <env>` | Environment: `dev`, `development`, `staging`, `production` |
| `--path <path>` | Secret path (default `/`; `""` = all paths) |
| `--tags <tags>` | Comma-separated tag filter; case-insensitive, partial match |
| `--show` | Show uncensored secret values (use with care) |
| `--generate-leases` | `true`/`false` — auto-generate dynamic secret leases |
| `--lease-ttl <sec>` | TTL in seconds for generated leases |

---

## Project File: `.phase.json`

Created by `phase init`. Allows omitting `--app`/`--env` flags:

```json
{
  "version": "2",
  "phaseApp": "pscollect",
  "appId": "441db810-38ce-4b0b-a910-71402223e093",
  "defaultEnv": "production",
  "monorepoSupport": false
}
```

Add to `.gitignore` for projects with sensitive app IDs. The `--app` and `--app-id` flags always override `.phase.json`.

---

## Installation Reference

```bash
# Install via pip
pip install phase-cli

# Or via curl installer (Linux/macOS)
curl -fsSL https://pkg.phase.dev/install.sh | bash

# Verify installation
phase --version
```
