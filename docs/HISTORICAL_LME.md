# Historical LME: not included in the current manuscript

The final no-LME manuscript excludes the exploratory linear mixed-effects-model analysis. The earlier v1.0.0 release was archived on Zenodo at https://doi.org/10.5281/zenodo.22885339 and contains this historical analysis. The mixed-effects-model specification, code, reference CSVs, and historical Excel sheets are preserved solely to document the development process. **They are not analyses reported by the current manuscript and are not covered by its validation claim.**

## Current default

- `run_all_reproductions` explicitly calls `reproduce_Figure4_results(..., 'RunLME', false)`.
- Calling `reproduce_Figure4_results` without options also uses `RunLME = false`.
- `validate_against_verified` checks 13 key non-LME outputs by default.
- Historical `Figure4_LME_coefficients.csv` and `Figure4_LME_model_comparison.csv` remain in `results/verified_key_outputs/` and the historical sheets remain unchanged in the source workbooks.

## Optional historical re-execution — NOT manuscript validation

To inspect the earlier models, write to a distinct directory (do not mix historical and current outputs):

```matlab
setup_repository
reproduce_Figure4_results( ...
    fullfile(pwd, 'data', 'analysis_ready', 'Figures2to4_analysis_ready.mat'), ...
    fullfile(pwd, 'results', 'historical_LME_reproduced'), ...
    'RunLME', true)
```

The historical models were removed from the manuscript after a final audit raised an unresolved issue. Retaining the files must not be interpreted as endorsement, validation for the current manuscript, or a substitute for further review.
