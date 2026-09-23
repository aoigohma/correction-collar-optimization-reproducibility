# Public-release audit

Audit date: 2026-09-22

This audit was performed on the prepared `v0.3.0-draft` repository package before public release.

## Findings

### Passed checks

- No GitHub tokens, API keys, passwords, or obvious credentials were found in the text/code files scanned.
- No personal user-profile paths such as `C:\Users\...`, `/Users/...`, or `/home/...` were found.
- No temporary/editor files such as `.asv`, `.autosave`, `.DS_Store`, `Thumbs.db`, `.tmp`, or `.bak` were found in the prepared package.
- The released Excel workbooks contained no external-link parts, workbook connections, or hidden/veryHidden worksheets.
- The GitHub repository URL is now known and can be recorded directly in `CITATION.cff` and the Data and code availability text.

### Items requiring action before public release

1. **Excel document-location metadata**
   - All six released `.xlsx` files retained Excel document-location metadata (`x15ac:absPath`) pointing to the local manuscript/source-data folder.
   - This does not alter the scientific data, but it exposes an unnecessary local filesystem path and should be removed before public release.
   - On a copy of each workbook, use Excel: `File > Info > Check for Issues > Inspect Document` and remove **Document Properties and Personal Information**. Save, close Excel, and then use the cleaned file in the repository.
   - After cleaning, reopen/inspect the public copy if desired, because Excel may add a document location again after a later save in a reopened workbook.

2. **Draft/version metadata**
   - Keep `v0.3.x-draft` while the repository is private.
   - Immediately before the first public GitHub release, set `VERSION` to `v1.0.0` and `CITATION.cff` `version` to `1.0.0`.

3. **Zenodo DOI placeholder**
   - `[ZENODO DOI]` should remain until Zenodo assigns the DOI.
   - Replace it in the manuscript-facing availability text and repository documentation after DOI assignment.

4. **SHA-256 manifest**
   - The local public repository includes the released analysis-ready MAT files, whereas the earlier draft manifest was generated before those files were inserted into the local copy.
   - Run `update_manifest_sha256` after all final file changes so the manifest includes the released MAT files and cleaned workbooks.

5. **CITATION metadata**
   - Confirm author order/names with coauthors.
   - The GitHub URL can be entered now.
   - Add `date-released` at the v1.0.0 release.
   - Add the Zenodo DOI after archiving, and add the article as `preferred-citation` after article metadata are final.

## Optional MATLAB check for released MAT files

The two analysis-ready MAT files were already used successfully for end-to-end numerical reproduction. Before public release, the following commands can also be used to review their top-level contents:

```matlab
whos('-file','data/analysis_ready/Figure1_analysis_ready.mat')
whos('-file','data/analysis_ready/Figures2to4_analysis_ready.mat')
```

The public release should contain only the intended compact analysis-ready structures/metadata, not raw microscopy images or unrelated workspace variables.

## Final pre-public sequence

1. Clean the six `.xlsx` files with Excel Document Inspector.
2. Commit those cleaned workbooks to the private GitHub repository.
3. Overlay the public-audit text/code patch.
4. Rerun `run_all_reproductions` and `validate_against_verified` if any data workbook or analysis-ready MAT file itself was changed. Metadata-only Excel cleaning does not change the numerical data, but a final verification is still recommended.
5. Run all main and supplementary figure generators once more if desired.
6. Run `update_manifest_sha256`.
7. Commit/push the final private state.
8. Change version metadata to `v1.0.0` only when ready to make the first public release.


## Final no-LME manuscript scope change (2026-09-23)

The final manuscript omits exploratory LME/LMM because a final audit found an unresolved issue. The underlying historical code and data are retained without claiming current-manuscript validation. v1.0.0 remains the historical Zenodo archive. A new v1.0.1 GitHub/Zenodo release is required for a manuscript-scope-aligned immutable archive; its DOI is assigned only after publication. Assertions that original OIR files have been lost are removed because their availability has not been confirmed.
