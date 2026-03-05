# Updating Projects from claude-starter

This guide describes how Claude can identify downstream projects that were bootstrapped from
`jodfie/claude-starter` and apply updates from newer template versions.

## How Versioning Works

When a project is created from the template (via `template-cleanup.sh` or the GitHub workflow),
it gets two version artifacts in `.claude/`:

- **`.claude/STARTER_VERSION`** — the semver string (e.g., `1.2.0`)
- **`.claude/starter-manifest.json`** — full metadata:
  ```json
  {
    "starter_repo": "jodfie/claude-starter",
    "version": "1.2.0",
    "commit": "78c578d",
    "bootstrapped_at": "2026-03-05",
    "bootstrapped_by": "template-cleanup"
  }
  ```

The starter repo tracks changes in `CHANGELOG.md` and `VERSION`.

---

## Update Workflow for Claude

### Step 1 — Find the current starter version

```bash
cat /tmp/claude-starter/VERSION        # if starter is already cloned locally
# or
gh api repos/jodfie/claude-starter/contents/VERSION --jq '.content' | base64 -d
```

### Step 2 — Find all downstream projects

```bash
# List all repos belonging to the user
gh repo list jodfie --limit 100 --json name,url | jq '.[].name'
```

For each repo, check if it has a starter manifest:
```bash
gh api repos/jodfie/<REPO>/contents/.claude/starter-manifest.json \
  --jq '.content' | base64 -d 2>/dev/null
```

Or check the version file directly:
```bash
gh api repos/jodfie/<REPO>/contents/.claude/STARTER_VERSION \
  --jq '.content' | base64 -d 2>/dev/null
```

A non-empty result means the repo was bootstrapped from this template.

### Step 3 — Compare versions

Read the project's version from `starter-manifest.json` (field: `version`).
Compare against the current starter `VERSION`.

If project version < current version: updates are available.

### Step 4 — Determine what changed

Read `CHANGELOG.md` from the starter repo. Find all changelog entries **after** the
project's recorded version. For each entry, use the **"Files Changed"** sections to get
the exact list of files that were added, changed, or deleted.

Example: a project at `1.1.0` needs entries for `1.2.0` (and any later versions).

### Step 5 — Clone the project and apply updates

```bash
git clone https://github.com/jodfie/<REPO>.git /tmp/<REPO>
cd /tmp/<REPO>
```

For each file listed in the changelog as **Added** or **Changed**:
```bash
# Copy the updated template file from the starter into the project
# The mapping is:  .github/templates/claude/X  →  .claude/X
#                  docs/X                       →  docs/X
#                  CLAUDE.md                    →  CLAUDE.md
#                  .gitignore                   →  .gitignore
```

For files listed as **Deleted**, remove them from the project.

### Step 6 — Bump the manifest

After applying updates, update `.claude/starter-manifest.json`:
```json
{
  "starter_repo": "jodfie/claude-starter",
  "version": "<new-version>",
  "commit": "<new-commit>",
  "bootstrapped_at": "<original-date>",
  "bootstrapped_by": "template-cleanup",
  "last_updated_at": "<today>",
  "last_updated_to": "<new-version>"
}
```

And update `.claude/STARTER_VERSION` to the new version string.

### Step 7 — Commit and push

```bash
git add .claude/starter-manifest.json .claude/STARTER_VERSION <changed-files>
git commit -m "chore: update from claude-starter v<new-version>"
git push origin main
```

---

## File Mapping Reference

Files in the starter repo map to project locations as follows:

| Starter source                                   | Project destination              |
|--------------------------------------------------|----------------------------------|
| `.github/templates/claude/settings.json`         | `.claude/settings.json`          |
| `.github/templates/claude/skills/<skill>/`       | `.claude/skills/<skill>/`        |
| `.github/templates/claude/agents/<agent>.md`     | `.claude/agents/<agent>.md`      |
| `.github/templates/claude/commands/<cmd>/`       | `.claude/commands/<cmd>/`        |
| `.github/templates/claude/scripts/`              | `.claude/scripts/`               |
| `.github/templates/claude/STARTER_VERSION`       | `.claude/STARTER_VERSION`        |
| `.github/templates/bootstrap.sh`                 | `bootstrap.sh` (deleted post-run)|
| `CLAUDE.md`                                      | `CLAUDE.md`                      |
| `.gitignore`                                     | `.gitignore`                     |
| `docs/`                                          | `docs/`                          |

---

## Quick Reference Commands

```bash
# Check a project's starter version
gh api repos/jodfie/<REPO>/contents/.claude/STARTER_VERSION --jq '.content' | base64 -d

# Check the current starter version
gh api repos/jodfie/claude-starter/contents/VERSION --jq '.content' | base64 -d

# Read the changelog (to see what changed between versions)
gh api repos/jodfie/claude-starter/contents/CHANGELOG.md --jq '.content' | base64 -d

# Get the starter manifest from a project
gh api repos/jodfie/<REPO>/contents/.claude/starter-manifest.json --jq '.content' | base64 -d
```

---

## Notes

- **Project-specific customizations** (e.g., custom CLAUDE.md content added after bootstrap,
  project-specific skills, or overridden settings) should be preserved. Only update the
  files explicitly listed in the CHANGELOG for the relevant versions.
- When updating `CLAUDE.md`, carefully merge changes rather than overwriting if the project
  has custom additions below the template sections.
- When updating `settings.json`, merge the allow/deny lists rather than replacing wholesale.
- The `bootstrap.sh` is deleted after running in a project, so it doesn't need to be updated.
