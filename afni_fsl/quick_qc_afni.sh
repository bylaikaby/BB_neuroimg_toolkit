#!/usr/bin/env bash
# quick_qc_afni — in-situ EPI motion + alignment QC (wrapper around epi_align_qc.sh)
#
# Alignment rule (see cm_monkey_qst_bids/docs/qc_alignment_modes.md):
#   1 EPI  → wrun (within-run volreg only)
#   2+ EPI → ref  (ref_mean_epi + r*_aligned; motion QC on to_ref)
# Override: --mode wrun|ref|auto  (aliases: --single-run, --session)
#
# All outputs go under <nifti-dir>/epi_QCed/ by default (no BIDS / project folder).
#
# Usage:
#   bash quick_qc_afni.sh -d /path/to/Nifti
#   bash quick_qc_afni.sh -d /path/to/Nifti --glob '*_2_1.nii' --force
#   bash quick_qc_afni.sh run19.nii run22.nii
#
# Windows:
#   .\quick_qc_afni.ps1 -Directory \\tsclient\E\cm042_0602\Nifti -Glob '*_2_1.nii' -InSitu -Force
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EPI_ALIGN_QC="${EPI_ALIGN_QC:-${SCRIPT_DIR}/epi_align_qc.sh}"
CENSOR_MM="${CENSOR_MM:-0.2}"
ALIGN_MODE="${ALIGN_MODE:-auto}"
MOTION_PLOT="${MOTION_PLOT:-}"
OUT_DIR=""
NIFTI_DIR=""
GLOB_PATTERN=""
FORCE=0
pos=()

usage() {
  cat <<EOF
quick_qc_afni — in-situ EPI motion + alignment QC

Usage:
  bash quick_qc_afni.sh -d DIR [options]
  bash quick_qc_afni.sh [-o OUT] [file.nii ...]

Options:
  -d, --dir DIR       NIfTI directory (in-situ: writes DIR/epi_QCed/)
  -o, --out DIR       Override output dir (default: <input-dir>/epi_QCed)
  --glob PAT          Basename glob in -d mode (e.g. '*_2_1.nii')
  --force             Recompute all outputs (FORCE=1)
  --censor-mm MM      Censor threshold mm (default: 0.2)
  --mode MODE         auto | wrun | ref (default: auto)
  --single-run        Same as --mode wrun
  --session           Same as --mode ref
  --motion LABEL      wrun | to_ref — override censor/plot only (default: follow --mode)

Outputs (local epi_QCed/ only — raw NIfTIs stay untouched):
  Session: ref_mean_epi.nii.gz, r*_aligned.nii*, QC_*_motion_to_ref.png
  Single:  *_mcf.nii.gz (if kept), QC_*_motion_wrun.png, motion_summary.json
EOF
}

stem_from_path() {
  local b
  b=$(basename "$1")
  b="${b%.nii.gz}"
  b="${b%.nii}"
  printf '%s' "$b"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    -o | --out) OUT_DIR="${2:-}"; shift 2 ;;
    -d | --dir) NIFTI_DIR="${2:-}"; shift 2 ;;
    --glob) GLOB_PATTERN="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --censor-mm) CENSOR_MM="${2:-}"; shift 2 ;;
    --mode) ALIGN_MODE="${2:-}"; shift 2 ;;
    --single-run) ALIGN_MODE="wrun"; shift ;;
    --session) ALIGN_MODE="ref"; shift ;;
    --motion) MOTION_PLOT="${2:-}"; shift 2 ;;
    *) pos+=("$1"); shift ;;
  esac
done

normalize_motion_label() {
  case "$1" in
    wrun) printf '%s' "wrun" ;;
    to_ref | ref) printf '%s' "to_ref" ;;
    *)
      echo "Error: --motion must be wrun or to_ref" >&2
      exit 1
      ;;
  esac
}

if [[ -n "$MOTION_PLOT" ]]; then
  MOTION_PLOT=$(normalize_motion_label "$MOTION_PLOT")
fi

case "$ALIGN_MODE" in
  auto | wrun | ref | single | single-run | session) ;;
  *)
    echo "Error: --mode must be auto, wrun, or ref" >&2
    exit 1
    ;;
esac

[[ -f "$EPI_ALIGN_QC" ]] || { echo "Error: missing $EPI_ALIGN_QC" >&2; exit 1; }

align_args=()
input_root=""
if [[ -n "$NIFTI_DIR" ]]; then
  align_args=(-d "$NIFTI_DIR")
  input_root="$NIFTI_DIR"
