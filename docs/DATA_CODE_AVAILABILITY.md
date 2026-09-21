# Data and code availability text

## Recommended manuscript wording after Zenodo deposition

> **Data and code availability.** Analysis-ready datasets, source-data workbooks underlying the figures and supplementary tables, MATLAB code used to reproduce the reported numerical analyses, verified reference outputs, and scripts used to regenerate the data-driven figure panels are available in the accompanying Zenodo record (DOI: **[ZENODO DOI]**). The development repository is available on GitHub at **[GITHUB REPOSITORY URL]**. The compact repository does not include the original OIR acquisition files or the representative raw fluorescence-image assets required for Figure 1C; all reported numerical analyses can be reproduced from the deposited analysis-ready datasets.

## Concise version if the journal prefers a single repository citation

> **Data and code availability.** Analysis-ready datasets, source data underlying the figures and supplementary tables, and MATLAB code for numerical reproduction and data-panel generation are publicly available at Zenodo (DOI: **[ZENODO DOI]**). Original OIR acquisition files and the representative raw fluorescence images used for Figure 1C are not included in the compact repository.

## Temporary wording before a DOI has been assigned

> **Data and code availability.** Analysis-ready datasets, source-data workbooks underlying the figures and supplementary tables, MATLAB code used to reproduce the reported numerical analyses, and scripts used to regenerate the data-driven figure panels will be deposited in a public Zenodo record. The corresponding development repository will be made available on GitHub. Repository identifiers will be added before publication.

## After the article receives a DOI

After acceptance/publication, also update:

1. `CITATION.cff` with the article as `preferred-citation` and add the article DOI/journal metadata.
2. `README.md` with the final article citation.
3. Zenodo metadata with the article DOI as a related identifier.
4. The manuscript Data and code availability statement with the final Zenodo DOI and, if desired, the GitHub URL.
