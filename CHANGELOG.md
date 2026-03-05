# Changelog

All notable changes to the claude-starter template are documented here.

> **For Claude**: When updating a downstream project, look at the version in the project's
> `.claude/starter-manifest.json`, find all entries in this file **after** that version,
> and use the "Files Changed" lists to know exactly what to copy/update/delete.
> See `docs/updating-projects.md` for the full update workflow.

---

## [1.2.0] - 2026-03-05

**commit**: `78c578d`

### Summary
Replaced Infisical with Phase CLI for secret management. Phase is self-hosted at
`https://secrets.redleif.dev`. Added versioning/manifest system so downstream projects
can be tracked and updated.

### Added
- `.github/templates/claude/skills/phase-secrets/SKILL.md` → `.claude/skills/phase-secrets/SKILL.md`
  Full Phase CLI command reference (755 lines): all commands, flags, dynamic secrets, export formats
- `docs/phase-integration.md` — setup guide, instance details, CI/CD pattern
- `VERSION` — semver version file for the starter repo
- `CHANGELOG.md` — this file
- `.github/templates/claude/STARTER_VERSION` → `.claude/STARTER_VERSION`
- `docs/updating-projects.md` — guide for Claude to update downstream projects
- Added `starter-manifest.json` recording in `template-cleanup.sh` and workflow

### Changed
- `CLAUDE.md` — replaced entire "Secret Management with Infisical" section with Phase
- `docs/secret-management-best-practices.md` — full rewrite for Phase workflows
- `.gitignore` — updated secret management section: Phase instead of Infisical
- `.github/templates/claude/settings.json` — added Phase CLI allow rules
  (`phase secrets list/get/export/run`, `phase users whoami`); denied `.phase/config.json` reads
- `.github/templates/bootstrap.sh` — added `phase init` step post-`/init`

### Deleted
- `docs/infisical-integration.md`

---

## [1.1.0] - 2026-01-14

**commit**: `8ac62be`

### Summary
Added Infisical CLI integration for automated secret management.

### Added
- `docs/infisical-integration.md`
- `docs/secret-management-best-practices.md`
- Infisical section in `CLAUDE.md`
- Infisical ignore patterns in `.gitignore`

---

## [1.0.0] - 2026-01-14

**commit**: `bec1e7f`

### Summary
Initial release. Claude Code starter template with Task Master, Serena, and Context7 MCP
server configurations. Template cleanup workflow, bootstrap script, and skills for common
development workflows.

### Added
- `.github/templates/claude/` — settings, commands, agents, scripts, skills
- `.github/templates/serena/` — Serena project config
- `.github/templates/taskmaster/` — Task Master config and CLAUDE.md
- `.github/workflows/template-cleanup.yml`
- `template-cleanup.sh`
- `CLAUDE.md`
- `README.md`
- `LICENSE.md`
