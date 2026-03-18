#!/usr/bin/env bash
# Usage: ./qc.sh yourfile.nii.gz

f=$1
base=${f%.nii*}
base=${base%.gz}

# # # 1. Motion correction
3dvolreg -base 0 -prefix ${base}_mc.nii.gz -1Dfile ${base}_motion.1D "$f"

# # 2. One plot with motion + FD + censor bars
# # instead of 1dplot → use 1dplot.py
# # Step 1: Compute censor file (enorm >0.2 mm, + prev TR; creates ${base}_censor.1D)
# # 1. Create proper censor file using the modern, short syntax
# #    For NHP: use 0.2 mm (not 1.2 — 1.2 is for human FD!)
1d_tool.py -infile ${base}_motion.1D -set_nruns 1\
           -censor_motion 0.2 ${base}  -overwrite
# 1d_tool.py -infile ${base}_motion.1D -show_mmms -derivative \

# 2. Plot with correct red bars using the file that 1d_tool.py just wrote
1dplot.py -sepscl \
          -ylabels VOLREG \
          -infiles ${base}_motion.1D \
          -censor_files ${base}_censor.1D\
          -censor_RGB red \
          -censor_hline 0.2 \
          -title "${base} | red = censored (>0.2 mm)" \
          -prefix QC_${base}_motion.png
# # # 3. Movie (PNG frames)
# mkdir -p movie_${base}
# @snapshot_volreg ${base}_mc.nii.gz "$f" movie_${base}

# echo "Done → QC_${base}_motion.png + movie_${base}/*.png"