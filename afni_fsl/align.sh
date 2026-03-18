#!/bin/bash

files=(
    HenryGroup_cm044_20251120a_73_1_1.nii
    HenryGroup_cm044_20251120a_74_1_1.nii
    HenryGroup_cm044_20251120b_6_1_1.nii
    HenryGroup_cm044_20251120b_7_1_1.nii
    HenryGroup_cm044_20251120b_15_1_1.nii
)

# 1. Within-run motion cord:\OPTO_fMRI_CM\Code\AccuMRNorm_ver_Binbin\bash_shell_scripts\ants\ants4cm044.shction → create mean image of first run as final reference
echo "=== Step 1: Within-run motion correction ==="
for f in "${files[@]}"; do
    base=$(basename "$f" .nii)
    [[ -f "${base}_mcf.nii.gz" ]] && continue
    
    echo "Within-run alignment: $f"
    3dvolreg -prefix "${base}_mcf.nii.gz" \
              -heptic -1Dfile "${base}_motion.txt" \
             "$f"
done
echo "Done within-run alignment"

# Create high-SNR reference = mean of first run after within-run correction
ref_mean=ref_mean.nii.gz
3dTstat -mean -prefix $ref_mean "${files[0]%.*}_mcf.nii.gz"

# 2. Between-run alignment to the common reference
echo "=== Step 2: Between-run alignment to first run mean ==="
for f in "${files[@]}"; do
    base=$(basename "$f" .nii)
    infile="${base}_mcf.nii.gz"
    outfile="${base}_aligned.nii"
    
    [[ -f "$outfile" ]] && continue
    
    echo "Between-run alignment: $f"
    3dvolreg -prefix "$outfile" \
             -base $ref_mean -heptic \
             "$infile"
done

# Clean up intermediate files if you want
rm *mcf.nii.gz 

echo "Done inter-run alignment"

