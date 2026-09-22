# v1.0.0 public-release checklist

This checklist is for the first public GitHub/Zenodo release.

## Data and numerical reproduction

- [ ] Confirm `Figure1_analysis_ready.mat` is present in `data/analysis_ready/`.
- [ ] Confirm `Figures2to4_analysis_ready.mat` is present in `data/analysis_ready/`.
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

## Licensing and attribution

- [ ] Confirm with the study authors/institution that the deposited research materials can be released under CC BY 4.0.
- [ ] Confirm that the MATLAB source code can be released under the MIT License.
- [ ] Confirm the author list/order in `CITATION.cff` with the coauthors.
- [ ] Confirm no third-party material requiring a different license is included.

## Repository hygiene

- [ ] Confirm the six released `.xlsx` files were cleaned with Excel Document Inspector and no unnecessary local-folder metadata remains.
- [ ] Confirm there are no credentials, personal information, private/raw acquisition files, or unrelated laboratory files.
- [ ] Search for obsolete local Windows paths and unresolved placeholders other than the intentionally pending Zenodo DOI.
- [ ] Run `update_manifest_sha256` after all final changes.
- [ ] Confirm `MANIFEST_SHA256.txt` includes both released analysis-ready MAT files and the cleaned workbooks.

## v1.0.0 metadata

- [x] `VERSION` is `v1.0.0`.
- [x] `CITATION.cff` version is `1.0.0`.
- [x] `CITATION.cff` contains the GitHub repository URL.
- [x] `CITATION.cff` contains `date-released: 2026-09-22`.
- [ ] If the actual public release date differs from 2026-09-22, update `date-released` and the README before creating the release.
- [ ] Commit and push the v1.0.0 preparation changes while the repository is still private.
- [ ] Change the GitHub repository visibility from Private to Public.
- [ ] In Zenodo, run `Sync now`, enable `correction-collar-optimization-reproducibility`, and confirm the repository is enabled for archiving.
- [ ] On GitHub, create the `v1.0.0` release/tag only **after** Zenodo integration is enabled.
- [ ] Confirm that Zenodo archives the release and assigns a DOI.

## After Zenodo assigns the DOI

- [ ] Add the Zenodo DOI to `README.md`.
- [ ] Add the Zenodo DOI to `CITATION.cff`.
- [ ] Insert the Zenodo DOI into `docs/DATA_CODE_AVAILABILITY.md` and the manuscript.
- [ ] Commit/push these metadata-only updates.
- [ ] If desired, create a small metadata-only patch release only when necessary; the archived v1.0.0 record itself remains the immutable first release.

## After article acceptance/publication

- [ ] Add the article as `preferred-citation` in `CITATION.cff`.
- [ ] Add the final article citation and DOI to `README.md`.
- [ ] Add the article DOI as a related identifier in Zenodo.
