#!/bin/bash
/mnt/d/OPTO_fMRI_CM/Templates/


# Define input variables
template_folder="/mnt/d/OPTO_fMRI_CM/Templates"
field="/mnt/d/CM032_bids/sub-CM032/first_level_analysis/warped_temps/temp_transformed.nii1Warp.nii"
affine="/mnt/d/CM032_bids/sub-CM032/first_level_analysis/warped_temps/temp_transformed.nii0GenericAffine.mat"
warped_temp_folder="/mnt/d/CM032_bids/sub-CM032/first_level_analysis/warped_temps"
warped_NMT="/mnt/d/CM032_bids/sub-CM032/first_level_analysis/warped_temps/temp_transformed.niiWarped.nii"

temps=($template_folder/*)



for temp in "${temps[@]}"; do
    
    # antsApplyTransforms command using $gzipped_func
    antsApplyTransforms -d 3 -e 3 -i "$temp" -r "$warped_NMT" \
        -t $affine \
        -t $field -o "$warped_temp_folder/warped_$(basename "$temp")"
done