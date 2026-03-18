#!/bin/bash

# ────────────────────── EDIT ONLY THESE LINES ──────────────────────
INPUT_PATTERN="HenryGroup_cm044_20251120*_aligned.nii"     # ← change this to whatever your files are called
                                                    # examples:
                                                    #   "sub-*_bold.nii.gz"
                                                    #   "*_run-?_bold.nii.gz"
                                                    #   "macaque??_rest.nii.gz"

ANAT_REF="mask.nii"             # anatomical reference for mcflirt
CUSTOM_PREFIX="filtered"                     # output files will start with this
# ─────────────────────────────────────────────────────────────────────

for bold in ${INPUT_PATTERN}; do
    [[ ! -f "$bold" ]] && { echo "No files match '$INPUT_PATTERN'"; exit 1; }

    # Remove path and extension to make clean base name
    base=$(basename "$bold" .nii)

    echo "=== Processing $bold ==="

    # 4. Denoise + bandpass 0.008-0.1 Hz + 2 mm smooth
    3dTproject -input "${base}.nii" \
               -prefix "${CUSTOM_PREFIX}_${base}.nii" \
               -passband 0.01 0.1 \ 
	       -automask \
               -polort 2\ 
                -blur 2   

    echo "DONE → ${CUSTOM_PREFIX}_${base}.nii"
    
done

