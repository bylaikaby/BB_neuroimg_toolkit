#!/bin/bash

INPUT="sub*.nii"   # ← your 3dTproject outputs

mask=/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/anat/test_mask.nii

for base in $INPUT ; do
    out="${base%.nii}_sf.nii"

    3dBandpass \
        -input "$base" \
        -mask "$mask" \
        -prefix "$out" \
        -blur 1.5 \
        -band 0.006 0.1\
done