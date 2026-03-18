#!/bin/bash

INPUT="runs/runs_QCed/cm044*aligned.nii"   # ← your 3dTproject outputs

# mask="anat_mask/mask_in_epi_binary.nii"



# Determine the parent directory of the files directory
parent_dir=$(dirname "$INPUT")

# Define the output directory
concat_output_dir="$parent_dir/concat_scans"
ICA_output_dir="$parent_dir/ICA_denoised_scans"


# printf "%s\n" $INPUT > scans.txt

# melodic -i scans.txt \
#         -o cm044_melodic \
#         --tr=2 \
#         --approach=tica\
#         --report -m $mask\
#         --nobet -v


# fslmerge -t concat_output_dir/concat_scan.nii $(printf "%s\n" "$INPUT" )
# fsl_regfilt -i concat_output_dir/concat_scan.nii   \
#                 -d ./cm044_melodic/melodic_mix \
#                 -o "ICA_output_dir/concat_scans_ICA_filtered.nii" \
#                 -f "1, 12, 14, 15, 19, 20, 21, 22, 23, 24, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44"

# # Create output dir change the directory name for everything below
# mkdir -p ICA_output_dir

# Auto-split using scans.txt order
start=0
while IFS= read -r orig_scan; do
    [[ -z "$orig_scan" ]] && continue

    # Get subject filename (e.g., cm044_20251120_01_aligned.nii)
    base=$(basename "$orig_scan" .nii)  # strips path & .nii
    
    # Get number of volumes from ORIGINAL scan (critical!)
    nv=$(fslinfo "$orig_scan" | awk '/^dim4/ {print $2}')
    
    # echo "✂️ Extracting $base (vols $start – $((start + nv - 1)))"
    
    # Extract from denoised merged file
    fslroi $ICA_output_dir/concat_scans_ICA_filtered.nii \
            $ICA_output_dir/"${base}_denoised.nii" \
            $start $nv
    fslmaths "ICA_denoised_scans/${base}_denoised.nii" \
         -kernel gauss 0.85 \
         -fmean \
         "$ICA_output_dir/${base}_denoised_smoothed.nii"
    # 3dTproject -input "${base}.nii" \
    #            -prefix "${CUSTOM_PREFIX}_${base}.nii" \
    #            -ort "${base%_aligned}_motion.txt" \
    #            -stopband 0 0.00099 \
    #             -automask \
    #            -polort 2 
    ((start += nv))
done < scans.txt


# Define the output file
output_motion_file="${output_folder}/all_runs_motion.txt"

# Initialize an empty output file
> "$output_motion_file"

# Loop through each motion file and append it to the output file
for f in "${motion_files[@]}"; do
    cat "$f" >> "$output_motion_file"
done