elif [[ ${#pos[@]} -eq 1 && -d "${pos[0]}" ]]; then
  align_args=(-d "${pos[0]}")
  input_root="${pos[0]}"
elif [[ ${#pos[@]} -gt 0 ]]; then
  align_args=("${pos[@]}")
  input_root="$(dirname "$(readlink -f "${pos[0]}" 2>/dev/null || echo "${pos[0]}")")"
else
  echo "Error: pass -d DIR or NIfTI file(s)." >&2; usage >&2; exit 1
fi

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="${input_root%/}/epi_QCed"
fi

mkdir -p "$OUT_DIR"

echo "=== quick_qc_afni (in-situ) ==="
echo "  input:  $input_root"
echo "  out:    $OUT_DIR"
echo "  glob:   ${GLOB_PATTERN:-<all raw *.nii>}"
echo "  force:  $FORCE"
if [[ -n "$MOTION_PLOT" ]]; then
  echo "  mode:   ${ALIGN_MODE}  censor/plot override: ${MOTION_PLOT}"
else
  echo "  mode:   ${ALIGN_MODE}  censor/plot: (follow mode)"
fi
echo "  censor: ${CENSOR_MM} mm"

export GLOB_PATTERN FORCE ALIGN_MODE
# Multi-run sessions: never pass wrun as CENSOR_MOTION_FROM unless user explicitly set --motion wrun
censor_from="${MOTION_PLOT:-auto}"
if [[ -z "$MOTION_PLOT" && ( "$ALIGN_MODE" == "ref" || "$ALIGN_MODE" == "session" ) ]]; then
  censor_from="to_ref"
fi
OUT_DIR="$OUT_DIR" CENSOR_MM="$CENSOR_MM" CENSOR_MOTION_FROM="$censor_from" \
  bash "$EPI_ALIGN_QC" "${align_args[@]}"

# Collect stems from outputs (authoritative after align)
mapfile -t stems < <(
  find "$OUT_DIR" -maxdepth 1 -name '*_motion_wrun.txt' -printf '%f\n' 2>/dev/null \
    | sed 's/_motion_wrun\.txt$//' | sort
)

summary_json="${OUT_DIR}/motion_summary.json"
python3 - "$OUT_DIR" "$CENSOR_MM" "$summary_json" "${stems[@]}" <<'PY'
import json
import sys
from pathlib import Path

import numpy as np

out_dir = Path(sys.argv[1])
censor_mm = float(sys.argv[2])
summary_path = Path(sys.argv[3])
stems = sys.argv[4:]


def motion_stats(mot: np.ndarray, censor_mm: float, label: str, stem: str, out_dir: Path):
    trans = mot[:, 3:6]
    disp_from_base = np.sqrt((trans**2).sum(axis=1))
    fd_trans = np.sqrt((np.diff(trans, axis=0) ** 2).sum(axis=1))
    enorm_p = out_dir / f"{stem}_{label}_enorm.1D"
    if enorm_p.is_file():
        fd = np.loadtxt(enorm_p)
        if fd.ndim > 1:
            fd = fd[:, 0]
    else:
        fd = fd_trans
    censor_p = out_dir / f"{stem}_{label}_censor.1D"
    n_censor = int((np.loadtxt(censor_p) == 0).sum()) if censor_p.is_file() else None
    return {
        "n_volumes": int(mot.shape[0]),
        "max_disp_from_base_mm": round(float(disp_from_base.max()), 4),
        "max_framewise_fd_mm": round(float(fd.max()), 4) if len(fd) else 0.0,
        "mean_framewise_fd_mm": round(float(fd.mean()), 4) if len(fd) else 0.0,
        "volumes_fd_gt_censor": int((fd > censor_mm).sum()) if len(fd) else 0,
        "volumes_censored_afni": n_censor,
    }


rows = []
for stem in stems:
    row = {"stem": stem}
    for label in ("wrun", "to_ref"):
        mot_p = out_dir / f"{stem}_motion_{label}.txt"
        if mot_p.is_file():
            row[f"motion_{label}"] = motion_stats(np.loadtxt(mot_p), censor_mm, label, stem, out_dir)
    rows.append(row)

align_mode = (out_dir / ".align_mode").read_text().strip() if (out_dir / ".align_mode").is_file() else None
summary = {
    "tool": "quick_qc_afni",
    "mode": "in_situ",
    "align_mode": align_mode,
    "out_dir": str(out_dir),
    "censor_mm": censor_mm,
    "runs": rows,
}
summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")

primary = align_mode if align_mode in ("wrun", "ref") else "wrun"
primary_key = "motion_wrun" if primary == "wrun" else "motion_to_ref"
print(f"\n=== Motion summary (framewise FD, {primary}) ===")
for row in rows:
    stats = row.get(primary_key)
    if not stats:
        print(f"  {row['stem']}: no {primary} motion")
        continue
    print(
        f"  {row['stem']}: n={stats['n_volumes']}  "
        f"maxFD={stats['max_framewise_fd_mm']:.3f} mm  "
        f"FD>{censor_mm}={stats['volumes_fd_gt_censor']} vol  "
        f"censored={stats['volumes_censored_afni']}"
    )
print(f"\n  JSON: {summary_path}")
if (out_dir / "motion_gallery.png").is_file():
    print(f"  Gallery: {out_dir}/motion_gallery.png")
else:
    print(f"  PNG:  {out_dir}/QC_*_motion_*.png (or motion_gallery.png if MOTION_GALLERY=1)")
PY

# Session motion gallery (wrun) if epi_align did not already write it (MOTION_GALLERY=1)
GALLERY_PY="/mnt/z/MRIdata/cm_monkey_qst_bids/code/python/plot_motion_qc_gallery.py"
[[ -f "$GALLERY_PY" ]] || GALLERY_PY="Z:/MRIdata/cm_monkey_qst_bids/code/python/plot_motion_qc_gallery.py"
if [[ -f "$GALLERY_PY" ]] && [[ ! -f "${OUT_DIR}/motion_gallery.png" ]]; then
  python3 "$GALLERY_PY" --qc-dir "$OUT_DIR" --out "${OUT_DIR}/motion_gallery.png" --motion-source wrun \
    --censor-mm "$CENSOR_MM" || true
fi

echo ""
echo "=== quick_qc_afni done ==="
