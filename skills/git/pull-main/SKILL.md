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

Fast-forward local `main` to the latest `origin/main`, preserve uncommitted local changes by temporarily stashing them when needed, return to the starting work branch, put that branch or local changes on top of updated `main` without force-push risk, and push normally only when requested.

## Behavior

1. Inspect repository state:

```bash
git status --short
git branch --show-current
```

2. Remember the starting branch and whether there are uncommitted changes.

   If `git branch --show-current` returns empty (detached HEAD), stop and report that pull-main requires being on a named branch. Suggest `git checkout -b pull-main-recovery` to create a recovery branch, then retry.

3. If there are uncommitted changes, create a temporary autostash before changing branches or pulling:

```bash
git stash push --include-untracked -m "pull-main autostash $(date -u +%Y%m%dT%H%M%SZ)"
```

Keep the stash reference from the command output if possible. If stashing fails, stop.
4. If already on `main`, only update `main` and then reapply any autostash; there is no separate work branch to stack.
5. Check out `main`:

```bash
git checkout main
```

6. Fetch latest refs:

```bash
git fetch origin
```

7. Fast-forward local `main` only:

```bash
git pull --ff-only origin main
```

8. Verify clean state:

```bash
git status --short
git rev-parse main
git rev-parse origin/main
```

9. If the user started on `main` and an autostash was created, reapply it on top of updated `main`:

```bash
git stash pop
```

If `git stash pop` reports conflicts, stop and report that the user's changes are now partially applied with conflicts to resolve. Suggest `git merge --abort` (if in a merge state) or `git checkout --theirs . && git add -u && git stash drop` as recovery options. Do not run more integration or push commands.
10. Verify state:

```bash
git status --short
git rev-parse main
git rev-parse origin/main
```

If the user started on `main`, stop here unless they explicitly asked to commit and push the reapplied changes.
11. If the user started on another branch, check it out again:

```bash
git checkout <starting-branch>
```

12. If an autostash was created, reapply it on the starting branch before integrating updated `main`:

```bash
git stash pop
```

If `git stash pop` reports conflicts, stop and report that the user's changes are now partially applied with conflicts to resolve. Suggest resolving conflicts manually or running `git checkout --theirs . && git add -u && git stash drop` to discard stashed changes. Do not run merge, rebase, or push commands.
13. Check whether the work branch has any commits beyond updated `main`:

```bash
# If the branch has no unique commits, skip merge/rebase — it's already up to date
if [ -z "$(git log main..HEAD --oneline)" ]; then
  echo "Branch is already up to date with main."
  # Stop here; no integration needed
fi
```

14. Fetch and inspect the branch upstream, if any:

```bash
git status --short --branch
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

15. Put the work branch on top of updated `main`:

- If the branch has no upstream or has not been pushed before, rebase the work branch onto `main`, then push normally with `git push -u origin <starting-branch>`.
- If the branch already has an upstream, do not rebase it because publishing rewritten history would require a force push. Merge updated `main` into the work branch, then push normally with `git push`.

```bash
git merge --no-edit main
git push
```

16. If the user specifically asked for a linear unpublished branch and the branch has no upstream, use:

```bash
git rebase main
git push -u origin <starting-branch>
```

17. Verify clean state and report the final branch, whether `main` matches `origin/main`, whether an autostash was created and reapplied, what integration method was used, and whether anything was pushed.

## Expected Result

Local `main` is fast-forwarded to `origin/main`. If the user had uncommitted changes on `main`, those changes are reapplied on top of updated `main`. If the user started on another branch, that branch contains the latest `main` plus the user's work and is pushed with a normal, non-force push only when requested.

## Stop Only For

- `git stash push --include-untracked` fails
- `main` branch does not exist
- Authentication failure
- Network failure
- `origin/main` is unavailable
- `git pull --ff-only origin main` cannot fast-forward
- Local `main` has commits not on `origin/main`
- The starting work branch has no commits beyond updated `main`
- Merge or rebase conflicts
- `git stash pop` conflicts
- Normal push is rejected

## Never

- Rebase local `main`
- Force push
- `git push --force`
- `git push --force-with-lease`
- `git reset --hard`
- Rebase a work branch that already has an upstream, unless the user explicitly accepts that the normal push may be rejected and force push is still forbidden
- Destructive git operations
- Auto-commit user changes
- Drop a stash unless it was successfully reapplied and removed by `git stash pop`

## If Blocked

- Explain the reason
- Provide the exact command needed to continue
- Leave the repository on the safest branch reached so far and report that branch

## Definition of "pull main and put my changes on top"

```bash
git status --short
current_branch="$(git branch --show-current)"
if [ -z "$current_branch" ]; then
  echo "ERROR: detached HEAD — pull-main requires a named branch."
  exit 1
fi
if [ -n "$(git status --short)" ]; then
  git stash push --include-untracked -m "pull-main autostash $(date -u +%Y%m%dT%H%M%SZ)"
fi
git checkout main
git fetch origin
git pull --ff-only origin main
git status --short
if [ "$current_branch" = "main" ]; then
  git stash pop
else
  git checkout "$current_branch"
  git stash pop
  # Skip integration if branch has no unique commits
  if [ -n "$(git log main..HEAD --oneline)" ]; then
    # Rebase if unpublished, merge if published
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
      git merge --no-edit main
    else
      git rebase main
    fi
  fi
fi
```

When the user explicitly asks to push a work branch after integration, use `git push` for a branch with an upstream or `git push -u origin <starting-branch>` for an unpublished branch. Do not push reapplied uncommitted changes on `main`; committing and pushing those changes requires an explicit user request.

Use `git rebase main` only for an unpublished work branch when linear history is requested. Never rebase local `main`. Never force push.
