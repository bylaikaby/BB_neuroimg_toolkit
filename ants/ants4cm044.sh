#!/bin/bash
#


# Define input paths for analysis
ana_input='/mnt/d/cm044_2011/mask.nii'

# Define template paths for CMT and NMT
template_CMT='/mnt/d/OPTO_fMRI_CM/Templates/CMT/NMT_warped/NMT2CMT_Warped.nii'
template_NMT='/mnt/d/OPTO_fMRI_CM/Templates/NMT_v2.0_sym/NMT_v2.0_sym/NMT_v2.0_sym_SS.nii.gz'

# Define directories for normalization and output #change below outputs
norm_dir='/mnt/d/cm044_2011/norm/' 
func_dir='/mnt/d/cm044_2011/func2norm/'
warped_funcs='/mnt/d/cm044_2011/func2norm/'

# # Define paths for post landmark flow fields and analysis directories
# # post_landmark_flow_field='/mnt/d/CM032_bids/sub-CM032/norm/u_rc2wrsssub-CM032_run-03_FLASHdesc_ss_ref(NMT_v2.0_sym_SS)_mreg2d_volume_Template.nii'
# # analysis_dir='/mnt/d/CM032_bids_NEW/sub-CM032/first_level_analysis'

# # Set up directories for functional data copies and warped outputs
# # func_orig='/mnt/d/CM032_bids_NEW/sub-CM032/func'
# # mkdir func_copy
# # cp -r $func_orig/r* ./func_copy

# mkdir warped_ana
# warped_ana='ana2temp'
# Make directories for normalization and warped functional files
mkdir -p $func_dir
mkdir -p $norm_dir
mkdir -p $warped_funcs

# Perform CMT template registration if the output file doesn't exist
cmt_warped_ana=${norm_dir}ana_CMT_Warped.nii.gz
if [ ! -f ${cmt_warped_ana} ]; then
    antsRegistrationSyNQuick.sh -d 3 -m $ana_input -f $template_CMT -o ${norm_dir}ana_CMT_
    gunzip -k -f $cmt_warped_ana
fi  

# Perform NMT template registration if the output file doesn't exist
nmt_warped_ana=${norm_dir}ana_NMT_Warped.nii.gz
if [ ! -f ${nmt_warped_ana} ]; then
    antsRegistrationSyNQuick.sh -d 3 -m $cmt_warped_ana -f $template_NMT -o ${norm_dir}ana_NMT_
    gunzip -k -f $nmt_warped_ana
fi

# Define paths for transformation fields from CMT and NMT
syn_field2CMT=${norm_dir}ana_CMT_1Warp.nii
syn_affine2CMT=${norm_dir}ana_CMT_0GenericAffine.mat
syn_field2NMT=${norm_dir}ana_NMT_1Warp.nii
syn_affine2NMT=${norm_dir}ana_NMT_0GenericAffine.mat

invsyn_field2CMT=${norm_dir}ana_CMT_1InverseWarp.nii.gz
invsyn_field2NMT=${norm_dir}ana_NMT_1InverseWarp.nii.gz
# Define path for mean functional image
# func_mean='/mnt/d/RawData/RawData/sub-cm042_BIDS/sub-cm042/func/meansub-cm042_run-12_EPI.nii'

# # Apply transformations to all functional files in func_dir and save in warped_funcs directory
# for func in $func_dir/*; do
#     nmt_warped_func="$warped_funcs/$(basename "$func" .nii)_NMT_Warped.nii"
#     if [ ! -f "$nmt_warped_func" ]; then
#         antsApplyTransforms -v -d 3 -e 3 -i $func -r $func_mean -t $syn_field2NMT -t [$syn_affine2NMT,0] -t $syn_field2CMT -t [$syn_affine2CMT,0] -o $nmt_warped_func
#     fi
# done



# inverse segmentation to native space 
template_seg_priors_dir='/mnt/d/OPTO_fMRI_CM/Templates/NMT_v2.0/TPM%d.nii'
inverse_seg_dir='/mnt/d/cm044_2011/inverse_seg'

mkdir -p $inverse_seg_dir
# Segmentation process (modified to apply inverse transformations)
for ((i=1; i<=3; i+=1)); do
    template_seg_prior="${template_seg_priors_dir/\%d/$i}"
    inverse_warped_seg="$inverse_seg_dir/TPM${i}_InverseWarped.nii.gz"
    
    if [ ! -f "$inverse_warped_seg" ]; then
        antsApplyTransforms -v -d 3 -e 3 -i "$template_seg_prior" -r "$func_mean" \
            -t "$invsyn_field2CMT" -t ["$syn_affine2CMT",1] \
            -t "$invsyn_field2NMT" -t ["$syn_affine2NMT",1] \
            -o "$inverse_warped_seg"
    gunzip -f "$inverse_warped_seg"   
    fi

done