# Pre-release checklist

Before public deposition / GitHub v1.0.0 release:

## Data and numerical reproduction

- [ ] Add `Figure1_analysis_ready.mat` to `data/analysis_ready/`.
- [ ] Add `Figures2to4_analysis_ready.mat` to `data/analysis_ready/`.
- [ ] Confirm metadata CSVs correspond exactly to the released MAT files.
- [ ] Run `setup_repository`.
- [ ] Run `run_all_reproductions`.
- [ ] Run `validate_against_verified` and confirm all 15 listed outputs report `PASS` with `MaxNumericAbsDiff = 0`.
- [ ] Confirm `Figure4_LME_model_comparison.csv` contains exactly two likelihood-ratio comparison rows.
- [ ] Confirm `experiment_id` terminology is used in public-facing tables and documentation.
- [ ] Confirm the 0% condition is described as isoflurane-off, not as verified awake.

## Figure-panel generation

- [ ] Run `generate_all_main_figure_panels`.
- [ ] Confirm Figure 1 D–H export successfully; confirm the Figure 1C metadata note is created. Figure 1A–B are conceptual Illustrator artwork and are intentionally not generated.
- [ ] Confirm Figure 2 B–G export successfully. Figure 2A is conceptual Illustrator artwork.
- [ ] Confirm Figure 3 B–G export successfully. Figure 3A is conceptual Illustrator artwork.
- [ ] Confirm Figure 4 C–F export successfully. Figure 4A–B are conceptual Illustrator artwork.
- [ ] Run `generate_all_supplementary_figure_panels`.
- [ ] Confirm Supplementary Figures S1–S6 export successfully.
- [ ] Confirm Figure 3D/G and Supplementary Figure S4 event-frequency panels use mouse-level **fractions**, not percent-scaled values.
- [ ] Visually compare generated panels with the manuscript figures for axes, group ordering, representative experiment, thresholds, and legends.
- [ ] Keep final Illustrator-only composition/schematic work documented in `docs/FIGURE_GENERATION.md`.

## Licensing and attribution

- [ ] Confirm with the study authors/institution that the repository rightsholders are authorized to release the source-data workbooks and deposited research materials under CC BY 4.0.
- [ ] Confirm that the software can be released under the MIT License.
- [ ] Confirm the author list/order used in `CITATION.cff` with the coauthors.
- [ ] Confirm no third-party material requiring a different license is included.

## GitHub / Zenodo metadata

- [ ] Change `VERSION` to `v1.0.0` immediately before the first public release.
- [ ] Change the `version` field in `CITATION.cff` to `1.0.0`.
- [ ] Add the public GitHub URL to `CITATION.cff` as `repository-code`.
- [ ] Add the public release date to `CITATION.cff` as `date-released`.
- [ ] Create the GitHub `v1.0.0` release after enabling Zenodo integration.
- [ ] Add the resulting Zenodo DOI to `CITATION.cff` and `README.md` (or include it in the next metadata-only patch release if the DOI is assigned after the release is archived).
- [ ] Insert the final Zenodo DOI and GitHub URL into `docs/DATA_CODE_AVAILABILITY.md` and the manuscript.
- [ ] After the article receives its DOI, add the article to `CITATION.cff` as `preferred-citation`, and add the article DOI/journal metadata to README/Zenodo.

## Final repository hygiene

- [ ] Search the repository for unresolved placeholders such as `[ZENODO DOI]`, `TODO`, and obsolete local Windows paths.
- [ ] Confirm that released `.xlsx` files do not retain local-folder metadata such as Excel `x15ac:absPath`.
- [ ] Confirm that no private/raw acquisition files, credentials, personal information, or unrelated laboratory files are included.
- [ ] Run `update_manifest_sha256` after all final changes and confirm that `MANIFEST_SHA256.txt` includes the released analysis-ready MAT files.
