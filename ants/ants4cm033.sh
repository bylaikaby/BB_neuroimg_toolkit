#!/bin/bash
#
ana_input='/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/anat/msub-CM032_run-03_FLASH_BRAIN.nii'

ana
template_CMT='/mnt/d/OPTO_fMRI_CM/Templates/CMT/NMT_warped/NMT2CMT_Warped.nii'
template_NMT='/mnt/d/OPTO_fMRI_CM/Templates/NMT_v2.0_sym/NMT_v2.0_sym/NMT_v2.0_sym_SS.nii.gz'
norm_dir='/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/norm/ants/'
func_dir='/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/norm/ants/func_test'
warped_funcs='/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/norm/ants/func_warped'


warped_ana_input=${norm_dir}warped.nii.gz

# post_landmark_flow_field='/mnt/d/CM032_bids/sub-CM032/norm/u_rc2wrsssub-CM032_run-03_FLASHdesc_ss_ref(NMT_v2.0_sym_SS)_mreg2d_volume_Template.nii'




# analysis_dir='/mnt/d/CM032_bids_NEW/sub-CM032/first_level_analysis'
# cd $analysis_dir

# func_orig='/mnt/d/CM032_bids_NEW/sub-CM032/func'
# mkdir func_copy
# cp -r $func_orig/r* ./func_copy

# mkdir warped_ana
# warped_ana='ana2temp'
# make the output to be norm_dir/ana_warped2ants_template.nii
mkdir $func_dir
mkdir $norm_dir
mkdir $warped_funcs
#only perform this if the output file doesn't exist
if [ ! -f $norm_dir/Warped.nii.gz ]; then
    # run the registration
antsRegistrationSyNQuick.sh -d 3 -m $ana_input -f $template_CMT -o ${norm_dir}
else

# else also run ants but avoid override
antsRegistrationSyNQuick.sh -d 3 -m $warped_ana_input -f $template_NMT -o ${norm_dir}secondary
fi

syn_field=${norm_dir}1Warp.nii.gz
syn_affine=${norm_dir}0GenericAffine.mat
func_mean='/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/func/meansub-CM032_task-MSTIM_run-01_EPI.nii'

# #for all the functional files in the func_dir, apply the transform to them and save them in the warped_funcs directory
# for func in $func_dir/*; do
#     # Check if $func contains ".gz"
#     if [[ $func != *.gz ]]; then
#         gzip "$func"
#         func="$func.gz"
#     fi

#     # antsApplyTransforms command using $gzipped_func
#     antsApplyTransforms -v -d 3 -e 4 -i "$gzipped_func" -r $func_mean -t $syn_field -t $syn_affine -o "$warped_funcs/warped_$(basename "$func").nii"
# done

# for func in "${funcs[@]}"; do
#     # Check if $func contains ".gz"
#     if [[ $func != *.gz ]]; then
#         gzipped_func="${func}.gz"
#     else
#         gzipped_func="$func"
#         $func=${$func%.gz}
#     fi

#     # antsApplyTransforms command using $gzipped_func
#     antsApplyTransforms -d 3 -e 3 -i "$gzipped_func" -r "$func_mean" \
#         -t ./Ana2Temp/with_landmark_0Warp.nii.gz -t ./Ana2Temp/with_landmark_1GenericAffine.mat \
#         -t ./Ana2Temp/with_landmark_2Warp.nii.gz -o "./warped_funcs/warped_$(basename "$func").nii"
# done