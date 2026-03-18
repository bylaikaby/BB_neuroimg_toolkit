#!/bin/bash

# Define output folder
output_folder='./runs_QCed'
mkdir -p "$output_folder"

files=(*.nii)
anat=(/mnt/d/OPTO_fMRI_CM/BIDS_data/CM032_BIDS/sub-CM032/anat/test_mask.nii)
anat_dir=$(dirname "$anat")

# # 1. Within-run motion correction → create mean image of first run as final reference
echo "=== Step 1: Within-run motion correction ==="
for f in "${files[@]}"; do
    base=$(basename "$f" .nii)
    motion_file="${output_folder}/${base}_motion.txt"
    mcf_file="${output_folder}/${base}_mcf.nii.gz"
    
    [[ -f "$mcf_file" ]] && continue
      
    echo "Within-run alignment: $f"
    3dvolreg -prefix "$mcf_file" \
              -heptic -1Dfile "$motion_file" \
             "$f"
done
echo "Done within-run alignment"

# Create high-SNR reference = mean of first run after within-run correction
ref_mean="${output_folder}/ref_mean.nii.gz"
first_base=$(basename "${files[0]}" .nii)
first_mcf_file="${output_folder}/${first_base}_mcf.nii.gz"

3dTstat -mean -prefix "$ref_mean" "$first_mcf_file"

flirt -in "$anat" \
      -ref "$ref_mean" \
      -out "${anat_dir}/mask_in_epi.nii" \
      -dof 6 \
#       -cost mutualinfo

fslmaths "${anat_dir}/mask_in_epi.nii"  -ero "${anat_dir}/mask_in_epi_thresholded.nii"



# 2. Between-run alignment to the common reference
echo "=== Step 2: Between-run alignment to first run mean ==="
for f in "${files[@]}"; do
    base=$(basename "$f" .nii)
    infile="${output_folder}/${base}_mcf.nii.gz"
    outfile="${output_folder}/r${base}.nii"
    motion_file="${output_folder}/${base}_motion.txt"
    
    [[ -f "$outfile" ]] && continue
    
    echo "Between-run alignment: $f"
    3dvolreg -prefix "$outfile" \
             -base "$ref_mean" -heptic \
             -1Dfile "$motion_file" \
             "$f"
done

# Clean up intermediate files if you want
rm -f "${output_folder}"/*mcf.nii.gz 

echo "Done inter-run alignment"

# 3. Motion correction and censoring using 1d_tool.py
echo "=== Step 3: Motion correction and censoring ==="
for f in "${files[@]}"; do
    base=$(basename "$f" .nii)
    motion_file="${output_folder}/${base}_motion.txt"
    censor_prefix="${output_folder}/${base}"
    [[ -f "$censor_file" ]] && continue
    
    echo "Censoring motion: $f"
    1d_tool.py -infile $motion_file \
               -set_nruns 1 \
               -censor_motion 0.2 $censor_prefix -overwrite
done
echo "Done motion correction and censoring"

# 4. Plotting using 1dplot.py
echo "=== Step 4: Plotting motion parameters ==="
for f in "${files[@]}"; do
    base=$(basename "$f" .nii)
    motion_file="${output_folder}/${base}_motion.txt"
    censor_file="${output_folder}/${base}_censor.1D"
    plot_file="${output_folder}/QC_${base}_motion.png"
    
    [[ -f "$plot_file" ]] && continue
    
    echo "Plotting motion: $f"
    1dplot.py -sepscl \
              -ylabels VOLREG \
              -infiles "$motion_file" \
              -censor_files "$censor_file" \
              -censor_RGB red \
              -censor_hline 0.2 \
              -title "${base} | red = censored (>0.2 mm)" \
              -prefix "$plot_file"
done
echo "Done plotting"


