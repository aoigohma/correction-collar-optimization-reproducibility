# Apply this patch to the existing GitHub clone — do not replace the repository

**This is a patch, not a complete repository.** Keep your existing two analysis-ready MAT files, six cleaned `.xlsx` workbooks, the original analysis scripts, and all historical results. Copy the *contents* of this patch folder into the existing cloned `correction-collar-optimization-reproducibility` folder, allowing files with the same names to be replaced.

## Before GitHub release

1. In MATLAB, set the *GitHub clone folder* as Current Folder. Use a fresh MATLAB session or run `clear functions` followed by `setup_repository`.
2. Run `run_all_reproductions`. It explicitly sets `RunLME=false`; no `fitlme` should be called.
3. Run `validate_against_verified`. **Expected: 13 PASS** for current-manuscript outputs. The two historical LME comparisons are not selected. If `results/reproduced/Figure4` already contains the two old LME CSVs from a previous run, the script warns without deleting them; these existing files are NOT products of the new run. You can use an empty temporary output folder to avoid confusion, or leave them as local historical artifacts (the folder is ignored by Git).
4. Record the real validation result in `docs/VALIDATION_STATUS.md`, replacing the 'pending' sentence **only after** you have seen the result. Do not claim 13/13 PASS in advance.
5. Run `update_manifest_sha256` **last**, in the real clone where the released MAT and cleaned Excel files are present. Do not copy any manifest from this patch.
6. In GitHub Desktop, commit and push. Suggested commit summary: `Align v1.0.1 with final no-LME manuscript`.
7. On GitHub confirm `README.md` distinguishes current no-LME and historical v1.0.0, that `VERSION` is `v1.0.1`, and that `CITATION.cff` says `1.0.1` without the old v1.0.0 version-specific DOI.

## Archive the current version on Zenodo

1. Leave the existing GitHub-to-Zenodo integration **ON**.
2. On GitHub, create a **new** release with tag `v1.0.1` targeting the verified main branch. Use `RELEASE_NOTES_v1.0.1.md` as the notes, not the v1.0.0 notes. Do not overwrite, retag, or delete the historical v1.0.0 release.
3. Wait for the v1.0.1 release to appear on Zenodo. Check that it is a **new version of the existing Zenodo record family**, associated with concept DOI `10.5281/zenodo.22885338`. Read the **actual new version-specific DOI** from the Zenodo record. The DOI is not known in advance.
4. In GitHub `main`, update README, `CITATION.cff`, `docs/DOI_AND_CITATION.md` and `docs/DATA_CODE_AVAILABILITY.md` with the new version-specific DOI, refresh the manifest, commit and push. This metadata-only GitHub update does not rewrite the immutable v1.0.1 tag archive.
5. Replace the manuscript Data and code availability DOI with the actual v1.0.1 version DOI. Send the new GitHub release and Zenodo record links to the supervisor.

## Historical v1.0.0 Zenodo record

The existing DOI `10.5281/zenodo.22885339` continues to identify the **historical v1.0.0 archive** (which includes exploratory LME code/outputs). Its files cannot be changed simply by editing GitHub main. If desired, use Zenodo **Edit metadata** (not New version) to add a clear notice to the historical record description:

> Historical release (v1.0.0). This archived version includes exploratory linear mixed-effects-model analysis excluded from the final manuscript following an additional audit. For the manuscript-aligned no-LME reproduction, use v1.0.1 and its version-specific Zenodo DOI. Statements in the historical documentation suggesting that original OIR acquisition files were lost or permanently unavailable are unverified and should not be relied upon; their availability has not been established.

Leave the historical files intact. Do not assign the old DOI to the current no-LME archive.
