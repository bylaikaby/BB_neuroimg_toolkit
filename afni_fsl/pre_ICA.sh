#!/bin/bash


INPUT_PATTERN="HenryGroup_cm043_20251204*_aligned.nii"    

ANAT_MASK="cm043_brain_mask.nii"             # anatomical reference for mcflirt, in this case the 
CUSTOM_PREFIX="filtered"     # output files will start with this    
ref_mean=ref_mean.nii.gz            
# ─────────────────────────────────────────────────────────────────────

# for bold in ${INPUT_PATTERN}; do
#     [[ ! -f "$bold" ]] && { echo "No files match '$INPUT_PATTERN'"; exit 1; }

#     # Remove path and extension to make clean base name
#     base=$(basename "$bold" .nii)

#     echo "=== Processing $bold ==="

#     3dTproject -input "${base}.nii" \
#                -prefix "${CUSTOM_PREFIX}_${base}.nii" \
#                -stopband 0 0.0099 \
#                 -automask \
#                -polort 2 


#     echo "DONE → ${CUSTOM_PREFIX}_${base}.nii"
    
# done


if [[ ! -f mask_in_epi_final.nii ]]; then
    flirt -in $ANAT_MASK -ref $ref_mean \
          -out mask_in_epi.nii  -dof 12 -cost normcorr
    fslmaths mask_in_epi.nii -bin  mask_in_epi_final.nii
    echo "Mask registered → mask_in_epi_final.nii"
fi


echo "All finished!"

# melodic -i cm044_all.nii.gz \
#         -o melodic_ica \
#         --dim=50 \                 # 40–60 typical for 5–15 min of macaque data
#         --approach=concat \
#         --report \
#         --mask=mask_in_epi_final.nii.gz