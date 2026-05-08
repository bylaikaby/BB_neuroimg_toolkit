#!/usr/bin/env bash
set -euo pipefail

# General utility: convert native anatomical NIfTI to binary mask.
# Optional: resample mask to a reference image grid (e.g., EPI space).
#
# Requirements:
#   - FSL (fslmaths, flirt)
#
# Examples:
#   bash anat_to_binary_mask.sh \
#     -i /mnt/d/cm044_430/anat/cm044_brain_native.nii \
#     -o /mnt/d/cm044_430/anat/cm044_brain_native_bin.nii
#
#   bash anat_to_binary_mask.sh \
#     -i /mnt/d/cm044_430/anat/cm044_brain_native.nii \
#     -o /mnt/d/cm044_430/anat/rcm044_brain_native_bin_from_cm044.nii \
#     --ref /mnt/d/cm044_430/anat/rcm044_brain_native.nii

usage() {
  cat <<'EOF'
anat_to_binary_mask.sh - Convert anatomical NIfTI to binary mask.

Usage:
  bash anat_to_binary_mask.sh -i INPUT_NII -o OUTPUT_NII [--ref REF_NII] [--thr THRESH]

Required:
  -i, --input    Input anatomical NIfTI (.nii or .nii.gz)
  -o, --output   Output binary mask NIfTI (.nii or .nii.gz)

Optional:
  --ref          Reference image for resampling output mask to target grid
  --thr          Threshold before binarization (default: 0.000001)
  -h, --help     Show this help

Behavior:
  1) Replace NaNs with 0
  2) Apply threshold (voxels > thr survive)
  3) Binarize to {0,1}
  4) If --ref is set: resample with nearest-neighbor using FLIRT
EOF
}

INPUT=""
OUTPUT=""
REF=""
THR="0.000001"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      INPUT="${2:-}"; shift 2 ;;
    -o|--output)
      OUTPUT="${2:-}"; shift 2 ;;
    --ref)
      REF="${2:-}"; shift 2 ;;
    --thr)
      THR="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1 ;;
  esac
done

[[ -n "$INPUT" ]] || { echo "Error: --input is required" >&2; usage; exit 1; }
[[ -n "$OUTPUT" ]] || { echo "Error: --output is required" >&2; usage; exit 1; }
[[ -f "$INPUT" ]] || { echo "Error: input not found: $INPUT" >&2; exit 1; }
if [[ -n "$REF" ]]; then
  [[ -f "$REF" ]] || { echo "Error: ref not found: $REF" >&2; exit 1; }
fi

command -v fslmaths >/dev/null 2>&1 || { echo "Error: fslmaths not found in PATH" >&2; exit 1; }
command -v flirt >/dev/null 2>&1 || { echo "Error: flirt not found in PATH" >&2; exit 1; }

out_dir="$(dirname "$OUTPUT")"
mkdir -p "$out_dir"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

tmp_bin="$tmp_dir/tmp_bin.nii.gz"

echo "Binarizing: $INPUT"
fslmaths "$INPUT" -nan -thr "$THR" -bin "$tmp_bin"

if [[ -n "$REF" ]]; then
  echo "Resampling to ref grid: $REF"
  flirt -in "$tmp_bin" \
        -ref "$REF" \
        -applyxfm \
        -init "${FSLDIR}/etc/flirtsch/ident.mat" \
        -interp nearestneighbour \
        -out "$OUTPUT"
  # Ensure output remains hard-binary after interpolation
  fslmaths "$OUTPUT" -thr 0.5 -bin "$OUTPUT"
else
  cp "$tmp_bin" "$OUTPUT"
fi

echo "Done: $OUTPUT"
