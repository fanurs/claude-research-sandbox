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
```

## Controls

| Action | Command |
|--------|---------|
| Build and start container | `./scripts/start.sh` |
| Start the research loop | `./scripts/start-loop.sh` |
| Watch (web UI) | `cd tools/viewer && npm start` → http://localhost:3000 |
| Watch (raw tmux) | `docker exec -it __PROJECT_NAME__-sandbox tmux attach -t research` |
| Detach from tmux | `Ctrl+B` then `D` |
| Stop after current session | `./scripts/stop.sh` |
| Stop after session N | `./scripts/stop.sh 50` |
| Check status | `./scripts/status.sh` |
| Pause container | `./scripts/pause.sh` |
| Resume container | `./scripts/resume.sh` |
| Shell into container | `./scripts/shell.sh` |
| Kill everything | `./scripts/cleanup.sh` |

## Watching Sessions

The tmux session shows raw NDJSON streaming — this is expected (Claude runs non-interactively with `--output-format stream-json`). For a human-readable view, use the **log viewer web UI**:

```bash
cd tools/viewer && npm start
# Open http://localhost:3000
```

The viewer runs on the host, reads log files from the bind-mounted `logs/` directory, and polls for new lines in real-time during active sessions.

## How It Works

Each Claude session follows a strict protocol (see `protocol.md`):

1. **Orient** — Read state files (summary, journal, next action, plan)
2. **Scope** — Pick ONE clear objective for the session
3. **Work** — Write code, run experiments, analyze results
4. **Report** — Write a research diary entry in `reports/` with plots and analysis
5. **Commit** — Git commit all changes
6. **Handoff** — Update journal, write next action for the following session

Sessions chain automatically. Between sessions, the loop checks for a `state/STOP` file — if present, it exits gracefully. Use `./scripts/stop.sh N` to stop after a specific session number.

## Providing Direction

You can steer the research without stopping the loop:

- **Edit `state/next_action.md`** to tell the next session what to focus on. Changes take effect when the next session starts.
- **Edit `README.md`** (the research directions section) to change high-level research priorities.
- **Run `./scripts/stop.sh`** to stop the loop after the current session finishes, then edit state files and restart with `./scripts/start-loop.sh`.

## Cross-Session Memory

State files in `state/` persist between sessions:

| File | Purpose |
|------|---------|
| `summary.md` | Compressed history of all past sessions (long-term memory) |
| `journal.md` | Detailed log of recent sessions, ~10-15 entries (working memory) |
| `next_action.md` | Detailed instructions for the next immediate session |
| `plan.md` | Overall research roadmap and phases |

## Project Structure

| Directory/File | Purpose |
|----------------|---------|
| `README.md` | Project description, research goal, directions |
| `CLAUDE.md` | Hard rules for the autonomous agent (~20 lines) |
| `protocol.md` | Session protocol and evaluation framework (immutable) |
| `playground/` | Exploration sessions (`playground/session-NNN-slug/`) |
| `src/` | Reusable research code (extracted from playground) |
| `tests/` | Tests for code in `src/` |
| `data/` | Datasets |
| `checkpoints/` | Model checkpoints |
| `results/` | Evaluation results (JSON) and cross-experiment comparison tables |
| `reports/` | Session reports with figures (research diary) |
| `logs/` | Session logs (text + JSON) |
| `state/` | Cross-session memory |
| `tools/viewer/` | Log viewer web UI |
| `scripts/` | Control scripts |

## Scripts Reference

**Host-only** (use Docker commands, run from your terminal):
- `scripts/start.sh` — Build and start the container
- `scripts/pause.sh` — Pause the container
- `scripts/resume.sh` — Resume the container
- `scripts/shell.sh` — Open an interactive shell in the container

**Dual-mode** (auto-detect host vs container, work from either):
- `scripts/start-loop.sh` — Start the research loop
- `scripts/stop.sh [N]` — Stop the loop (after current session, or at session N)
- `scripts/status.sh` — Show status (GPU, processes, tmux, stop signal)
- `scripts/cleanup.sh` — Kill all research processes

**Container-only** (run inside the container, called by the loop):
- `loop.sh` — Main research loop, chains sessions
- `scripts/run_session.sh` — Runs a single Claude session

## Requirements

- Docker
- Claude Code CLI (authenticated)
- nvidia-container-toolkit (optional, for GPU passthrough)
- npm (optional, for log viewer web UI)
