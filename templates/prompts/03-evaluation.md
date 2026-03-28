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

Maintain a results summary table in `notes/results_comparison.md`:
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
