#! /bin/bash


ana_to_seg='/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/norm/ants/ana_NMT_Warped.nii'
template_seg_priors='/mnt/d/OPTO_fMRI_CM/Templates/NMT_v2.0/TPM%d.nii'

ana_mask='/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/anat/ana_NMT_Warped_mask.nii'
fslmaths $ana_to_seg -thr 0.5 -bin $ana_mask

seg_dir='/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/norm/ants/ants_segmentation'
mkdir -p $seg_dir

# segmentation with ANTs

antsAtroposN4.sh -d 3 -c 3 -a $ana_to_seg -x $ana_mask -o $seg_dir -p $template_seg_priors 