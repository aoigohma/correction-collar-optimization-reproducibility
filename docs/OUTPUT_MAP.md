# Output map

This document maps the main reproduction outputs to the **current no-LME manuscript**. Historical LME outputs are listed separately and are NOT manuscript results.

## Figure 1

Script: `reproduce_Figure1_results.m`

| Output | Main use |
|---|---|
| `Figure1_reproduced_time_level.csv` | Time-level θopt, R², boundary hit, W95, relative fitted score |
| `Figure1_reproduced_mouse_level.csv` | Experiment-level values corresponding to Figure 1H / Figure S1 / Table S1 |
| `Figure1_reproduced_group_summary.csv` | Group medians/IQRs reported in Results 3.1 |
| `Figure1_reproduced_representative_summary.csv` | Representative experiment checks |
| `Figure1_reproduced_results.mat` | MATLAB copy including fit details |

Figure 1C fluorescence images are outside the compact numerical reproduction workflow.

## Figure 2

Script: `reproduce_Figure2_results.m`

| Output | Main use |
|---|---|
| `Figure2_reproduced_time_level.csv` | Recomputed fit-derived time-level values |
| `Figure2_reproduced_mouse_level.csv` | Mean θopt, mean W95, mean R², valid-fit rate, boundary-hit rate |
| `Figure2_reproduced_group_summary.csv` | Descriptive medians/IQRs |
| `Figure2_stats_mean_theta_depth_within_iso.csv` | Final depth-effect family for mean θopt |
| `Figure2_stats_mean_theta_iso_within_depth.csv` | Final isoflurane-effect family for mean θopt |
| `Figure2_stats_W95_depth_within_iso.csv` | Final depth-effect family for mean W95 |

## Figure 3

Script: `reproduce_Figure3_results.m`

| Output | Main use |
|---|---|
| `Figure3_reference_angles.csv` | Per-experiment θref |
| `Figure3_depth_transfer_time_level.csv` | Time-level depth-transfer relative fitted scores |
| `Figure3_depth_transfer_mouse_level_0p95.csv` | Primary mouse-level depth-transfer metrics |
| `Figure3_depth_transfer_summary_0p95.csv` | Primary manuscript depth-transfer summary |
| `Figure3_depth_transfer_mouse_level_0p98.csv` | Sensitivity analysis |
| `Figure3_depth_transfer_summary_0p98.csv` | Sensitivity group summary |
| `Figure3_isoflurane_transfer_time_level.csv` | Time-level isoflurane-transfer scores |
| `Figure3_isoflurane_transfer_mouse_level_0p95.csv` | Primary mouse-level isoflurane-transfer metrics |
| `Figure3_isoflurane_transfer_summary_0p95.csv` | Primary manuscript isoflurane-transfer summary |
| `Figure3_isoflurane_transfer_mouse_level_0p98.csv` | Sensitivity analysis |
| `Figure3_isoflurane_transfer_summary_0p98.csv` | Sensitivity group summary |

No hypothesis tests are performed across Figure 3 target conditions.

## Figure 4

Script: `reproduce_Figure4_results.m`

| Output | Main use |
|---|---|
| `Figure4_DiffMAD_mouse_level.csv` | Experiment-condition-depth DiffMAD and quality metrics |
| `Figure4_stats_DiffMAD_depth_within_iso.csv` | Main Friedman/BH depth tests |
| `Figure4_stats_DiffMAD_posthoc_signedrank.csv` | Exploratory pairwise depth comparisons |
| `Figure4_depth_slopes.csv` | One slope per experiment × condition |
| `Figure4_mousewise_median_slopes.csv` | Per-experiment median slope across conditions |
| `Figure4_slope_summary.csv` | 26/28 positive-slope summary and group slope statistics |
| `Figure4_Spearman.csv` | Overall and subgroup descriptive associations |
| `Figure4_Spearman_overall.csv` | Overall associations used in the manuscript text/figures |
| `Figure4_W95_regression.csv` | Pooled simple DiffMAD ~ mean W95 model |
| `Figure4_W95_adjusted_residuals.csv` | Per-observation residuals |
| `Figure4_stats_W95_adjusted_residual_depth_within_iso.csv` | Residual depth tests and BH q values |
| `Figure4_LME_coefficients.csv` | HISTORICAL ONLY; optional, not a current-manuscript result |
| `Figure4_LME_model_comparison.csv` | HISTORICAL ONLY; optional, not a current-manuscript result |

The following historical output specification is retained for provenance only; it is **excluded from the current manuscript** and generated only with explicit `RunLME=true`. When produced, the historical compact LME comparison has exactly two rows:

1. Model 1 vs Model 2
2. Model 2 vs Model 3

The baseline rows returned by MATLAB `compare()` are intentionally omitted from the public CSV.

## Main figure-panel artwork

Run `generate_all_main_figure_panels` to create panel-level SVG/PNG files under `results/figure_panels/`.

- Figure 1: D, E, F, G, and H are generated. Panels A and B are conceptual artwork assembled manually in Adobe Illustrator. Panel C requires separately deposited fluorescence-image assets.
- Figure 2: B–G are generated. Panel A is conceptual Illustrator artwork and is intentionally omitted; the legacy development-stage panel H is also omitted.
- Figure 3: B–G are generated. Panel A is conceptual Illustrator artwork and is intentionally omitted.
- Figure 4: C–F are generated; panels A and B are conceptual Illustrator artwork and are intentionally omitted. Panel F is exported as a two-part group.

Supplementary figures contain no conceptual-only panels; supplementary panel-generation scripts, when added, should target all data-driven supplementary panels.

The final journal composite may be assembled manually in Adobe Illustrator. See `FIGURE_GENERATION.md`.
