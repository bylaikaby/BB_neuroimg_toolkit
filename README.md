# BB_neuroimg_toolkit

Personal neuroimaging utilities: **CT vessel extraction** from native vs contrast volumes, **MRI-style vessel helpers**, **fMRI pipeline scaffolding**, and assorted **shell** helpers for AFNI/FSL/ANTs workflows.

Upstream: [github.com/bylaikaby/BB_neuroimg_toolkit](https://github.com/bylaikaby/BB_neuroimg_toolkit)

---

## Repository layout

| Area | Path | Purpose |
|------|------|---------|
| **CT** | `CT/` | Contrast subtraction vessel mask; HU gating; DICOM→NIfTI helpers |
| **MRI** | `MRI/` | Index: `MRI/README.md` |
| **MRI** | `MRI/aglogos_toolbox/` | Lab AgLogo MATLAB package (fMRI + neural analysis; needs external `toolbox/` + `utils/`) |
| **MRI** | `MRI/max_intensity_mri_vessel/` | Intensity-window and Frangi-based vessel extraction from NIfTI |
| **MRI** | `MRI/flicker_1704/` | MATLAB flicker / TTL trigger control for fMRI experiments |
| **MRI** | `MRI/anat_to_binary_mask.sh` | FSL anatomical → binary mask helper |
| **Workflow** | `workflow/`, `config/`, `normalization/`, `glm/`, `activation/` | Config-driven orchestrator (dry-run, ANTs, GLM, optional activation summaries) |
| **Shell** | `afni_fsl/`, `ants/`, root `*.sh` | Motion correction, alignment, ICA, capture helpers |
| **Tools** | `tools/neuro_injection_calculator/` | IV tubing volume and anesthesia reach-time calculator (web) |

---

## CT: contrast vs native vessel extraction

Core library: `CT/nifti_ct_extraction.py`  
CLI: `CT/ct_vessel_workflow.py`  
Short reference: `CT/VESSEL_WORKFLOW_NOTE.md`

**Typical run** (defaults match the tuned preset; `--best` forces the same explicitly):

```bash
python CT/ct_vessel_workflow.py ^
  --ct-native "path/to/native.nii.gz" ^
  --ct-contrast "path/to/contrast.nii.gz" ^
  --output-vessel "path/to/vessels.nii.gz" ^
  --best
```

**Python import** (run from repo root or adjust `PYTHONPATH`):

```python
from CT.nifti_ct_extraction import subtract_contrast_ct, extract_vessels_best
```

**Dependencies:** `numpy`, `nibabel`; optional `pydicom` for DICOM conversion; `scipy` improves connected-component cleanup.

---

## MRI: intensity and Frangi vessel extraction

Path: `MRI/max_intensity_mri_vessel/`

- `intensity_vessel_extract.py` — binary mask from a scalar intensity band (good when thresholds are chosen in ITK-SNAP or similar).
- `frangi_vessel_extract.py` — 3D Frangi vesselness + mask (`scikit-image`, `scipy`).
- `notes_itksnap_intensity_threshold.md` — why display windowing can disagree with hard thresholds.

Example:

```bash
python MRI/max_intensity_mri_vessel/frangi_vessel_extract.py --input your_volume.nii.gz --out-mask vessel_mask_frangi.nii.gz
```

---

## fMRI: orchestrator (optional)

Config-driven stages (normalize, GLM backends, optional activation summaries):

```bash
python -m workflow.orchestrator --config config/env.example.json --dry-run
```

See `config/env.example.json`, `config/env.optofmri.bids.json`, and `config/env.example.yaml` for field shapes.

---

## MATLAB path setup

Add repo MATLAB code (flicker GUI, full AgLogo package) from any session:

```matlab
addpath('D:\imaging_toolkit\matlab');
add_imaging_toolkit_paths('verbose', true);
```

**monline only** (ParaVision 2dseq online GUI — used from cm_monkey_qst_bids Track L):

```matlab
addpath('D:\imaging_toolkit\matlab');
add_monline_paths();
monline
```

From **cm_monkey_qst_bids** (recommended):

```matlab
cd('Z:/MRIdata/cm_monkey_qst_bids/code');
setup_online_track_path;   % setup_qc_path + setup_monline_path
monline
```

Set `IMAGING_TOOLKIT_ROOT` if the clone is not at `D:\imaging_toolkit`.

**Persistent (recommended):** copy `matlab/startup.m` to `Documents\MATLAB\startup.m`, or append its `addpath` + `add_imaging_toolkit_paths()` lines to your existing user `startup.m`. Edit the `toolkit` path if the clone is not on `D:\imaging_toolkit`.

AgLogo third-party bundles (`toolbox/`, `utils/`) are added automatically when present next to `MRI/aglogos_toolbox/`. `monline` only needs `mri/monline/` + SPM12. See `MRI/aglogos_toolbox/README.md`.

---

## Installation

```bash
pip install -r requirements.txt
```

`requirements.txt` covers the orchestrator stack. For **Frangi** MRI scripts, also install:

```bash
pip install scipy scikit-image
```

For **DICOM** conversion in `CT/nifti_ct_extraction.py`:

```bash
pip install pydicom
```

---

## License and data

Scripts are provided as-is for research workflows. **Do not commit patient-identifiable data or large binary series** unless your project policy explicitly allows it; use `.gitignore` for local NIfTI/DICOM trees.
