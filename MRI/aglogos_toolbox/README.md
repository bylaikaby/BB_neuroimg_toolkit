# AgLogo MATLAB toolbox

Lab analysis package for combined fMRI and electrophysiology workflows (ParaVision/Bruker, SPM, ROI tools, neural cleaning, session orchestration). Original `readme.txt` and `AgLogo Matlab Package (how-to).docx` in this directory have additional lab-internal notes.

**Redistribution:** Lab policy applies — do not share code outside the group without permission from NKL.

## Layout

| Directory | Role |
|-----------|------|
| `mri/` | fMRI processing, online monitoring (`monline/`), ROI (`mroi/`), atlas data (`mroiatlas/`), raw preprocessing |
| `neu/` | Neural signal analysis, cleaning (`cln/`), spike sorting |
| `io/` | Readers for ParaVision, Neuroscan, Spike2, ESS, HDF5/MAT bridges |
| `exppar/` | Experiment parameter and event parsing |
| `sigfunc/` | Signal utilities (trials, filtering, grouping, spectra) |
| `plt/` | Plotting helpers and GUI bitmaps |
| `stat/` | Statistics (e.g. FDR) |
| `stim/` | Stimulus / Cogent-related assets |
| `sysid/` | System identification / CCA utilities |
| `Projects/` | Per-project session scripts and configs |
| `docs/` | In-MATLAB help (`hgetstarted`, `hfunctions`, …) |
| `test/` | Example and validation scripts |
| `startup.m` | Path setup — run MATLAB with this folder as the start-in directory |

## Setup (MATLAB R2017a+)

1. Copy or clone this tree to a local path (e.g. `D:\imaging_toolkit\MRI\aglogos_toolbox`).
2. Create a MATLAB shortcut whose **Start in** / `-sd` directory is this folder.
3. Set **Preferences → General → Initial working folder** to something like `Documents\MATLAB` (not “last folder”), so `startup.m` path logic stays predictable.
4. Launch MATLAB from that shortcut. `startup.m` adds paths automatically — do **not** use **Set Path** from the menu.
5. In MATLAB, try `hgetstarted` for orientation.

Edit `startup.m` (and any local path helpers) if your SPM install or data roots differ from the lab defaults.

## External dependencies (not in this repo)

This copy is the **AgLogo-authored code** only. A full lab install also requires sibling directories that `startup.m` expects next to this tree:

| Missing path | Purpose |
|--------------|---------|
| `toolbox/` | Third-party bundles: SPM12, EEGLAB, Cogent, ParaVision `pvtools`, ICA, mrVista, MonkeyLogic, iso2mesh, glm, … |
| `utils/` | MEX utilities, SON32/SON64, Neuralynx helpers, ADF/ANZ converters |

Obtain `toolbox/` and `utils/` from the lab share or an existing workstation install, then place them as:

```
aglogos_toolbox/
  startup.m
  toolbox/    ← from lab
  utils/      ← from lab
  mri/
  …
```

Without those folders, many functions will fail at runtime even though the MATLAB sources are present.

**Runtime:** Some MEX files need the [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist) (2008/2010/2017 builds ship as `*.mexw64` / `*.mexw32` here).

## Quick workflow (from lab readme)

1. Add a session script under `Projects/ana/` (six-char name, e.g. `m02lx1`).
2. `sescheck` — validate session file.
3. `sesdumppar` — dump experiment parameters.
4. MRI: `sesascan` / `sescscan` / `sesimgload` / `mroi` / …
5. Neural: `sesgetcln` / `sesclnspc` / `sesgetblp` / `sesgetspk`.
6. `sigload` — load generated signals (e.g. `tcImg` time courses).

## ParaVision manual

Bruker ParaVision reference PDF lives once at `io/paravision/ParaVision 360 V3.4; PvManual.pdf` (~86 MB). A duplicate under `mri/monline/` was removed during repo import.
