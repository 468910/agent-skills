---
name: pull-main
description: Safely update local main from origin/main, put the current work branch on top of the updated main without rewriting published history, and push normally when the user asks to update main or pull latest before pushing work.
metadata:
  short-description: Update main and stack work
---

# Update Main

## Trigger Phrases

- update main
- pull latest main
- sync main
- refresh main
- update main before pushing my work
- pull latest and push my work
- put my work on top of main

## Goal

Fast-forward local `main` to the latest `origin/main`, return to the starting work branch, put that branch on top of updated `main` without force-push risk, and push the work branch normally when requested.

## Behavior

1. Inspect repository state:

```bash
git status --short
git branch --show-current
```

2. Stop if there are uncommitted changes. Do not stash automatically. Current work must be committed before this workflow changes branches.
3. Remember the starting branch. If already on `main`, only update `main`; there is no separate work branch to stack.
4. Check out `main`:

```bash
git checkout main
```

5. Fetch latest refs:

```bash
git fetch origin
```

6. Fast-forward local `main` only:

```bash
git pull --ff-only origin main
```

7. Verify clean state:

```bash
git status --short
git rev-parse main
git rev-parse origin/main
```

8. If the user started on another branch, check it out again:

```bash
git checkout <starting-branch>
```

9. Fetch and inspect the branch upstream, if any:

```bash
git status --short --branch
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

10. Put the work branch on top of updated `main`:

- If the branch has no upstream or has not been pushed before, rebase the work branch onto `main`, then push normally with `git push -u origin <starting-branch>`.
- If the branch already has an upstream, do not rebase it because publishing rewritten history would require a force push. Merge updated `main` into the work branch, then push normally with `git push`.

```bash
git merge main
git push
```

11. If the user specifically asked for a linear unpublished branch and the branch has no upstream, use:

```bash
git rebase main
git push -u origin <starting-branch>
```

12. Verify clean state and report the final branch, whether `main` matches `origin/main`, what integration method was used, and whether the work branch was pushed.

## Expected Result

Local `main` is clean and fast-forwarded to `origin/main`. The starting work branch contains the latest `main` plus the user's committed work and has been pushed with a normal, non-force push when requested.

## Stop Only For

- Dirty worktree or untracked files that make checkout unsafe
- `main` branch does not exist
- Authentication failure
- Network failure
- `origin/main` is unavailable
- `git pull --ff-only origin main` cannot fast-forward
- Local `main` has commits not on `origin/main`
- The starting work branch has no commits beyond updated `main`
- Merge or rebase conflicts
- Normal push is rejected

## Never

- Rebase local `main`
- Force push
- `git push --force`
- `git push --force-with-lease`
- `git reset --hard`
- Rebase a work branch that already has an upstream, unless the user explicitly accepts that the normal push may be rejected and force push is still forbidden
- Destructive git operations
- Auto-stash or auto-commit user changes

## If Blocked

- Explain the reason
- Provide the exact command needed to continue
- Leave the repository on the safest branch reached so far and report that branch

## Definition of "update main and push my work"

```bash
git status --short
current_branch="$(git branch --show-current)"
git checkout main
git fetch origin
git pull --ff-only origin main
git status --short
git checkout "$current_branch"
git merge main
git push
```

Use `git rebase main` only for an unpublished work branch when linear history is requested. Never rebase local `main`. Never force push.
