#!/bin/bash
#
input='/mnt/d/CM033_bids_new/sub-CM033/anat/csub-CM033_run-15_FLASH_BETss.nii'
template='/mnt/d/AccuMRnorm_binbin/NMT_v2.0/NMT_v2.0_sym_SS.nii'
post_landmark_flow_field='/mnt/d/CM032_bids/sub-CM032/norm/u_rc2wrsssub-CM032_run-03_FLASHdesc_ss_ref(NMT_v2.0_sym_SS)_mreg2d_volume_Template.nii'
func_mean='/mnt/d/CM032_bids/sub-CM032/func/meanrsub-CM032_run-02_EPI.nii'

windows_folder=$(pwd)/demo_funcs
gzip -k $windows_folder/*
funcs=($(pwd)/demo_funcs/*)

mkdir Ana2Temp
cd Ana2Temp
antsRegistrationSyNQuick.sh -d 3 -m $input -f $template  -t b -o "with_landmark_"
cd ..

mkdir warped_funs
for func in "${funcs[@]}"; do
    # Check if $func contains ".gz"
    if [[ $func != *.gz ]]; then
        gzipped_func="${func}.gz"
    else
        gzipped_func="$func"
        $func=${$func%.gz}
    fi

    # antsApplyTransforms command using $gzipped_func
    antsApplyTransforms -d 3 -e 3 -i "$gzipped_func" -r "$func_mean" \
        -t ./Ana2Temp/with_landmark_0Warp.nii.gz -t ./Ana2Temp/with_landmark_1GenericAffine.mat \
        -t ./Ana2Temp/with_landmark_2Warp.nii.gz -o "./warped_funcs/warped_$(basename "$func").nii"
done