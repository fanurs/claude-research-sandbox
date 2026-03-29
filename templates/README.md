# __PROJECT_NAME__

Autonomous multi-session research environment powered by Claude, running in a Docker container. Claude runs in a loop — each session reads what happened before, picks one objective, does the work, writes a report, and hands off to the next session.

## Quick Start

```bash
# 1. Build and start the container
./scripts/start.sh

# 2. Authenticate Claude inside the container
docker exec -it __PROJECT_NAME__-sandbox claude /login

# 3. Start the research loop
./scripts/start-loop.sh

# 4. Watch Claude work (detach with Ctrl+B D)
docker exec -it __PROJECT_NAME__-sandbox tmux attach -t research
```

## Controls

| Action | Command |
|--------|---------|
| Build and start container | `./scripts/start.sh` |
| Start the research loop | `./scripts/start-loop.sh` |
| Watch the loop | `docker exec -it __PROJECT_NAME__-sandbox tmux attach -t research` |
| Detach from tmux | `Ctrl+B` then `D` |
| Stop after current session | `touch state/STOP` |
| Check status | `./scripts/status.sh` |
| Pause container | `./scripts/pause.sh` |
| Resume container | `./scripts/resume.sh` |
| Shell into container | `./scripts/shell.sh` |
| Kill everything | `./scripts/cleanup.sh` |

## How It Works

Each Claude session follows a strict protocol:

1. **Orient** — Read state files (summary, journal, next action, plan)
2. **Scope** — Pick ONE clear objective for the session
3. **Work** — Write code, run experiments, analyze results
4. **Report** — Write a research diary entry in `reports/` with plots and analysis
5. **Handoff** — Update journal, write next action for the following session

Sessions chain automatically. Between sessions, the loop checks for a `state/STOP` file — if present, it exits gracefully.

## Providing Direction

You can steer the research without stopping the loop:

- **Edit `state/next_action.md`** to tell the next session what to focus on. Changes take effect when the next session starts.
- **Edit `prompts/01-research-directions.md`** to change high-level research priorities.
- **Create `state/STOP`** to stop the loop after the current session finishes, then edit state files and restart with `./scripts/start-loop.sh`.

## Cross-Session Memory

State files in `state/` persist between sessions:

| File | Purpose |
|------|---------|
| `summary.md` | Compressed history of all past sessions |
| `journal.md` | Detailed log of recent sessions (~10-15 entries) |
| `next_action.md` | Instructions for the next session |
| `plan.md` | Overall research roadmap and phases |

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `src/` | Research code |
| `data/` | Datasets |
| `checkpoints/` | Model checkpoints |
| `results/` | Evaluation results (JSON) |
| `notes/` | Research notes |
| `reports/` | Session reports with figures (research diary) |
| `logs/` | Session logs (text + JSON) |
| `state/` | Cross-session memory |
| `prompts/` | Immutable research instructions |
| `scripts/` | Control scripts |

## Scripts Reference

**Host-only** (use Docker commands, run from your terminal):
- `scripts/start.sh` — Build and start the container
- `scripts/pause.sh` — Pause the container
- `scripts/resume.sh` — Resume the container
- `scripts/shell.sh` — Open an interactive shell in the container

**Dual-mode** (auto-detect host vs container, work from either):
- `scripts/start-loop.sh` — Start the research loop
- `scripts/status.sh` — Show status (GPU, processes, tmux, stop signal)
- `scripts/cleanup.sh` — Kill all research processes

**Container-only** (run inside the container, called by the loop):
- `loop.sh` — Main research loop, chains sessions
- `scripts/run_session.sh` — Runs a single Claude session

## Requirements

- Docker
- Claude Code CLI (authenticated)
- nvidia-container-toolkit (optional, for GPU passthrough)
