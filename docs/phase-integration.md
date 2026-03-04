# Phase CLI Integration Guide

This guide covers integrating Phase CLI into your development workflow for automated secret management against the self-hosted Redleif-Dev Phase instance.

## Overview

Phase CLI provides secure, automated access to secrets without manual copy-paste or committing sensitive data. The CLI is installed globally on your development machine, not per-repository. Projects are linked to a Phase app via `.phase.json`.

## Instance Details

| Field    | Value                           |
|----------|---------------------------------|
| Host     | `https://secrets.redleif.dev`   |
| Org      | Phi Security Inc.               |
| Server   | Redleif-Dev Contabo VPS (Docker + Cloudflare tunnels) |
| Auth     | Service token (`~/.phase/config.json`) |

> **Always pass `--host https://secrets.redleif.dev`** in every command.

## Installation

```bash
pip install phase-cli

# Verify
phase --version
```

## Authentication

The service account token is already configured in `~/.phase/config.json`. To verify or re-authenticate:

```bash
# Verify current auth
phase users whoami --host https://secrets.redleif.dev

# Re-authenticate with a service token
phase auth --mode token --host https://secrets.redleif.dev
```

## Linking a New Project

Run once per project to create `.phase.json`:

```bash
cd ~/projects/myproject
phase init --host https://secrets.redleif.dev
# Interactive: select app name and default environment
```

The generated `.phase.json`:
```json
{
  "version": "2",
  "phaseApp": "myapp",
  "appId": "...",
  "defaultEnv": "production"
}
```

Commit `.phase.json` — it contains no credentials, only project identifiers.

## Core Usage

### Run an app with secrets injected

```bash
# With .phase.json present (app/env from file)
phase run --host https://secrets.redleif.dev -- npm start

# Explicit app + env (for CI or override)
phase run \
  --host https://secrets.redleif.dev \
  --app openclaw \
  --env production \
  -- python manage.py runserver
```

### List secrets

```bash
phase secrets list \
  --host https://secrets.redleif.dev \
  --app myapp \
  --env production
```

### Import existing `.env`

```bash
phase secrets import .env \
  --host https://secrets.redleif.dev \
  --app myapp \
  --env production
```

### Get a specific secret

```bash
phase secrets get DATABASE_URL \
  --host https://secrets.redleif.dev \
  --app myapp \
  --env production
```

## Available Apps

| App       | Description                      |
|-----------|----------------------------------|
| `global`  | Shared secrets across projects   |
| `openclaw`| OpenClaw project                 |
| `mancave` | Mancave project                  |
| `memory`  | Memory project                   |
| `pscollect` | PSCollect project              |

## Full Command Reference

See `.claude/skills/phase-secrets/SKILL.md` for the complete command reference including all flags, dynamic secrets, export formats, and workflows.

## Security

- `~/.phase/config.json` — stores your service token. **Never commit.**
- `.phase.json` — links project to app. **Safe to commit.**
- Use `phase run` to inject secrets into processes; never export them to the parent shell manually.
