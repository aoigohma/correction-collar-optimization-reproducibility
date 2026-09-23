# Validation status

During repository preparation, the complete shared-function numerical workflow was run end-to-end after placing the two analysis-ready MAT files in `data/analysis_ready/`.

Commands:

```matlab
clear functions
setup_repository
run_all_reproductions
validate_against_verified
```

Historical verification on 2026-09-22: all 15 then-selected comparisons reported `PASS`, with `MaxNumericAbsDiff = 0`; two compared files were exploratory LME outputs. These two historical files are **not part of the current manuscript**. For v1.0.1/no-LME, default validation compares **13 non-LME outputs**. The new 13/13 result has not yet been verified in MATLAB; update this statement only after a successful local run.

## Figure-generation validation

The main-figure and supplementary figure-generation scripts were also executed successfully during repository preparation.

### Main figures

- Figure 1 data-driven panels D–H: generated successfully and visually checked.
- Figure 1A–B: conceptual Illustrator artwork, intentionally not generated.
- Figure 1C: image-based panel; metadata are included but the representative fluorescence-image assets are not part of the compact repository.
- Figure 2 data-driven panels B–G: generated successfully and visually checked.
- Figure 3 data-driven panels B–G: generated successfully and visually checked; event-frequency panels use mouse-level fractions rather than percent-scaled values.
- Figure 4 data-driven panels C–F: generated successfully and visually checked.

### Supplementary figures

`generate_all_supplementary_figure_panels` completed successfully for Supplementary Figures S1–S6, producing SVG and PNG outputs for each figure. The generated figures were visually checked during repository preparation.

The figure-generation scripts should be interpreted as reproducible panel-level source artwork. Final multi-panel assembly, panel lettering, and conceptual artwork may be completed manually in Adobe Illustrator without altering the plotted numerical values.


### v1.0.1 current-manuscript verification (pending local MATLAB run)

The updated default validator compares **13** non-LME CSVs. The earlier 15/15 pass is a **historical result** and is not a verification of v1.0.1. Once the local no-LME code has been executed successfully, record the new result here. Historical LME statistics are not part of the manuscript.
