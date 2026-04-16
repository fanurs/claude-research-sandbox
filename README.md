# research-sandbox

A Claude Code skill that creates autonomous research environments in Docker containers.

## What it does

`/research-sandbox` sets up a fully sandboxed, GPU-enabled research environment where Claude runs autonomously in a loop — each session tackles one research task, logs findings, and passes instructions to the next session. Like a researcher working day after day on a problem.

### Features

- **Docker sandbox**: All work happens inside a container with limited privileges
- **GPU access**: Automatic NVIDIA GPU detection and passthrough
- **Multi-session loop**: Claude sessions chain automatically via tmux
- **Cross-session memory**: Journal, summary, plan, and next-action files persist between sessions
- **Git integration**: Automatic commits after each session, `main` branch by default
- **STOP-N**: Stop after N sessions (`echo "STOP-50" > state/STOP`)
- **Playground pattern**: Exploration code in `playground/session-NN-slug/`, proven code in `src/`
- **Log viewer**: Web-based session viewer with real-time streaming (Express.js)
- **JSON logging**: Every session produces structured NDJSON logs
- **Safe controls**: Pause, resume, stop, cleanup scripts
- **Dual-mode scripts**: Key scripts auto-detect whether you're on the host or inside the container
- **Configurable model/effort**: Set Claude model and effort level via `.research-config`
- **Email notifications**: Optional session report emails via Resend with project name in subject

## Install

```bash
git clone https://github.com/cteh/claude-research-sandbox ~/.claude/skills/research-sandbox
```

## Usage

In any project directory:

```
/research-sandbox
```

Claude will ask for your research question, git identity, and preferences, then set up the environment and build the container. Then:

1. **Authenticate Claude inside the container:**
   ```bash
   docker exec -it <project>-sandbox claude /login
   ```

2. **Start the research loop:**
   ```bash
   ./scripts/start-loop.sh
   ```

3. **Watch sessions (web UI):**
   ```bash
   cd tools/viewer && npm start
   # Open http://localhost:3000
   ```

### Controls

| Action | Command |
|--------|---------|
| Build and start container | `./scripts/start.sh` |
| Start the research loop | `./scripts/start-loop.sh` |
| Watch (web UI) | `cd tools/viewer && npm start` |
| Watch (raw tmux) | `docker exec -it <project>-sandbox tmux attach -t research` |
| Detach from tmux | `Ctrl+B` then `D` |
| Stop after current session | `touch state/STOP` |
| Stop after session N | `echo "STOP-50" > state/STOP` |
| Pause container | `./scripts/pause.sh` |
| Resume container | `./scripts/resume.sh` |
| Check status | `./scripts/status.sh` |
| Shell into container | `./scripts/shell.sh` |
| Kill everything | `./scripts/cleanup.sh` |

`start-loop.sh`, `status.sh`, and `cleanup.sh` work from both the host and inside the container.

## Requirements

- Docker with nvidia-container-toolkit (for GPU support)
- Claude Code CLI
- NVIDIA GPUs (optional — works without, just no GPU passthrough)
- npm (optional — for the log viewer web UI)

## How it works

Each Claude session follows a strict protocol:

1. **Orient** — Read state files (journal, summary, plan, next action)
2. **Scope** — Pick ONE objective for the session
3. **Work** — Code, experiment, analyze (exploration in `playground/`, stable code in `src/`)
4. **Report** — Write a research diary entry with plots and analysis
5. **Commit** — Git commit all changes
6. **Handoff** — Update journal, write next action for the following session

State is managed through simple markdown files that serve as cross-session memory. The journal compresses automatically when it gets too long.

## Project structure (generated)

```
your-project/
├── README.md              # Project description, research goal, directions
├── CLAUDE.md              # Hard rules for the agent (~20 lines)
├── protocol.md            # Session protocol + evaluation framework (immutable)
├── Dockerfile             # Ubuntu + uv + Claude CLI + tmux + vim
├── docker-compose.yml     # Container config with GPU access
├── pyproject.toml         # Python project (managed by uv)
├── loop.sh                # Session chainer (runs inside container)
├── scripts/               # Control scripts
├── tools/
│   └── viewer/            # Log viewer web UI (Express.js)
├── state/                 # Cross-session memory
│   ├── summary.md         # Compressed history (long-term memory)
│   ├── journal.md         # Recent session logs (working memory)
│   ├── next_action.md     # Next session instructions
│   └── plan.md            # Research roadmap
├── playground/            # Exploration sessions (session-NN-slug/)
├── src/                   # Reusable research code
├── tests/                 # Tests for src/
├── data/                  # Datasets
├── checkpoints/           # Model checkpoints
├── reports/               # Session reports with figures (research diary)
│   └── figures/           # Plots and visualizations
├── results/               # Evaluation results (JSON)
├── notes/                 # Research notes
└── logs/                  # Session logs (text + JSON)
```

## License

MIT
