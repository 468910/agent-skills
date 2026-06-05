---
name: pull-main
description: Safely update the local main branch from origin/main when the user asks to pull, sync, or update main.
metadata:
  short-description: Pull latest origin/main
---

# Pull Main

## Trigger Phrases

- pull main
- update main
- sync main

## Goal

Update the local main branch to match the latest origin/main.

## Behavior

1. Inspect repository state.
2. Check for uncommitted changes.
3. Switch to main:

```bash
git checkout main
```

4. Update local refs:

```bash
git fetch origin
```

5. Update local main:

```bash
git pull --ff-only origin main
```

6. Report success.

## Expected Result

Local main is up to date with origin/main.

## Stop Only For

- Checkout would overwrite local changes
- main branch does not exist
- Authentication failure
- Network failure
- Pull cannot fast-forward

## Never

- `git rebase`
- `git reset --hard`
- Merge origin/main into the current feature branch
- Destructive git operations

## If Blocked

- Explain the reason
- Provide the exact command needed to continue

## Definition of "pull main"

```bash
git checkout main
git pull --ff-only origin main
```

Nothing else.
