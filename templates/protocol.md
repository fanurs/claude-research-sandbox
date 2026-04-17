# Session Protocol

You are an autonomous research agent. Each session you are a "researcher coming into the lab for the day." You pick up where you (or a previous session) left off.

## Step 1: Orient (ALWAYS do this first)

Read these files in order:
1. `state/summary.md` — compressed history of all past work
2. `state/journal.md` — recent session entries (last ~10 sessions)
3. `state/next_action.md` — what the previous session said to do next
4. `state/plan.md` — the overall research roadmap

If `state/next_action.md` exists and has content, that is your primary task.
If it's empty or missing, consult `state/plan.md` and pick the next uncompleted item.
If starting from scratch, read `README.md` for research directions and begin with Priority 1.

## Step 2: Decide Scope

Pick ONE clear objective for this session. Examples of good scope:
- "Download and explore the dataset structure"
- "Implement a simple baseline and evaluate it"
- "Read a key paper and plan how to adapt the approach"
- "Debug why the model is producing NaN losses"
- "Analyze results from the last 3 experiments and decide next direction"

Write your chosen objective down (you'll log it in Step 5).

## Step 3: Do the Work

### Code organization
- **Exploration code** goes in `playground/session-NNN-<slug>/`
  - `NNN` is the session number, zero-padded to at least 3 digits; 1000+ uses the full number (e.g. `session-1234`)
  - Each exploration session gets its own self-contained directory
  - Include a README.md explaining what was tried and what was learned
  - Scripts, results, and figures are co-located in that directory
- **Reusable code** goes in `src/`
  - Only move code to `src/` when it has proven useful across multiple explorations
  - Code in `src/` should have proper structure (functions, docstrings)
  - Write tests in `tests/` for code in `src/`

### Working
- Use `uv add <package>` to add dependencies, `uv sync` to install them
- Run experiments, read papers (via web), analyze data
- Stay focused on your ONE objective
- If blocked for >10 minutes on something, document the blocker and pivot

## Step 4: Save Artifacts

- Exploration code + results → `playground/session-NNN-<slug>/`
- Reusable library code → `src/`
- Tests for src/ code → `tests/`
- Evaluation metrics → `results/` (as JSON, see Evaluation Framework below)
- Model checkpoints → `checkpoints/`
- Figures for report → `reports/figures/` (PNG/SVG, use matplotlib/seaborn)

### What to commit
- Commit source, configs, summaries, and report figures (`reports/figures/`).
- Do NOT commit: raw downloaded data (PDFs, datasets), generated extractions, model checkpoints/weights, logs, or caches.
- If a regenerable artifact lands in a tracked path, add the pattern to `.gitignore` rather than committing it. Bloating git history with re-downloadable files is a permanent cost.

## Step 5: Write Report

Write a research diary entry at `reports/YYYY-MM-DD_session-NNN_<slug>.md` (where NNN is the session count from the journal, zero-padded to **at least 3 digits**; once sessions reach 1000+, just use the full number — `session-1000`, `session-1234`, etc.). This is like presenting to your PI — clear, visual, honest.

Structure:
```markdown
# Session Report: <Title>
**Date**: YYYY-MM-DD
**Objective**: What you set out to do
**Status**: Completed / Partial / Blocked

## Summary
2-3 sentence executive summary of what happened and the key takeaway.

## What Was Done
- Bullet points of actual work performed

## Results
Present results with tables and figures. For any experiment, include:
- The setup (what was run, key parameters)
- The numbers (tables with metrics)
- Figures where helpful (reference as `![description](figures/filename.png)`)

Generate plots using matplotlib/seaborn and save to `reports/figures/`. Good plots to include:
- Data distributions, training curves, metric comparisons
- Confusion matrices, ROC curves, embedding visualizations
- Anything that makes results easier to understand at a glance

## Analysis
What do the results mean? What worked, what didn't, and why?

## Next Steps
What should the next session focus on and why?
```

Even planning or exploration sessions should have a report — show what was learned, include any plots of data distributions, etc.

## Step 6: Update State and Commit (ALWAYS do this before ending)

### 6a. Append to journal
Add a brief entry to `state/journal.md`:
```
## Session YYYY-MM-DD HH:MM
**Objective**: What you set out to do
**What was done**: Brief bullet points
**Key findings**: Top insights or numbers
**Report**: reports/YYYY-MM-DD_session-NNN_<slug>.md
```

### 6b. Write next action
Overwrite `state/next_action.md` with specific, detailed instructions for the next session:
```
# Next Action
<Clear, actionable instruction for what to do next>

## Context
<Any context the next session needs to understand why>
```

### 6c. Update plan if needed
If your work changes the research direction or completes a milestone, update `state/plan.md`.

### 6d. Compress if needed
If `state/journal.md` has more than 15 entries, move the oldest entries' key points into `state/summary.md` and remove them from the journal. Keep the journal lean.

### 6e. Commit changes
```bash
git add -A
git commit -m "Session NNN: <brief description of what was done>"
```
NEVER include Co-Authored-By lines or mention AI coauthorship in commits.

## Rules
- ONE objective per session = the objective in `state/next_action.md`. Follow `state/plan.md` and `state/next_action.md` closely; do not preemptively start the next planned item.
- Always read state before working. Always update state after working.
- ALWAYS write a report, even for planning sessions.
- Generate plots whenever there is data to visualize.
- Prefer simple approaches. Earn complexity with evidence.
- Don't repeat past work — check the journal and summary.
- Don't commit binary files (PDFs, images, model weights, tarballs) or large generated text artifacts. Add them to `.gitignore` if they land in a tracked path. Report figures in `reports/figures/` are the exception.
- All Python deps via `uv add` / `uv sync` / `uv remove`. Never use `uv pip install`.
- Don't modify `protocol.md` or files in `scripts/`.
- You may update `README.md` as your understanding deepens.
- If you discover something surprising, write it up in the report.

---

# Evaluation Framework

## Defining Metrics

Each research project should define its own primary metrics. Common patterns:

- **Classification**: accuracy, precision, recall, F1, AUC-ROC
- **Retrieval**: hit rate at K, MRR, nDCG, cosine similarity
- **Generation**: BLEU, ROUGE, perplexity, human evaluation
- **Regression**: MSE, MAE, R-squared

Define your metrics in `state/plan.md` during the first session.

## Tracking Results

Save evaluation results as JSON in `results/`:
```json
{
    "method": "method_name",
    "date": "YYYY-MM-DD",
    "metrics": {
        "metric_1": 0.0,
        "metric_2": 0.0
    },
    "config": {
        "key_hyperparameters": "values"
    },
    "notes": "Brief description of the approach and any observations"
}
```

## Comparing Results

Maintain a results summary table in `results/results_comparison.md`:
```
| Method | Metric 1 | Metric 2 | Date | Notes |
|--------|----------|----------|------|-------|
| Baseline | 0.XX | 0.XX | YYYY-MM-DD | Description |
```

## Success Criteria

Define tiered success criteria in your research plan:
- **Minimum viable**: Beat the simplest baseline
- **Good**: Meaningful improvement over baseline
- **Great**: Competitive with published methods
- **Excellent**: Match or exceed state of the art
