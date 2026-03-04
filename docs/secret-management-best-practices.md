# Secret Management Best Practices

This document outlines team-wide best practices for managing secrets in repositories using the claude-starter template with Phase CLI integration.

## Philosophy

**Core Principle**: Secrets should never be committed to version control. Instead, they should be:
- Stored centrally in Phase (self-hosted at `https://secrets.redleif.dev`)
- Retrieved automatically at runtime via `phase run`
- Environment-specific (dev/staging/production)
- Auditable and rotatable

## Repository Setup

### 1. Initial Configuration

When creating a new repository from this template:

**Step 1**: Choose or create a Phase app

Contact the team lead or use the Phase console at `https://secrets.redleif.dev` to:
1. Create a new app (e.g., `myapp-backend`) **or** use an existing app (`global`, `openclaw`, `mancave`, `memory`)
2. Add secrets for each environment (`dev`, `staging`, `production`)

**Step 2**: Link the project

```bash
cd ~/projects/myproject
phase init --host https://secrets.redleif.dev
# Select app name and default environment interactively
```

This creates `.phase.json` — commit it to the repo.

**Step 3**: Document required secrets

```markdown
# Add to README.md

## Required Secrets

This project requires the following secrets configured in Phase (app: `myapp`, env: `production`):

| Secret Name     | Description                     | Required For      |
|----------------|---------------------------------|-------------------|
| `DATABASE_URL`  | PostgreSQL connection string    | All environments  |
| `API_KEY`       | External API key                | All environments  |
| `JWT_SECRET`    | JWT signing key (random 32 ch.) | All environments  |

### Setup

1. Ensure Phase CLI is installed: `pip install phase-cli`
2. Verify auth: `phase users whoami --host https://secrets.redleif.dev`
3. Run: `phase run --host https://secrets.redleif.dev -- npm run dev`
```

### 2. Example Configuration Files

Always provide `.env.example` with placeholder values:

```bash
# .env.example — commit this file
# Actual values are managed in Phase, not here.

DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
API_KEY=your_api_key_here
JWT_SECRET=generate_random_32_char_string
SMTP_HOST=smtp.example.com
SMTP_PASSWORD=your_password
```

## Development Workflows

### Run with secrets

```bash
# With .phase.json in project (uses configured app + env)
phase run --host https://secrets.redleif.dev -- npm run dev

# Explicit (for CI or multi-env work)
phase run \
  --host https://secrets.redleif.dev \
  --app myapp \
  --env production \
  -- npm start
```

### Onboarding New Developers

```markdown
## New Developer Checklist

- [ ] Install Phase CLI: `pip install phase-cli`
- [ ] Verify auth: `phase users whoami --host https://secrets.redleif.dev`
  - If not authenticated: `phase auth --mode token --host https://secrets.redleif.dev`
- [ ] Check project link: `cat .phase.json`
- [ ] Test: `phase secrets list --host https://secrets.redleif.dev --env production`
- [ ] Run: `phase run --host https://secrets.redleif.dev -- npm run dev`
```

### Secret Rotation

```bash
# 1. Update in Phase console (https://secrets.redleif.dev)
#    or via CLI:
phase secrets update API_KEY \
  --host https://secrets.redleif.dev \
  --app myapp \
  --env production

# 2. No code changes needed — all developers get new value on next run

# 3. Notify team
echo "API_KEY rotated in Phase — restart dev server"
```

**Rotation schedule:**
- Critical secrets (DB, payment APIs): every 90 days
- JWT secrets: every 180 days
- Service tokens: every 30 days
- Immediately if compromised or team member departs

## Security Policies

### 1. Git Commit Policies

**Never commit:**
- `.env`, `.env.local`, `.env.*.local` — actual secret values
- `~/.phase/config.json` — Phase service token
- Any file with `*credentials*`, `*secrets*`, `*.key`, `*.pem`

**Always commit:**
- `.phase.json` — project→app link (no credentials inside)
- `.env.example` — placeholder values for documentation

### 2. Environment Access Matrix

| Role              | Dev        | Staging    | Production |
|-------------------|-----------|------------|------------|
| Developer         | Read/Write | Read       | None       |
| Senior Developer  | Read/Write | Read/Write | Read       |
| Team Lead         | Read/Write | Read/Write | Read/Write |
| CI/CD             | Read       | Read       | Read       |

### 3. Secret Classification

**Level 1 — Critical** (production DB, payment APIs):
- Separate Phase app or restricted path
- Rotation every 30 days

**Level 2 — High** (API keys, JWT secrets):
- Standard access
- Rotation every 90 days

**Level 3 — Medium** (SMTP, CDN):
- Standard access
- Rotation every 180 days

**Level 4 — Low** (feature flags, config):
- Can appear in `.env.example`
- Rotation as needed

## CI/CD Integration

### GitHub Actions

```yaml
name: Test and Deploy

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Phase CLI
        run: pip install phase-cli

      - name: Authenticate Phase
        env:
          PHASE_SERVICE_TOKEN: ${{ secrets.PHASE_SERVICE_TOKEN }}
        run: |
          mkdir -p ~/.phase
          echo "{\"default_user\":\"ci\",\"users\":{\"ci\":{\"host\":\"https://secrets.redleif.dev\",\"token\":\"$PHASE_SERVICE_TOKEN\"}}}" > ~/.phase/config.json

      - name: Run tests with secrets
        run: |
          phase run \
            --host https://secrets.redleif.dev \
            --app myapp \
            --env staging \
            -- npm test
```

**GitHub secrets to configure:**
- `PHASE_SERVICE_TOKEN` — Phase service account token (from `~/.phase/config.json`)

Never store actual application secrets in GitHub — only the Phase token.

## Incident Response

### If Secrets Are Compromised

**Immediate (within 1 hour):**
1. Rotate affected secrets in Phase console or via CLI:
   ```bash
   phase secrets update COMPROMISED_KEY \
     --host https://secrets.redleif.dev \
     --app myapp \
     --env production \
     --random hex --length 32
   ```
2. Check audit logs in Phase console
3. Notify all team members

**Short-term (within 24 hours):**
1. Review all commits for additional exposed secrets
2. Scan production logs for unauthorized access
3. Document incident in security log

### If Secrets Are Committed to Git

**DO NOT** just delete the commit — secrets remain in Git history.

```bash
# 1. Immediately rotate the secret in Phase (make exposure useless)

# 2. Remove from Git history
git filter-repo --path-glob '**/.env*' --invert-paths

# 3. Force push (if caught early)
git push --force origin main

# 4. If pushed to public GitHub:
#    Rotate ALL secrets immediately — consider them permanently compromised
```

## Troubleshooting

**"Not authenticated"**
```bash
phase auth --mode token --host https://secrets.redleif.dev
# Or verify: phase users whoami --host https://secrets.redleif.dev
```

**"App not found"**
```bash
# Check .phase.json has correct app name
cat .phase.json

# Or list available apps by trying a known one
phase secrets list --host https://secrets.redleif.dev --app global --env production
```

**"Secret not found"**
```bash
# List all secrets to confirm names
phase secrets list --host https://secrets.redleif.dev --app myapp --env production
```

## Additional Resources

- [Phase Integration Guide](./phase-integration.md) — detailed setup and workflows
- [Phase Skill](../.github/templates/claude/skills/phase-secrets/SKILL.md) — full CLI command reference
- [Official Phase Docs](https://docs.phase.dev/cli/commands)

---

**Last Updated**: 2026-03-05
**Review Frequency**: Quarterly
