# Reproducibility package for image-based correction-collar optimization over time in in vivo two-photon microscopy

Historical v1.0.0 archive: [10.5281/zenodo.22885339](https://doi.org/10.5281/zenodo.22885339). **This archived version includes exploratory LME analysis and is not the current no-LME manuscript release.** The updated no-LME v1.0.1 archive will receive its own DOI after release.

This repository contains the compact analysis-ready datasets, MATLAB code, released source-data workbooks, verified reference outputs, and figure-panel generation scripts associated with the manuscript:

**Gohma A, Ue Y, Miyawaki A, Monai H. _Image-Based Correction-Collar Optimization over Time in In Vivo Two-Photon Microscopy._**

Current manuscript scope: **v1.0.1 (no LME; release preparation)**. The earlier v1.0.0 release remains available solely as a historical record.

The numerical workflow starts from **normalized measured image-score profiles at the sampled correction-collar angles** and recalculates the principal derived quantities and statistical results. It does not use previously calculated θopt, W95, relative fitted score, or DiffMAD as numerical inputs.

## What this repository reproduces

The public workflow covers the numerical results underlying Figures 1–4 and the associated supplementary analyses, including:

- cubic image-score fitting and R²;
- fitted optimum and operational θopt;
- W95, defined as the angular width over which the fitted score remains at least 95% of the fitted maximum;
- relative fitted score at an initial or reference angle;
- depth- and isoflurane-condition summaries;
- DiffMAD from signed first differences of operational θopt;
- Friedman tests, Wilcoxon signed-rank post-hoc tests, and Benjamini–Hochberg correction;
- Spearman associations;
- W95-adjusted residual analysis.

**The current manuscript does not report linear mixed-effects models (LME/LMM).** Historical LME code and output files are retained for provenance only; they are excluded from the default reproduction, current-manuscript validation, and manuscript claims. The old LME has not been revalidated as part of this no-LME release.

The repository also regenerates the **data-driven figure panels** for the main and supplementary figures. Conceptual artwork and final multi-panel composition were assembled separately in Adobe Illustrator and are intentionally kept separate from numerical reproduction.

## Repository structure

```text
.
├─ README.md
├─ CITATION.cff
├─ LICENSE
├─ LICENSE_DATA.md
├─ VERSION
├─ setup_repository.m
├─ code/
│  ├─ run_all_reproductions.m
│  ├─ validate_against_verified.m
│  ├─ generate_all_main_figure_panels.m
│  ├─ generate_all_supplementary_figure_panels.m
│  ├─ builders/
│  │  ├─ build_Figure1_analysis_ready.m
│  │  └─ build_Figures2to4_analysis_ready.m
│  ├─ reproduction/
│  │  ├─ reproduce_Figure1_results.m
│  │  ├─ reproduce_Figure2_results.m
│  │  ├─ reproduce_Figure3_results.m
│  │  └─ reproduce_Figure4_results.m
│  ├─ figure_generation/
│  │  ├─ generate_Figure1_panels.m
│  │  ├─ generate_Figure2_panels.m
│  │  ├─ generate_Figure3_panels.m
│  │  ├─ generate_Figure4_panels.m
│  │  ├─ generate_FigureS1_panels.m
│  │  ├─ generate_FigureS2_panels.m
│  │  ├─ generate_FigureS3_panels.m
│  │  ├─ generate_FigureS4_panels.m
│  │  ├─ generate_FigureS5_panels.m
│  │  └─ generate_FigureS6_panels.m
│  ├─ functions/+ccrepro/
│  │  └─ shared fitting/statistical utilities
│  ├─ functions/+ccplot/
│  │  └─ shared plotting/export utilities
│  └─ verified_standalone/
│     └─ standalone scripts retained as an audit trail
├─ data/
│  ├─ analysis_ready/
│  │  ├─ Figure1_analysis_ready.mat
│  │  ├─ Figures2to4_analysis_ready.mat
│  │  └─ metadata CSV files
│  └─ source_data/
│     └─ source-data and supplementary-table workbooks
├─ results/
│  └─ verified_key_outputs/
│     └─ selected CSV outputs used as numerical references
└─ docs/
   ├─ ANALYSIS_DEFINITIONS.md
   ├─ DATA_DICTIONARY.md
   ├─ OUTPUT_MAP.md
   ├─ FIGURE_GENERATION.md
   ├─ SUPPLEMENTARY_FIGURE_MAP.md
   ├─ DATA_CODE_AVAILABILITY.md
   ├─ VALIDATION_STATUS.md
   └─ README_JA.md
```

## Software requirements

The analyses were developed and verified using:

- MATLAB R2024b Update 2 (24.2.0.2773142)
- Statistics and Machine Learning Toolbox 24.2
- Windows

The Statistics and Machine Learning Toolbox is required for functions including `friedman` and `signrank`. `fitlme` is needed only if a user explicitly runs the historical, non-manuscript LME.

## Quick start: reproduce the numerical results

1. Ensure that the following released analysis-ready MAT files are present in `data/analysis_ready/`:

```text
Figure1_analysis_ready.mat
Figures2to4_analysis_ready.mat
```

2. Start MATLAB in the repository root and run:

```matlab
setup_repository
run_all_reproductions
```

3. Reproduced numerical outputs will be written under:

```text
results/reproduced/Figure1
results/reproduced/Figure2
results/reproduced/Figure3
results/reproduced/Figure4
```

4. Compare selected outputs against the verified reference CSVs:

```matlab
validate_against_verified
```

The previous v1.0.0 workflow produced **15/15 PASS** for its then-selected reference outputs, including two historical LME files. The **current no-LME validation covers 13 selected comparisons**. Run `run_all_reproductions` followed by `validate_against_verified` in this release; record the new result in `docs/VALIDATION_STATUS.md` only after checking MATLAB output.

## Generate figure panels

Main data-driven panels:

```matlab
setup_repository
generate_all_main_figure_panels
```

Supplementary figures S1–S6:

```matlab
generate_all_supplementary_figure_panels
```

Generated SVG and PNG files are written below `results/figure_panels/`.

The panel-generation scripts are intentionally **visualization-only** whenever possible: they read the released source-data workbooks and do not rerun the main hypothesis tests. This keeps numerical reproduction separate from presentation.

### Panels intentionally not regenerated

The following main-figure panels are conceptual or image-based rather than numerical MATLAB panels:

- Figure 1A–B: conceptual / experimental-design artwork
- Figure 1C: representative fluorescence images; the compact repository contains selection metadata but not the raw image assets
- Figure 2A: conceptual / experimental-design artwork
- Figure 3A: conceptual artwork
- Figure 4A–B: conceptual artwork

All supplementary figures S1–S6 are data-driven and are regenerated from released source-data records.

See `docs/FIGURE_GENERATION.md` and `docs/SUPPLEMENTARY_FIGURE_MAP.md` for panel-level details.

## Analysis-ready data and source-data workbooks serve different roles

The numerical-reproduction scripts start from compact analysis-ready MAT files:

```text
normalized measured image score
        ↓
analysis-ready MAT dataset
        ↓
numerical reproduction code
        ↓
recomputed derived quantities and statistics
        ↓
comparison with verified outputs
```

The figure-generation scripts instead use the released source-data workbooks:

```text
released source-data workbooks
        ↓
figure-panel generation code
        ↓
individual SVG / PNG data panels
        ↓
manual final multi-panel composition where applicable
```

The source-data workbooks are therefore validation and plotting records, not numerical inputs to `run_all_reproductions`.

## Core analysis conventions

The shared implementation follows the manuscript definitions:

- Each measured image-score profile is normalized to its largest measured value at that time point.
- A cubic polynomial is fitted in sampled-angle **index space**.
- The fit is evaluated on a fine grid with step `0.01` sampled-angle index units, corresponding to `0.02°` when sampled angles are separated by `2°`.
- The fitted optimum is the maximum of the fine-grid fitted curve.
- For the operational θopt used in Figures 1, 2, and 4:
  - if the highest measured image score occurs at an interior sampled angle, the fitted optimum is used;
  - if the highest measured image score occurs at either scan boundary, the corresponding sampled boundary angle is retained;
  - θopt is invalid when `R² <= 0.70`.
- A boundary hit is defined from the location of the **highest measured image score**, not from the fitted optimum.
- W95 is calculated from the fitted curve and summarized independently of the R²-based θopt validity mask.
- For Figure 3, θref is the first valid **fitted optimum** at 200 µm under 1% isoflurane, before operational boundary-angle substitution.
- DiffMAD is the median absolute deviation of the **signed** first-difference series of operational θopt.
- Under the 0% condition, the three noncontiguous 10-measurement blocks are treated as separate segments; first differences and consecutive-run calculations do not cross segment boundaries.
- Historical mixed-effects-model code is retained but is **not run by default** and is **not part of the current manuscript**.

See `docs/ANALYSIS_DEFINITIONS.md` for full operational definitions.

## Experimental subsets represented in the compact analysis-ready data

### Figure 1

- 7 experiments
- 200 µm below the pia
- 2% isoflurane
- first 30 measurements
- 14 sampled correction-collar angles per measurement

### Figures 2–4

A separate cohort of 7 experiments was analyzed at 200, 250, and 300 µm under four isoflurane conditions. Each condition contributes 30 measurements:

- `Ane0`: original measurement indices 1–10, 61–70, and 121–130
- `Ane1`: 31–60
- `Ane2`: 91–120
- `Ane3`: 150–179

The 0% condition denotes **isoflurane-off observation periods**. An awake state was not verified behaviorally or by EEG.

## Public terminology and the legacy term `Peak-F`

The accompanying manuscript uses descriptive public-facing terms such as **spatial-frequency-based image score**, **measured image score**, and **normalized image score**. The same score was called **Peak-F** in the previously published method and in the original analysis code.

For traceability, some legacy file names, variable names, and internal function names in this repository still contain `PeakF` or `peakf`. Unless explicitly stated otherwise, these names refer to the same spatial-frequency-based image score defined in the manuscript.

## Building the analysis-ready datasets

The builder scripts are provided for users who have the processed image-score MAT files used during manuscript preparation:

```matlab
build_Figure1_analysis_ready(inputDir, outputDir)
build_Figures2to4_analysis_ready(inputDir, outputDir)
```

The builders retain normalized measured image-score profiles and essential metadata. Previously calculated θopt, R², W95, relative fitted scores, DiffMAD, and statistical outputs are not copied into the compact analysis-ready datasets.

The builders are not required when the released analysis-ready MAT files are already present.

## Data naming

`experiment_id` is used rather than `mouse_id` because identifiers such as `20231108_data1` are experiment/acquisition identifiers.

Public-facing derived-variable terminology follows the manuscript, including:

- `thetaopt_deg`
- `theta_ref_deg`
- `W95_deg`
- `relative_fitted_score`
- `Diff_MAD` / DiffMAD
- `valid_fit_rate`
- `boundary_hit_rate`

## Raw images and acquisition files

The compact reproduction package does not require the original TIFF or OIR files for any reported numerical analysis. The TIFF-converted images used for image analysis are available from the corresponding author upon reasonable request. The original OIR files are not part of this compact deposit; their availability has not been established.

Figure 1C requires representative fluorescence images. The released source-data workbook records the exact experiment, time points, and collar angles used for that panel, but the representative raw fluorescence-image assets themselves are not included in the compact repository.

## Validation status

The Figure 1–4 numerical pipeline was first checked with standalone scripts and then refactored into shared functions. The refactored repository workflow was subsequently executed end-to-end and compared against selected verified reference outputs.

The earlier v1.0.0 workflow passed 15 selected comparisons, **including two historical LME outputs**. The present no-LME workflow has 13 default comparisons and requires a fresh MATLAB check before publishing v1.0.1. Main-figure data-panel generators and Supplementary Figure S1–S6 generators were executed successfully and visually checked during prior preparation.

See `docs/VALIDATION_STATUS.md` for details.

## Citation

`CITATION.cff` identifies the current no-LME version (v1.0.1). Its version-specific Zenodo DOI will be added **after** the v1.0.1 GitHub release is archived. Until then, do not cite the older v1.0.0 DOI as the archive for the final manuscript.

Historical v1.0.0 archive: https://doi.org/10.5281/zenodo.22885339 (includes exploratory LME materials; not the current manuscript release).

Zenodo concept DOI for all versions: https://doi.org/10.5281/zenodo.22885338 (will resolve to the latest version after archiving).

For manuscript-specific reproducibility, cite the **new v1.0.1 version DOI** once Zenodo assigns it. See `docs/DOI_AND_CITATION.md` and `docs/HISTORICAL_LME.md`.

## License

This repository uses separate licenses for software and research materials:

- **MATLAB source code:** MIT License (`LICENSE`)
- **Data, verified outputs, documentation, and generated data-panel artwork:** Creative Commons Attribution 4.0 International, CC BY 4.0 (`LICENSE_DATA.md`)

Third-party software such as MATLAB is not redistributed or licensed by this repository.

## Data and code availability

The manuscript-ready wording is maintained in `docs/DATA_CODE_AVAILABILITY.md`. It contains the public GitHub repository URL and a placeholder for the new no-LME v1.0.1 version-specific Zenodo DOI.

## MATLAB path troubleshooting

`setup_repository` adds the repository paths and verifies resolution of the shared package functions. MATLAB should print the repository root and the resolved location of `ccrepro.get_param`.

You can check this manually with:

```matlab
which ccrepro.get_param -all
```

If path resolution fails, from the repository root run:

```matlab
restoredefaultpath
rehash toolboxcache
setup_repository(pwd)
which ccrepro.get_param -all
```

`restoredefaultpath` removes custom MATLAB paths for the current MATLAB session, so re-add unrelated custom paths afterward if needed.

## Persistent identifiers

GitHub repository:

```text
https://github.com/aoigohma/correction-collar-optimization-reproducibility
```

Current planned release: `v1.0.1` (no LME).

Current v1.0.1 version-specific Zenodo DOI: **pending Zenodo archiving**.

Historical v1.0.0 DOI (not the current manuscript release):

```text
https://doi.org/10.5281/zenodo.22885339
```

Zenodo concept DOI for all versions:

```text
https://doi.org/10.5281/zenodo.22885338
```
