#!bin/bash

#!/bin/bash

# Define the directory containing the motion files
motion_files="/mnt/d/cm044_1212/runs/runs_QCed/*3[59]*_motion.txt"

# Define the output file
output_motion_file="/mnt/d/cm044_1212/runs/359.txt"

cat "${motion_files[@]}" > "$output_motion_file"

echo "Motion files concatenated to $output_motion_file"
