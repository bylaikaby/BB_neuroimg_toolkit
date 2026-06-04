#!/usr/bin/env bash
# EPI within-run + between-run alignment and motion QC (AFNI/FSL).
#
# Alignment modes (see docs/qc_alignment_modes.md in cm_monkey_qst_bids):
#   wrun / single-run  — Step 1 only: 3dvolreg to run mean; motion QC from *_motion_wrun.txt
#   ref / session      — Steps 1–2: within-run MCF, then 3dvolreg all runs → ref_mean_epi;
#                        writes BOTH *_motion_wrun.txt (GLM nuisances) and *_motion_to_ref.txt
#                        (inter-run / censor QC)
#   auto (default)     — 1 raw EPI → wrun; 2+ EPIs → ref (multi-run sessions)
#
# Env: ALIGN_MODE=auto|wrun|ref  CENSOR_MOTION_FROM=auto|wrun|to_ref (defaults follow ALIGN_MODE)
#      MOTION_GALLERY=1 (default) — session gallery PNG via cm_monkey_qst_bids plot_motion_qc_gallery.py
#      BIDS_CODE_ROOT — path to .../cm_monkey_qst_bids/code (auto-detected from script location)
#
# Run: bash epi_align_qc.sh --help   (do not `source` this file)
set -euo pipefail

stem_from_path() {
  local b
  b=$(basename "$1")
  b="${b%.nii.gz}"
  b="${b%.nii}"
  printf '%s' "$b"
}

is_raw_epi() {
  local b
  b=$(basename "$1")
  [[ "$b" == r* ]] && return 1
  [[ "$b" == mean* ]] && return 1
  [[ "$b" == ref_mean* ]] && return 1
  [[ "$b" == *_mcf* ]] && return 1
  [[ "$b" == *_mc.* ]] && return 1
  return 0
}

collect_dir_niftis() {
  local d=$1
  local pat="${GLOB_PATTERN:-*.nii*}"
  [[ -d "$d" ]] || {
    echo "Error: not a directory: $d" >&2
    exit 1
  }
  mapfile -t files < <(
    find "$d" -maxdepth 1 -type f \( -name '*.nii' -o -name '*.nii.gz' \) ! -path '*/epi_QCed/*' | sort
  )
  local filtered=()
  local f b
  for f in "${files[@]}"; do
    is_raw_epi "$f" || continue
    if [[ "$pat" != "*.nii*" ]]; then
      b=$(basename "$f")
      [[ "$b" == $pat ]] || continue
    fi
    filtered+=("$f")
  done
  files=("${filtered[@]}")
}

usage() {
  cat <<'EOF'
epi_align_qc.sh — EPI alignment + motion QC (3dvolreg, 1d_tool.py, 1dplot.py).

Usage:
  bash epi_align_qc.sh --help
  bash epi_align_qc.sh -d /path/to/nifti_dir
  bash epi_align_qc.sh /path/to/nifti_dir
  bash epi_align_qc.sh run1.nii run2.nii.gz

Environment variables (defaults shown):
  OUT_DIR             Output directory              default: ./epi_QCed
  ALIGN_MODE          auto | wrun | ref             default: auto (1 EPI→wrun, 2+→ref)
  CENSOR_MM           1d_tool.py -censor_motion   default: 0.2 (mm)
  CENSOR_MOTION_FROM  auto | wrun | to_ref          default: auto (follows ALIGN_MODE)
  MOTION_GALLERY      1 = matplotlib gallery (wrun) default: 1 (skip per-run 1dplot)
  BIDS_CODE_ROOT      cm_monkey_qst_bids/code       default: sibling of bash/ if in-repo
  CLEAN_MCF           1 = delete *_mcf after step2 default: 1
  KEEP_NII_GZ         1 = r*_aligned.nii.gz       default: 0 (.nii)
  INTER_RUN_FROM      mcf | raw (2nd volreg input) default: mcf
  GLOB_PATTERN        Filter basenames in -d mode  default: *.nii* (raw only)
  FORCE               1 = overwrite existing outs   default: 0
  ANAT_NII            optional path → FLIRT to ref default: (unset)

Requires: AFNI; FSL flirt if ANAT_NII is set.
EOF
}

nifti_dir=""
pos=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    -d | --dir)
      [[ -n "${2:-}" ]] || {
        echo "Error: $1 needs a directory" >&2
        exit 1
      }
      nifti_dir=$2
      shift 2
      ;;
    *)
      pos+=("$1")
      shift
      ;;
  esac
done

