#!/bin/bash

NMT_orig="/mnt/d/OPTO_fMRI_CM/Templates/NMT_v2.0/NMT_v2.0_sym_SS.nii"
NMT_warped="/mnt/d/OPTO_fMRI_CM/Templates/CMT/NMT_warped"
NMT_folder="/mnt/d/OPTO_fMRI_CM/Templates/CMT/NMT2warp"
CMT="/mnt/d/OPTO_fMRI_CM/Templates/CMT/CMT.nii"

NMTs=($NMT_folder/TPM*)

atlas="/mnt/d/OPTO_fMRI_CM/Templates/NMT_v2.0_sym/NMT_v2.0_sym/supplemental_ARM/ARM_5_in_NMT_v2.1_sym.nii.gz"

#atlas="/mnt/d/OPTO_fMRI_CM/Templates/NMT_v2.0_sym/NMT_v2.0_sym/ARM_in_NMT_v2.1_sym.nii.gz"

field="$NMT_warped/NMT2CMT_1Warp.nii.gz"
affine="$NMT_warped/NMT2CMT_0GenericAffine.mat"

mkdir -p "$NMT_warped/atlases"
output="$NMT_warped/atlases/NMT2CMT_$(basename "$atlas")"
    # antsApplyTransforms command using $gzipped_func
antsApplyTransforms -d 3 -e 3 -i "$atlas" -r "$NMT_warped/NMT2CMT_Warped.nii.gz" \
        -t $affine \
        -t $field -o "$output" -v
    


gunzip $output