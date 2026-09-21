# Analysis definitions

This document records the operational definitions implemented by the reproduction code. It is intended to make the numerical analysis unambiguous and to keep the code, source data, and manuscript terminology aligned.

## 1. Normalized measured Peak-F

At each measurement time point, Peak-F is available at 14 sampled correction-collar angles. Each 14-angle profile is normalized to its largest measured value at that time point, so the measured maximum is 1.

The compact analysis-ready datasets begin at this level. Raw fluorescence images and FFT calculation are upstream of the compact reproduction workflow.

## 2. Cubic score-versus-angle fit

A third-order polynomial is fitted to normalized measured Peak-F as a function of sampled-angle **index** (`1:14`), matching the original analysis implementation.

The fitted polynomial is evaluated on a fine grid with step:

```text
0.01 sampled-angle index units
```

For 2° sampled-angle spacing, this corresponds to 0.02°.

The sampled absolute angle range is experiment-specific and is read from the dataset; it is not hard-coded globally.

## 3. Fitted optimum and operational θopt

`theta_fit_deg` is the angle at which the fine-grid fitted curve reaches its maximum within the sampled scan range.

The operational `thetaopt_deg` used in Figures 1, 2, and 4 is assigned as follows:

1. Find the sampled angle with the highest **measured** normalized Peak-F.
2. If this measured maximum is at an interior sampled angle, use `theta_fit_deg`.
3. If this measured maximum is at the first or last sampled angle, use that sampled boundary angle instead.
4. If `R² <= 0.70`, set operational θopt to NaN for analyses using the θopt time series.

This boundary fallback reproduces the implemented analysis used for the reported numerical results.

## 4. R² and valid fit

R² is calculated from the cubic fit evaluated at the 14 sampled-angle indices.

A fit is considered valid for θopt-based analyses when:

```text
R² > 0.70
```

`valid_fit_rate` is the fraction of analyzed time points meeting this criterion.

`mean_R2` is calculated across all available time points before application of the validity threshold.

## 5. Boundary hit

A boundary hit is recorded when the highest **measured** normalized Peak-F occurs at either the first or last sampled scan angle.

`boundary_hit_rate` is the fraction of analyzed time points with a boundary hit.

A boundary hit does not by itself invalidate a fit.

## 6. W95

For each fitted curve, the code identifies the connected fine-grid interval containing the fitted maximum over which the fitted score is at least 95% of that fitted maximum.

```text
W95 = upper angle − lower angle
```

W95 is a fitted-curve width descriptor, not a confidence interval for θopt.

Mean W95 is calculated from all available W95 values irrespective of whether R² exceeds 0.70.

## 7. Figure 1 initial angle and relative fitted score

For Figure 1, the initial angle is the first valid fitted optimum. In the published Figure 1 cohort, the first measurement was valid in all seven experiments.

At each time point, the relative fitted score at the initial angle is:

```text
fitted score at theta_initial / same-time fitted maximum
```

The 0.95 threshold is operational and describes proximity to the fitted maximum; it is not an independently validated biological image-quality threshold.

## 8. Figure 2 condition summaries

For each experiment × isoflurane condition × imaging depth cell:

- mean θopt is the mean of valid operational θopt values;
- mean W95 is the mean of all available W95 values;
- mean R² is descriptive;
- valid fit rate is descriptive;
- boundary-hit rate is descriptive.

The final inferential test families are:

1. mean θopt: depth effect within each isoflurane condition (4 Friedman tests; BH across 4);
2. mean θopt: isoflurane effect within each depth (3 Friedman tests; BH across 3);
3. mean W95: depth effect within each isoflurane condition (4 Friedman tests; BH across 4).

Quality metrics are not included in a BH family in the final manuscript analysis.

## 9. Figure 3 reference angle

For each experiment:

```text
theta_ref = first valid fitted optimum at 200 µm under 1% isoflurane
```

This uses the fitted optimum before the operational boundary-angle substitution used for θopt time-series analyses.

For each valid target fitted curve:

```text
relative fitted score = fitted score(theta_ref) / fitted maximum
```

No extrapolation outside the sampled scan range is used.

Primary threshold: 0.95.
Sensitivity threshold: 0.98.

For the 0% condition, consecutive-run calculations treat the three noncontiguous 10-measurement segments separately.

## 10. Figure 4 first differences and DiffMAD

For valid adjacent measurements within the same continuous segment:

```text
Delta thetaopt(t) = thetaopt(t+1) − thetaopt(t)
```

Figure 4D displays the absolute magnitude `|Delta thetaopt|`, but DiffMAD is calculated from the signed differences:

```text
DiffMAD = median( abs(Delta thetaopt − median(Delta thetaopt)) )
```

For 0% isoflurane, differences across the three noncontiguous blocks are excluded. Before NaN exclusion, the expected number of legitimate adjacent pairs is:

- 0%: 27
- 1%: 29
- 2%: 29
- 3%: 29

## 11. DiffMAD depth slopes

For each experiment × isoflurane condition, a straight line is fitted to DiffMAD at 200, 250, and 300 µm. The slope is reported in degrees per micrometer.

For classification as positive/nonpositive, the reproduction code uses a tolerance of `1e-12 degree/µm` so that numerical floating-point noise around zero is not counted as a positive biological slope.

## 12. Associations and W95 adjustment

Across the 84 experiment-condition-depth observations, descriptive Spearman associations are calculated between DiffMAD and:

- mean W95;
- mean R²;
- valid fit rate;
- boundary-hit rate.

These 84 observations are repeated observations from seven experiments, not 84 independent biological replicates.

A pooled linear regression of DiffMAD on mean W95 is used to obtain W95-adjusted residuals. Residual depth comparisons are then performed within each isoflurane condition using Friedman tests with BH correction across the four conditions.

## 13. Exploratory linear mixed-effects models

Mouse/experiment is included as a random intercept. Imaging depth is coded as:

```text
Depth_50um = (depth_um − 200) / 50
```

Thus 200, 250, and 300 µm correspond to 0, 1, and 2.

Isoflurane is categorical with 0% as the reference condition.

Models:

```text
Model 1: DiffMAD ~ Depth_50um + isoflurane + (1|mouse)
Model 2: DiffMAD ~ Depth_50um + mean W95 + isoflurane + (1|mouse)
Model 3: DiffMAD ~ Depth_50um + mean W95 + mean R² + valid fit rate + boundary-hit rate + isoflurane + (1|mouse)
```

Models are estimated by maximum likelihood:

```matlab
'FitMethod','ML'
```

The public model-comparison CSV contains one row per likelihood-ratio comparison rather than retaining the baseline rows returned by MATLAB `compare`.
