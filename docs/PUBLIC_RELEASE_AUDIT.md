# Public-release audit

Audit date: 2026-09-22
Target release: `v1.0.0`

The repository was audited before the first public GitHub/Zenodo release.

## Completed checks

- No GitHub tokens, API keys, passwords, or obvious credentials were found in the prepared text/code files.
- No personal user-profile paths such as `C:\Users\...`, `/Users/...`, or `/home/...` were identified in the prepared public package.
- No temporary/editor files such as `.asv`, `.autosave`, `.DS_Store`, `Thumbs.db`, `.tmp`, or `.bak` were intended for release.
- The released Excel workbooks had no external-link parts, workbook connections, or hidden/veryHidden worksheets.
- The six released `.xlsx` files were cleaned with Excel Document Inspector before the final private-repository commit.
- The GitHub repository URL is fixed as `https://github.com/aoigohma/correction-collar-optimization-reproducibility`.
- Numerical reproduction previously completed with 15/15 key comparisons passing and `MaxNumericAbsDiff = 0`.
- Main-figure and Supplementary Figure S1–S6 panel-generation workflows were executed successfully and visually checked.

## v1.0.0 preparation

The v1.0.0 replacement files set:

- `VERSION` to `v1.0.0`;
- `CITATION.cff` version to `1.0.0`;
- `CITATION.cff` release date to `2026-09-22`;
- retain the confirmed GitHub repository URL; and
- intentionally leave the Zenodo DOI absent until Zenodo archives the GitHub release.

If the actual public release date differs from 2026-09-22, update `date-released` in `CITATION.cff` and the version/date sentence in `README.md` before the GitHub release is created.

## Final actions before public visibility

1. Overlay the v1.0.0 replacement files onto the local GitHub clone.
2. Run `update_manifest_sha256` after all final changes.
3. Optionally rerun `validate_against_verified` for a final numerical sanity check.
4. Commit and push the v1.0.0 preparation state while the repository is still private.
5. Change repository visibility to Public.
6. In Zenodo, run `Sync now`, enable the repository, and only then create the GitHub `v1.0.0` release.
7. Confirm DOI assignment and update README/CITATION/manuscript metadata afterward.