OUT_DIR="${OUT_DIR:-./epi_QCed}"
CENSOR_MM="${CENSOR_MM:-0.2}"
ALIGN_MODE="${ALIGN_MODE:-auto}"
CENSOR_MOTION_FROM="${CENSOR_MOTION_FROM:-auto}"
CLEAN_MCF="${CLEAN_MCF:-1}"
KEEP_NII_GZ="${KEEP_NII_GZ:-0}"
INTER_RUN_FROM="${INTER_RUN_FROM:-mcf}"
FORCE="${FORCE:-0}"
MOTION_GALLERY="${MOTION_GALLERY:-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIDS_CODE_ROOT="${BIDS_CODE_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

mkdir -p "$OUT_DIR"

files=()
if [[ -n "$nifti_dir" ]]; then
  collect_dir_niftis "$nifti_dir"
elif [[ ${#pos[@]} -eq 1 && -d "${pos[0]}" ]]; then
  collect_dir_niftis "${pos[0]}"
elif [[ ${#pos[@]} -gt 0 ]]; then
  files=("${pos[@]}")
elif [[ -n "${EPI_DIR:-}" ]]; then
  collect_dir_niftis "$EPI_DIR"
else
  collect_dir_niftis "."
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Error: no raw EPI files found." >&2
  exit 1
fi

normalize_align_mode() {
  case "$1" in
    auto) printf '%s' "auto" ;;
    wrun | single | single-run) printf '%s' "wrun" ;;
    ref | session) printf '%s' "ref" ;;
    *)
      echo "Error: ALIGN_MODE must be auto, wrun, or ref (got: $1)" >&2
      exit 1
      ;;
  esac
}

resolve_align_mode() {
  local n=$1 req
  req=$(normalize_align_mode "$ALIGN_MODE")
  if [[ "$req" == "auto" ]]; then
    if [[ "$n" -eq 1 ]]; then
      printf '%s' "wrun"
    else
      printf '%s' "ref"
    fi
    return
  fi
  if [[ "$n" -gt 1 && "$req" == "wrun" ]]; then
    echo "Warning: ${n} EPIs — session QC needs ref_mean alignment; forcing ref mode." >&2
    printf '%s' "ref"
    return
  fi
  printf '%s' "$req"
}

resolved_align=$(resolve_align_mode "${#files[@]}")
run_inter_run=0
[[ "$resolved_align" == "ref" ]] && run_inter_run=1

if [[ "$CENSOR_MOTION_FROM" == "auto" ]]; then
  if [[ "$resolved_align" == "ref" ]]; then
    CENSOR_MOTION_FROM="to_ref"
  else
    CENSOR_MOTION_FROM="wrun"
  fi
fi

if [[ "$CENSOR_MOTION_FROM" != "wrun" && "$CENSOR_MOTION_FROM" != "to_ref" ]]; then
  echo "Error: CENSOR_MOTION_FROM must be auto, wrun, or to_ref (got: $CENSOR_MOTION_FROM)" >&2
  exit 1
fi

if [[ "$INTER_RUN_FROM" != "mcf" && "$INTER_RUN_FROM" != "raw" ]]; then
  echo "Error: INTER_RUN_FROM must be mcf or raw (got: $INTER_RUN_FROM)" >&2
  exit 1
fi

should_skip() {
  [[ "$FORCE" == "1" ]] && return 1
  [[ -f "$1" ]]
}

echo "=== EPI inputs (${#files[@]} runs) ==="
printf '  %s\n' "${files[@]}"
printf '%s\n' "$resolved_align" >"${OUT_DIR}/.align_mode"
echo "=== OUT_DIR=$OUT_DIR  FORCE=$FORCE  ALIGN_MODE=$ALIGN_MODE→$resolved_align  INTER_RUN=$run_inter_run  INTER_RUN_FROM=$INTER_RUN_FROM  CENSOR_MOTION_FROM=$CENSOR_MOTION_FROM ==="

echo "=== Step 1: Within-run 3dvolreg ==="
for f in "${files[@]}"; do
  base=$(stem_from_path "$f")
  motion_wrun="${OUT_DIR}/${base}_motion_wrun.txt"
  mcf_file="${OUT_DIR}/${base}_mcf.nii.gz"
  if should_skip "$mcf_file"; then
    echo "  skip: $mcf_file"
    continue
  fi
  echo "  $f"
  3dvolreg -overwrite -prefix "$mcf_file" -heptic -1Dfile "$motion_wrun" "$f"
done

if [[ "$run_inter_run" -eq 1 ]]; then
  ref_mean="${OUT_DIR}/ref_mean_epi.nii.gz"
  first_base=$(stem_from_path "${files[0]}")
  first_mcf="${OUT_DIR}/${first_base}_mcf.nii.gz"

  echo "=== Reference (mean of first run MCF) ==="
  3dTstat -mean -overwrite -prefix "$ref_mean" "$first_mcf"
  echo "  $ref_mean"

  if [[ -n "${ANAT_NII:-}" ]]; then
    echo "=== FLIRT anat → ref_mean ==="
    anat_dir=$(dirname "$ANAT_NII")
    anat_base=$(stem_from_path "$ANAT_NII")
    flirt_out="${anat_dir}/${anat_base}_in_epi_space.nii.gz"
    flirt -in "$ANAT_NII" -ref "$ref_mean" -out "$flirt_out" -dof 6
    echo "  $flirt_out"
  fi

  echo "=== Step 2: Between-run 3dvolreg → ref_mean ==="
  for f in "${files[@]}"; do
    base=$(stem_from_path "$f")
    infile="${OUT_DIR}/${base}_mcf.nii.gz"
    if [[ "$KEEP_NII_GZ" == "1" ]]; then
      outfile="${OUT_DIR}/r${base}_aligned.nii.gz"
    else
      outfile="${OUT_DIR}/r${base}_aligned.nii"
    fi
    motion_to_ref="${OUT_DIR}/${base}_motion_to_ref.txt"
    if [[ "$FORCE" != "1" && -f "$outfile" && -f "$motion_to_ref" ]]; then
      echo "  skip: $outfile (+ motion_to_ref)"
      continue
    fi
    if [[ "$INTER_RUN_FROM" == "raw" ]]; then
      volreg_in=$f
    else
      volreg_in=$infile
    fi
    echo "  $base ($INTER_RUN_FROM)"
    3dvolreg -overwrite -prefix "$outfile" -base "$ref_mean" -heptic -1Dfile "$motion_to_ref" "$volreg_in"
  done
else
  echo "=== Step 2: skipped (single-run / wrun mode — no ref_mean_epi) ==="
fi

if [[ "$CLEAN_MCF" == "1" ]]; then
  rm -f "${OUT_DIR}"/*_mcf.nii.gz
  echo "Removed *_mcf.nii.gz (CLEAN_MCF=0 to keep)"
fi

motion_label_for_censor() {
  if [[ "$CENSOR_MOTION_FROM" == "wrun" ]]; then
    echo wrun
  else
    echo to_ref
  fi
}

echo "=== Step 3: 1d_tool.py censor (${CENSOR_MM} mm) ==="
label=$(motion_label_for_censor)
for f in "${files[@]}"; do
  base=$(stem_from_path "$f")
  if [[ "$label" == wrun ]]; then
    motion_use="${OUT_DIR}/${base}_motion_wrun.txt"
  else
    motion_use="${OUT_DIR}/${base}_motion_to_ref.txt"
  fi
  censor_stem="${OUT_DIR}/${base}_${label}"
  censor_file="${censor_stem}_censor.1D"
  if should_skip "$censor_file"; then
    echo "  skip: $censor_file"
    continue
  fi
  echo "  $base"
  1d_tool.py -infile "$motion_use" -set_nruns 1 \
    -censor_motion "$CENSOR_MM" "$censor_stem" -overwrite
done

if [[ "$MOTION_GALLERY" == "1" ]]; then
  echo "=== Step 4: motion gallery (wrun; MOTION_GALLERY=1) ==="
  GALLERY_PY="${BIDS_CODE_ROOT}/python/plot_motion_qc_gallery.py"
  if [[ -f "$GALLERY_PY" ]]; then
    python3 "$GALLERY_PY" --qc-dir "$OUT_DIR" --out "${OUT_DIR}/motion_gallery.png" \
      --motion-source wrun --censor-mm "$CENSOR_MM" || {
      echo "Warning: motion gallery failed; set MOTION_GALLERY=0 for 1dplot per-run PNGs" >&2
    }
  else
    echo "Warning: $GALLERY_PY missing — falling back to 1dplot per-run PNGs" >&2
    MOTION_GALLERY=0
  fi
fi

if [[ "$MOTION_GALLERY" != "1" ]]; then
  echo "=== Step 4: 1dplot.py QC (per-run PNGs) ==="
  for f in "${files[@]}"; do
    base=$(stem_from_path "$f")
    if [[ "$label" == wrun ]]; then
      motion_use="${OUT_DIR}/${base}_motion_wrun.txt"
    else
      motion_use="${OUT_DIR}/${base}_motion_to_ref.txt"
    fi
    censor_file="${OUT_DIR}/${base}_${label}_censor.1D"
    plot_file="${OUT_DIR}/QC_${base}_motion_${label}.png"
    if should_skip "$plot_file"; then
      echo "  skip: $plot_file"
      continue
    fi
    1dplot.py -sepscl -ylabels VOLREG \
      -infiles "$motion_use" \
      -censor_files "$censor_file" \
      -censor_RGB red \
      -censor_hline "$CENSOR_MM" \
      -title "${base} | motion=${label} | red=censored (>${CENSOR_MM} mm)" \
      -prefix "$plot_file"
  done
fi

echo ""
echo "=== Done ==="
if [[ "$run_inter_run" -eq 1 ]]; then
  echo "  ref_mean: ${OUT_DIR}/ref_mean_epi.nii.gz"
  echo "  aligned:  ${OUT_DIR}/r*_aligned.nii*"
fi
echo "  motion:   ${OUT_DIR}/*_motion_{wrun,to_ref}.txt (GLM uses wrun via BIDS ingest)"
if [[ "$MOTION_GALLERY" == "1" ]]; then
  echo "  QC:       ${OUT_DIR}/motion_gallery.png"
else
  echo "  QC:       ${OUT_DIR}/QC_*_motion_${label}.png"
fi
