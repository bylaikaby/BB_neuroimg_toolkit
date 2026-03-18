#!/bin/bash

# # ─── EDIT ONLY THIS LINE ───
# INPUT="filtered_HenryGroup_cm044_20251120*_aligned.nii"   # ← your 3dTproject outputs
# # ───────────────────────────



# echo "→ Done!  cm044_all_preproc.nii.gz  is ready for MELODIC / FEAT / ICA-AROMA"
# echo "   Volumes: $(fslval cm044_all_preproc.nii.gz dim4)"
# printf '%s\n' filtered_HenryGroup_cm044_20251120*_aligned.nii > scans.txt

# fslmerge -t cm044_preprocessed_concat.nii.gz filtered_HenryGroup_cm044_20251120*_aligned.nii


melodic -i scans.txt \
        -o cm043_melodic \
        --tr=2 \
        --approach=tica\
        --report -m mask_in_epi_final.nii\
        --nobet -v


# fslmerge -t concat_scan.nii $(printf '%s\n' filtered_HenryGroup_cm044_20251120*_aligned.nii)
# fsl_regfilt -i concat_scan.nii   \
#                 -d ./cm044_ica_3/melodic_mix \
#                 -o "concat_scans_ICA_filtered.nii" \
#                 -f "1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 21, 22, 23, 24, 27, 28, 29, 31, 32, 33, 34, 35, 36, 39"

# # Create output dir
# mkdir -p denoised_scans

# # Auto-split using scans.txt order
# start=0
# while IFS= read -r orig_scan; do
#     [[ -z "$orig_scan" ]] && continue

#     # Get subject filename (e.g., cm044_20251120_01_aligned.nii)
#     base=$(basename "$orig_scan" .nii)  # strips path & .nii
    
#     # Get number of volumes from ORIGINAL scan (critical!)
#     nv=$(fslinfo "$orig_scan" | awk '/^dim4/ {print $2}')
    
#     # echo "✂️ Extracting $base (vols $start – $((start + nv - 1)))"
    
#     # # Extract from denoised merged file
#     # fslroi concat_scans_ICA_filtered.nii \
#     #         denoised_scans/"${base}_denoised.nii.gz" \
#     #         $start $nv
#     fslmaths denoised_scans/"${base}_denoised.nii.gz" \
#          -kernel gauss 0.85 \
#          -fmean \
#          denoised_scans/"${base}_denoised_smoothed.nii.gz"
#     # 3dTproject -input "${base}.nii" \
#     #            -prefix "${CUSTOM_PREFIX}_${base}.nii" \
#     #            -ort "${base%_aligned}_motion.txt" \
#     #            -stopband 0 0.00099 \
#     #             -automask \
#     #            -polort 2 
#     ((start += nv))
# done < scans_clean.txt