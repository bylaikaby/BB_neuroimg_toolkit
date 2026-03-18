#!/bin/bash

# Define the template and subject files
TEMPLATE="./norm/ana_NMT_InverseWarped.nii"
SUBJECT="./upsampled_mask_epi.nii"
OUTPUT_PREFIX="./inversed_transformed_nmt"

# Run antsRegistrationSyNQuick.sh to perform the registration
antsRegistrationSyNQuick.sh \
  -d 3 \
  -m $TEMPLATE \
  -f $SUBJECT \
  -o $OUTPUT_PREFIX
#resamplebyspacing 
#ResampleImageBySpacing 3 mask.nii anat_resampled.nii 0.25 0.25 0.25

# # # Define the output file for the resampled template
# RESAMPLED_TEMPLATE="./inversed_transformed_nmt_resampled.nii.gz"

# # Use antsApplyTransforms to apply the transformations and resample to template resolution
# antsApplyTransforms \
#   --dimensionality 3 \
#   --input $TEMPLATE \
#   --output $RESAMPLED_TEMPLATE \
#   --reference-image $TEMPLATE \
#   --transform [${OUTPUT_PREFIX}1Warp.nii.gz, 0]\
#     --transform [${OUTPUT_PREFIX}0GenericAffine.mat, 0] \

  

