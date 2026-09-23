# v1.0.1 release checklist — align with final no-LME manuscript

- [ ] Confirm the current `README.md` explicitly excludes exploratory LME/LMM from the manuscript scope.
- [ ] Confirm `reproduce_Figure4_results` defaults to `RunLME=false`.
- [ ] Confirm `run_all_reproductions` explicitly passes `RunLME=false`.
- [x] Run `setup_repository; run_all_reproductions; validate_against_verified`. On 2026-09-23, **13/13 PASS**; historical LME was not run. Existing old LME CSVs in the output directory were reported as historical-only.
- [ ] Confirm the two historical LME CSVs remain in `results/verified_key_outputs/` and historical Excel sheets are unchanged.
- [ ] Confirm neither README nor Data and code availability claims original OIR acquisition files are lost or permanently unavailable.
- [ ] Confirm two released analysis-ready MAT files and all six cleaned source-data Excel workbooks remain in the local GitHub clone. The downloadable patch deliberately does **not** replace them.
- [ ] Run `update_manifest_sha256` in the actual local clone **after** all patch files and real data are in place.
- [ ] Commit and push no-LME changes to `main`; verify README, VERSION and CITATION.cff in GitHub.
- [ ] Keep GitHub/Zenodo historical v1.0.0 as an immutable historical version; update its Zenodo **description metadata** to clearly flag supersession if appropriate, without modifying its archived ZIP or DOI.
- [x] Keep Zenodo GitHub sync **ON**. GitHub tag/release `v1.0.1` was published with no-LME release notes.
- [x] Zenodo archived v1.0.1 under the existing version family; version-specific DOI: **10.5281/zenodo.22913943**.
- [ ] Apply this post-release documentation patch to GitHub main README/CITATION and the manuscript availability statement; do not move or rewrite the already published tag.
- [ ] Provide the actual GitHub release and Zenodo record links to the supervisor for final confirmation.
