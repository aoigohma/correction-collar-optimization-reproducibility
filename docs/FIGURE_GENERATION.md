# Figure-panel generation

## Purpose

The numerical reproduction and figure rendering are deliberately separated.

- `run_all_reproductions` starts from the compact analysis-ready MAT datasets and recalculates derived variables and statistics.
- `generate_all_main_figure_panels` reads the released source-data workbooks and renders the data-driven panels as SVG and PNG files.

The figure-generation scripts do **not** rerun hypothesis tests. Statistical annotations are read from the released source-data records when they are displayed.

## Run

From the repository root in MATLAB:

```matlab
setup_repository
generate_all_main_figure_panels
generate_all_supplementary_figure_panels
```

Or one figure at a time:

```matlab
generate_Figure1_panels
generate_Figure2_panels
generate_Figure3_panels
generate_Figure4_panels
generate_FigureS1_panels
generate_FigureS2_panels
generate_FigureS3_panels
generate_FigureS4_panels
generate_FigureS5_panels
generate_FigureS6_panels
```

Outputs are written under `results/figure_panels/`.

## Public terminology

Axis labels and panel text use manuscript-facing terminology such as **normalized image score** and **relative fitted score**. Some source-data column names still contain `peakf` or `retention` because they preserve the names used in the original analysis pipeline. Those names are treated only as legacy/internal terminology; values are not redefined during plotting.

## Figure 1

Panels A and B are **not generated**. They are conceptual/experimental-design artwork assembled manually in Adobe Illustrator and do not encode numerical results from the released source-data workbook.

Generated directly:

- D: representative normalized score-versus-angle curves
- E: representative normalized-score heatmap with θopt trajectory
- F: representative θopt time series with the W95 band
- G: relative fitted score at the initial angle
- H: mouse-level temporal range, mean W95, and minimum relative fitted score

Panel C is **not** regenerated because the compact repository does not contain the representative fluorescence-image assets. `1C_REQUIRES_RAW_IMAGES.txt` records this limitation and repeats the released metadata needed to select the correct images if the image assets are deposited separately.

## Figure 2

Panel A is **not generated**. It is conceptual/experimental-design artwork assembled manually in Adobe Illustrator.

Generated directly:

- B: representative score-versus-angle curves across depth, shown for each isoflurane condition
- C: representative score-versus-angle curves across isoflurane conditions, shown for each depth
- D: representative θopt time series for the 12 depth × isoflurane cells
- E: mouse-level mean θopt
- F: mouse-level mean W95
- G: mean R², valid-fit rate, and boundary-hit rate

The legacy panel H from early manuscript-development scripts is not generated because it is not part of the current main Figure 2.

## Figure 3

Panel A is **not generated**. It is conceptual artwork assembled manually in Adobe Illustrator.

Generated directly:

- B: depth-transfer mean and minimum relative fitted scores
- C: representative depth-transfer time series
- D: depth-transfer events below 0.95
- E: isoflurane-transfer mean and minimum relative fitted scores
- F: representative isoflurane-transfer time series
- G: isoflurane-transfer events below 0.95

## Figure 4

Panels A and B are **not generated**. They are conceptual artwork assembled manually in Adobe Illustrator.

Generated directly:

- C: representative θopt time series by depth
- D: representative |Δθopt| time series by depth
- E: DiffMAD depth comparisons within each isoflurane condition
- F left: depth-direction slopes of DiffMAD
- F right: DiffMAD versus mean W95, with the released pooled-regression line shown only as a visual guide and the released Spearman result annotated

## Supplementary figures

The supplementary figures contain no conceptual-only panels. In `v0.3.0-draft`, all currently used supplementary figures (S1-S6) are treated as data-driven and are regenerated directly from the released source-data workbooks.

Generated directly:

- S1: baseline-condition quality-control summary corresponding to Figure 1 / Table S1
- S2: all-mouse depth-transfer relative fitted-score time series
- S3: all-mouse isoflurane-transfer relative fitted-score time series
- S4: threshold-0.98 sensitivity analysis for Figure 3-type event summaries
- S5: DiffMAD associations with mean R², valid-fit rate, and boundary-hit rate
- S6: mean W95 by depth and DiffMAD residuals after accounting for mean W95

The detailed workbook-to-panel mapping is documented in `docs/SUPPLEMENTARY_FIGURE_MAP.md`.

## Final composition

The scripts export individual panel groups as SVG and PNG. The final submitted multi-panel figures may be assembled in Adobe Illustrator to control exact panel lettering, spacing, schematic artwork, and journal-specific layout. This manual assembly does not change the plotted numerical data.

The generated files should therefore be interpreted as **reproducible panel-level source artwork**, not as a guarantee of pixel-identical reconstruction of the final Illustrator composite.

### Figure 3 event fractions
For panels 3D (left) and 3G (left), the plotted mouse-level variable is `fraction_below_threshold` and is displayed as a 0–1 fraction, matching the publication figure. Percentages are used only in aggregate summary tables (`percent_below_threshold`).
