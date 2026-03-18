#!/bin/bash

NMT_orig="/mnt/d/OPTO_fMRI_CM/Templates/NMT_v2.0/NMT_v2.0_sym_SS.nii"
NMT_warped="/mnt/d/OPTO_fMRI_CM/Templates/CMT/NMT_warped"
NMT_folder="/mnt/d/OPTO_fMRI_CM/Templates/CMT/NMT2warp"
CMT="/mnt/d/OPTO_fMRI_CM/Templates/CMT/CMT.nii"

NMTs=($NMT_folder/TPM*)



# Step 1, warp the NMT_SS to the CMT.

antsRegistrationSyNQuick.sh -f "$CMT" -m "$NMT_orig" -o "$NMT_warped/NMT2CMT_"

field="$NMT_warped/NMT2CMT_1Warp.nii.gz"
affine="$NMT_warped/NMT2CMT_0GenericAffine.mat"


for NMT in "${NMTs[@]}"; do
    
    # antsApplyTransforms command using $gzipped_func
    antsApplyTransforms -d 3 -e 3 -i "$NMT" -r "$NMT_warped/NMT2CMT_Warped.nii.gz" \
        -t $affine \
        -t $field -o "$NMT_warped/NMT2CMT_$(basename "$NMT")"
    
done

cd $NMT_warped
gunzip *.nii.gz