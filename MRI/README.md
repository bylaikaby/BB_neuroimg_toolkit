# MRI utilities

MATLAB and shell helpers for macaque/rodent fMRI, stimulation control, vessel extraction, and the lab AgLogo analysis package.

| Path | Description |
|------|-------------|
| `aglogos_toolbox/` | Lab AgLogo MATLAB package (fMRI/neural analysis, ParaVision I/O, ROI tools). See `aglogos_toolbox/README.md`. |
| `flicker_1704/` | Flicker stimulation and TTL trigger control scripts for scanner experiments. |
| `flicker_gui.m` | GUI wrapper for flicker/trigger control (repo root of this folder). |
| `max_intensity_mri_vessel/` | Python vessel masks from intensity windows or 3D Frangi filtering. |
| `anat_to_binary_mask.sh` | FSL helper: anatomical NIfTI → binary mask, optional resample to EPI grid. |
| `figures/` | Example QC figures for vessel/threshold workflows. |

**Data files** (`*.nii`, `*.nii.gz`) are gitignored; keep local test volumes outside the repo or in ignored paths.
