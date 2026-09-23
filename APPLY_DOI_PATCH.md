# Post-release DOI metadata patch for no-LME v1.0.1

The current manuscript uses **https://doi.org/10.5281/zenodo.22913943** (v1.0.1). Historical v1.0.0 remains at https://doi.org/10.5281/zenodo.22885339; the all-versions concept DOI is https://doi.org/10.5281/zenodo.22885338.

1. Extract this patch and copy its **contents**, not the outer folder, into the root of the **GitHub Desktop clone**. Overwrite the existing same-named files. Do not remove or replace `data/`, `code/`, `results/`, or the original Excel sheets. The patch changes **documentation and CFF only**.
2. In MATLAB, with the clone as Current Folder, run `setup_repository; update_manifest_sha256`. Do not edit the already-published tag `v1.0.1`. An additional MATLAB numerical run is not necessary for documentation-only changes: the no-LME 13/13 PASS was already observed on 2026-09-23.
3. In GitHub Desktop, inspect Changes. Commit to `main` with summary `Add Zenodo v1.0.1 DOI and finalize no-LME documentation`, then Push origin. **Do not create a new Release solely to insert the DOI.**
4. In the **published Zenodo v1.0.1 record**, choose Edit (metadata only). Remove the out-of-date sentence claiming this release *will have* a new version DOI. The DOI is already https://doi.org/10.5281/zenodo.22913943. Also ensure license metadata expresses both MIT (code) and CC BY 4.0 (data/documentation), with scope explained in the description; save/publish metadata edits. Do not upload replacement archive files or use New version for metadata corrections.
5. If the GitHub `v1.0.1` Release description still says the DOI is pending, edit its description to include `Archived at https://doi.org/10.5281/zenodo.22913943`. This changes the release-page description only; the tag/archive remains unchanged.
6. In the manuscript, use the exact Data and code availability text in `docs/DATA_CODE_AVAILABILITY.md` and provide the supervisor with the **v1.0.1 version DOI**, not the historical v1.0.0 DOI.

Note: GitHub `main` will contain post-release DOI references that are not present in the immutable tagged v1.0.1 Zenodo ZIP. This is expected; Zenodo's record metadata already holds its DOI. The code and data remain unchanged.
