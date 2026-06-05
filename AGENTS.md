# AGENTS.md

This repository contains reusable coding-agent skills.

## Usage

- When the user says "pull main", "update main", or "sync main", use the `git/pull-main` skill.
- Skills should be portable across agent frameworks.
- Prefer explicit behavior over agent interpretation.

## Installation

Run `./install.sh` to create symlinks into supported agent directories:

- `~/.agent-skills/`
- `~/.codex/`
- `~/.opencode/`
- `~/.agy/`
