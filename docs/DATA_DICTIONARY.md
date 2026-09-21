# Data dictionary

## `Figure1_analysis_ready.mat`

Main variable: `F1`, one struct per experiment.

| Field | Description |
|---|---|
| `experiment_id` | Acquisition/experiment identifier, e.g. `20231108_data1` |
| `source_file` | Processed MAT filename from which the compact dataset was built |
| `depth_um` | Imaging depth; 200 for Figure 1 |
| `isoflurane_pct` | Isoflurane concentration; 2 for Figure 1 |
| `measurement_index` | Index within the 30-measurement analysis window |
| `actual_time_idx` | Original measurement indices |
| `segment_id` | Segment label; one continuous segment for Figure 1 |
| `angle_deg` | Sampled correction-collar angles for that experiment |
| `normalized_peakf` | Matrix: sampled angle × measurement |

The MAT file also contains `dataset_info` and `analysis_parameters` structs describing the compact dataset and reproduction settings.

## `Figures2to4_analysis_ready.mat`

Main variable: `F234`, one struct per experiment.

Experiment-level fields include:

| Field | Description |
|---|---|
| `experiment_id` | Acquisition/experiment identifier |
| `source_file` | Processed 4-condition MAT filename |
| `depth_um` | `[200 250 300]` |
| `angle_deg` | Experiment-specific sampled correction-collar angles |
| `condition` | Array of four condition structs |

Each condition struct contains:

| Field | Description |
|---|---|
| `condition_name` | `Ane0`, `Ane1`, `Ane2`, or `Ane3` |
| `isoflurane_label` | `0%`, `1%`, `2%`, or `3%` |
| `isoflurane_pct` | Numeric concentration 0, 1, 2, or 3 |
| `measurement_index` | 1–30 within the compact condition series |
| `actual_time_idx` | Original measurement indices from the full recording |
| `segment_id` | Continuous-segment identifier |
| `normalized_peakf` | 3-D array: sampled angle × measurement × depth |

### Original analysis windows

| Condition | Original indices | Segments |
|---|---|---:|
| `Ane0` | 1–10, 61–70, 121–130 | 3 |
| `Ane1` | 31–60 | 1 |
| `Ane2` | 91–120 | 1 |
| `Ane3` | 150–179 | 1 |

## Metadata CSVs

`Figure1_analysis_ready_metadata.csv` and `Figures2to4_analysis_ready_metadata.csv` provide human-readable summaries of experiment IDs, condition windows, scan ranges, angle spacing, and segment structure without duplicating the full normalized Peak-F arrays.

## Values intentionally omitted from the compact inputs

The following are deliberately recalculated downstream and are not required as analysis-ready inputs:

- polynomial coefficients;
- fitted curves;
- R²;
- fitted optimum;
- operational θopt;
- boundary hit;
- W95;
- relative fitted scores;
- DiffMAD;
- experiment-level summaries;
- group statistics.

This design allows the reported derived values to be independently reconstructed from normalized measured Peak-F profiles.
