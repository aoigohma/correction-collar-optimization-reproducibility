# Supplementary figure mapping and generation plan

This document maps each supplementary figure to the released workbook sheets and the MATLAB generator script used in the public repository.

## Scope

The current manuscript uses six supplementary figures:

- **Fig. S1**: supplementary quality-control summary for the baseline condition used in Figure 1 and Table S1.
- **Fig. S2**: mouse-level relative fitted-score time series for the Figure 3 depth-transfer analysis.
- **Fig. S3**: mouse-level relative fitted-score time series for the Figure 3 isoflurane-transfer analysis.
- **Fig. S4**: sensitivity analysis using a relative fitted-score threshold of 0.98.
- **Fig. S5**: associations between DiffMAD and curve-quality metrics.
- **Fig. S6**: mean W95 by depth and DiffMAD residuals after accounting for mean W95.

No supplementary figure contains conceptual artwork only. All six are therefore treated as MATLAB-regenerable, data-driven figures.

## Mapping table

| Supplementary figure | Panel(s) | Content | Released source-data sheet(s) | Generator script | Output file |
|---|---|---|---|---|---|
| Fig. S1 | A | Maximum absolute deviation from initial θopt | `Supplementary_TableS1_Figure1.xlsx` → `TableS1_individual` | `generate_FigureS1_panels.m` | `results/figure_panels/Supplementary/FigureS1/FigureS1_panels.svg` |
| Fig. S1 | B | Initial-angle outside-W95 rate and relative-fitted-score < 0.95 rate | `Supplementary_TableS1_Figure1.xlsx` → `TableS1_individual` | `generate_FigureS1_panels.m` | same as above |
| Fig. S1 | C | Mean R² | `Supplementary_TableS1_Figure1.xlsx` → `TableS1_individual` | `generate_FigureS1_panels.m` | same as above |
| Fig. S1 | D | Valid-fit rate and boundary-hit rate | `Supplementary_TableS1_Figure1.xlsx` → `TableS1_individual` | `generate_FigureS1_panels.m` | same as above |
| Fig. S2 | single composite | Mouse-level relative fitted-score time series for depth transfer | `SourceData_Figure3.xlsx` → `Supp_S2_depth_TS_all` | `generate_FigureS2_panels.m` | `results/figure_panels/Supplementary/FigureS2/FigureS2_depth_transfer_all_mice.svg` |
| Fig. S3 | single composite | Mouse-level relative fitted-score time series for isoflurane transfer | `SourceData_Figure3.xlsx` → `Supp_S3_iso_TS_all` | `generate_FigureS3_panels.m` | `results/figure_panels/Supplementary/FigureS3/FigureS3_isoflurane_transfer_all_mice.svg` |
| Fig. S4 | A–D | 0.98-threshold sensitivity analysis: fractions and longest runs for depth transfer and isoflurane transfer | `SourceData_Figure3.xlsx` → `Raw_time_level` (mouse-level event summaries recomputed at threshold 0.98) | `generate_FigureS4_panels.m` | `results/figure_panels/Supplementary/FigureS4/FigureS4_sensitivity_0p98.svg` |
| Fig. S5 | A–C | DiffMAD versus mean R², valid-fit rate, boundary-hit rate | `SourceData_Figure4.xlsx` → `F_right_W95`, `S_Spearman` | `generate_FigureS5_panels.m` | `results/figure_panels/Supplementary/FigureS5/FigureS5_quality_metric_associations.svg` |
| Fig. S6 | A | Mean W95 by depth | `SourceData_Figure4.xlsx` → `F_right_W95` | `generate_FigureS6_panels.m` | `results/figure_panels/Supplementary/FigureS6/FigureS6_W95_and_residuals.svg` |
| Fig. S6 | B | DiffMAD residuals after accounting for mean W95, compared across depth within each isoflurane condition | `SourceData_Figure4.xlsx` → `F_right_W95`, `S_W95_resid` | `generate_FigureS6_panels.m` | same as above |

## Notes

### Fig. S4 threshold handling

The released workbook includes manuscript-level 0.98 summaries (`Supp_S4_depth_0p98`, `Supp_S4_iso_0p98`), but the plotted mouse-level distributions require re-derivation from the released time-level table. Therefore `generate_FigureS4_panels.m` recomputes:

- number of valid time points,
- number and fraction below 0.98,
- longest consecutive run below 0.98.

This matches the policy already used in the main Figure 3 generators, while keeping the plotted left-column quantities as **fractions**, not percentages.

### Relationship to main figures

- **Fig. S2/S3** expand the representative time-series panels in Figure 3C/F to all mice.
- **Fig. S4** is a sensitivity counterpart to Figure 3D/G.
- **Fig. S5/S6** extend the Figure 4 analyses using released quality metrics and residualized DiffMAD values.

## Recommended execution order

From the repository root in MATLAB:

```matlab
setup_repository
generate_all_supplementary_figure_panels
```

Or run one figure at a time:

```matlab
generate_FigureS1_panels
generate_FigureS2_panels
generate_FigureS3_panels
generate_FigureS4_panels
generate_FigureS5_panels
generate_FigureS6_panels
```
