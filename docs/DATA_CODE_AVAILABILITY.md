# Data and code availability text

## Recommended manuscript wording after Zenodo deposition

> **Data and code availability.** Analysis-ready datasets, source-data workbooks underlying the figures and supplementary tables, mouse-level data used in the reported analyses, verified reference outputs, and MATLAB code used to reproduce the numerical analyses are available in the accompanying Zenodo record (DOI: **[ZENODO DOI]**). The development repository is available on GitHub at **https://github.com/aoigohma/correction-collar-optimization-reproducibility**. The deposited code includes scripts for curve fitting, estimation of the optimal correction-collar angle and W95, calculation of relative fitted scores and DiffMAD, statistical analyses, numerical validation, and regeneration of the data-driven panels in the main and supplementary figures. Documentation describing the analysis definitions, data structure, software requirements, and reproduction workflow is included in the repository.
>
> The TIFF-converted images used for image analysis are available from the corresponding author upon reasonable request. The original OIR acquisition files are no longer available. The compact public repository does not include the representative raw fluorescence-image assets used in Figure 1C or the manually assembled conceptual artwork; these are not required to reproduce the reported numerical analyses.

## Concise version if the journal prefers a shorter statement

> **Data and code availability.** Analysis-ready datasets, source data underlying the figures and supplementary tables, and MATLAB code for numerical reproduction and data-panel generation are publicly available at Zenodo (DOI: **[ZENODO DOI]**). The development repository is available at **https://github.com/aoigohma/correction-collar-optimization-reproducibility**. TIFF-converted images used for image analysis are available from the corresponding author upon reasonable request; original OIR acquisition files are no longer available.

## Temporary wording before a DOI has been assigned

> **Data and code availability.** Analysis-ready datasets, source-data workbooks underlying the figures and supplementary tables, mouse-level data used in the reported analyses, MATLAB code used to reproduce the numerical analyses, and scripts used to regenerate the data-driven figure panels will be deposited in a public Zenodo record. The development repository is available at **https://github.com/aoigohma/correction-collar-optimization-reproducibility**. The Zenodo DOI will be added before publication.

## After the article receives a DOI

After acceptance/publication, also update:

1. `CITATION.cff` with the article as `preferred-citation` and add the article DOI/journal metadata.
2. `README.md` with the final article citation.
3. Zenodo metadata with the article DOI as a related identifier.
4. The manuscript Data and code availability statement with the final Zenodo DOI.
