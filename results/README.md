# Results

`verified_key_outputs/` contains selected CSV outputs that were numerically checked against the manuscript source data during preparation of this repository package.

`results/reproduced/` is created by `run_all_reproductions.m` and is ignored by Git because those files are regenerated from the analysis-ready inputs.

## Figure-panel output

`generate_all_main_figure_panels` creates panel-level SVG/PNG artwork under `results/figure_panels/`. These files are generated from the released source-data workbooks and are separate from `results/reproduced/`, which contains numerically recomputed outputs from the analysis-ready MAT datasets.
