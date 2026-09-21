# Shared MATLAB functions

The `+ccrepro` package centralizes analysis logic reused by multiple figure-reproduction scripts.

Key shared functions include:

- `fit_peakf_series` — cubic fitting, R², measured boundary detection, fitted optimum, operational θopt, W95;
- `relative_fitted_score` — evaluation of a target fitted curve at a fixed reference angle;
- `complete_matrix` / `friedman_p` — repeated-measures table preparation and Friedman test;
- `bh_fdr` — Benjamini–Hochberg adjusted q values;
- `centered_prctile` / `prctile_finite` — finite-value percentile helpers;
- `mad1` — unscaled median absolute deviation;
- `longest_run` — threshold-event run length respecting segment boundaries.

The standalone verified scripts are retained separately under `code/verified_standalone/` for auditability.
