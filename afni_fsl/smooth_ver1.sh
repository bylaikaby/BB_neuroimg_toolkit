#!/bin/bash

# Define the directory containing the files
files_dir="./runs/runs_QCed"

# Determine the parent directory of the files directory
parent_dir=$(dirname "$files_dir")

# Define the output directory
output_dir="$parent_dir/smoothed"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Define the smoothing FWHM (in mm)
smoothing_fwhm=2

# Calculate the standard deviation for the smoothing FWHM
smoothing_sd=$(echo "$smoothing_fwhm / 2.3548" | bc -l)

# List of files to process
files=("$files_dir"/*.nii)

for file in "${files[@]}"; do
    # Extract the base name of the file without the directory and extension
    base_name=$(basename "$file" .nii)
    echo "$base_name"
    
    # Create the output file name based on the base name
    output_name="$output_dir/smoothed_${base_name}.nii"
    
    # Apply smoothing to the filtered file
    fslmaths "$file" -s "$smoothing_sd" "$output_name"
done
