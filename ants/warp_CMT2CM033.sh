#!/bin/bash


#shell script to convert from CMT to cm033 space


CMT_orig='/mnt/d/OPTO_fMRI_CM/Templates/CMT/CMT.nii'
CMT_warped='/mnt/d/OPTO_fMRI_CM/Templates/CMT/CMT2cm033/CMT_warped'
CMT_folder="/mnt/d/OPTO_fMRI_CM/Templates/CMT/CMT2cm033"
cm033="/mnt/d/OPTO_fMRI_CM/Templates/CMT/print_brain_cm033.nii"

CMTs=($CMT_folder/CMT*.nii)



# Step 1, warp the CMT_SS to the CMT.

antsRegistrationSyNQuick.sh -f "$cm033" -m "$CMT_orig" -o "$CMT_warped/CMT2cm033_"

field="$CMT_warped/CMT2cm033_1Warp.nii.gz"
affine="$CMT_warped/CMT2cm033_0GenericAffine.mat"


for CMT in "${CMTs[@]}"; do
    
    # antsApplyTransforms command using $gzipped_func
    antsApplyTransforms -d 3 -e 3 -i "$CMT" -r "$CMT_warped/CMT2cm033_Warped.nii.gz" \
        -t $affine \
        -t $field -o "$CMT_warped/CMT2cm033_$(basename "$CMT")"
    
done

cd $CMT_warped
gunzip *.nii.gz