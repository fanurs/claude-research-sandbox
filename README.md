# research-sandbox

A Claude Code skill that creates autonomous research environments in Docker containers.

## What it does

`/research-sandbox` sets up a fully sandboxed, GPU-enabled research environment where Claude runs autonomously in a loop — each session tackles one research task, logs findings, and passes instructions to the next session. Like a researcher working day after day on a problem.

### Features

- **Docker sandbox**: All work happens inside a container with limited privileges
- **GPU access**: Automatic NVIDIA GPU detection and passthrough
- **Multi-session loop**: Claude sessions chain automatically via tmux
- **Cross-session memory**: Journal, summary, plan, and next-action files persist between sessions
- **JSON logging**: Every session produces structured logs
- **Safe controls**: Pause, resume, stop, cleanup scripts

## Install

```bash
git clone https://github.com/cteh/claude-research-sandbox ~/.claude/skills/research-sandbox
```

## Usage

In any project directory:

```
/research-sandbox
```

Claude will ask for your research question, set up the environment, and guide you through authentication. Then start the loop:

```bash
docker exec <project>-sandbox tmux new -d -s research /workspace/loop.sh
```

### Controls

| Action | Command |
|--------|---------|
| Watch the loop | `docker exec -it <project>-sandbox tmux attach -t research` |
| Stop after current session | `touch state/STOP` |
| Pause container | `./scripts/pause.sh` |
| Resume container | `./scripts/resume.sh` |
| Check status | `./scripts/status.sh` |
| Kill everything | `./scripts/cleanup.sh` |
| Shell into container | `./scripts/shell.sh` |

## Requirements

- Docker with nvidia-container-toolkit (for GPU support)
- Claude Code CLI
- NVIDIA GPUs (optional — works without, just no GPU passthrough)

## How it works

Each Claude session follows a strict protocol:

1. **Orient** — Read state files (journal, summary, plan, next action)
2. **Scope** — Pick ONE objective for the session
3. **Work** — Code, experiment, analyze
4. **Record** — Save artifacts, write notes
5. **Handoff** — Update journal, write next action for the following session

State is managed through simple markdown files that serve as cross-session memory. The journal compresses automatically when it gets too long.

## Project structure (generated)

```
your-project/
├── CLAUDE.md              # Project instructions for Claude
├── Dockerfile             # Ubuntu + uv + Claude CLI + tmux
├── docker-compose.yml     # Container config with GPU access
├── pyproject.toml         # Python project (managed by uv)
├── loop.sh                # Session chainer
├── scripts/               # Control scripts
├── prompts/               # Research context and protocol
│   ├── 00-context.md      # Problem background (generated)
│   ├── 01-research-directions.md  # Approaches (generated)
│   ├── 02-session-protocol.md     # Session protocol
│   └── 03-evaluation.md  # Evaluation framework
├── state/                 # Cross-session memory
│   ├── summary.md         # Compressed history
│   ├── journal.md         # Recent session logs
│   ├── next_action.md     # Next session instructions
│   └── plan.md            # Research roadmap
├── src/                   # Research code
├── data/                  # Datasets
├── checkpoints/           # Model checkpoints
├── results/               # Evaluation results
├── notes/                 # Research notes
└── logs/                  # Session logs (text + JSON)
```

## License

MIT
