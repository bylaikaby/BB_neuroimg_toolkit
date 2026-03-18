#!/bin/bash



# Define input variables
input="/mnt/d/CM032_bids/sub-CM032/anat/sub-CM032_run-03_FLASH_BETss_copy.nii"
template="/mnt/d/AccuMRnorm_binbin/NMT_v2.0/NMT_v2.0_sym_SS.nii"
post_landmark_flow_field="/mnt/d/CM032_bids_old/sub-CM032/norm/u_rc2wrsssub-CM032_run-03_FLASHdesc_ss_ref(NMT_v2.0_sym_SS)_mreg2d_volume_Template.nii"
func_mean="/mnt/d/CM032_bids/sub-CM032/func/meansub-CM032_task-MSTIM_run-01_EPI_copy.nii"

func_folder='/mnt/d/CM032_bids/sub-CM032/func'
output_folder=${func_folder}/quick_warped
# Define the IDs of the functional images to process
ids=(03 04)

# Create a directory to store intermediate files
mkdir -p $output_folder

# Perform registration using ANTs
antsRegistrationSyNQuick.sh -d 3 -m "$input" -f "$template" -i "$post_landmark_flow_field" -t b -o "with_landmark_"

antsRegistrationSyNQuick.sh -d 3 -m "$input" -f "$template" -i "$post_landmark_flow_field" -t t -o "with_landmark_linear"


# Create a directory to store the warped functional images
mkdir -p warped_funcs

cd $output_folder

# Iterate over each functional image ID
for id in "${ids[@]}"; do

    # Define the filename of the functional image
    func_filename="sub-CM032_task-OPTO_run-${id}_EPI.nii"
    ss_filename=ss_$func_filename
    bet4animal ${func_folder}/${func_filename} ${output_folder}/ss_funcs/${ss_filename}.gz -z 2 -f 0.2 -m

        # Check if the functional image is already gzipped
    if [[ ! -f "${output_folder}/ss_funcs/${ss_filename}.gz" ]]; then
        # Gzip the functional image
        gzip "${output_folder}/ss_funcs/${ss_filename}"
    fi

    antsRegistrationSyNQuick.sh -f $func_mean -m ${func_folder}/${func_filename} -t a -o initial_linear

    # Apply transformation using ANTs
    antsApplyTransforms -d 3 -e 3 -i ${output_folder}/ss_funcs/${ss_filename}.gz -r $template\
        -t $output_folder/initial_linear0GenericAffine.mat \
        -t $output_folder/with_landmark_0Warp.nii.gz -t $output_folder/with_landmark_1GenericAffine.mat\
        -t $output_folder/with_landmark_2Warp.nii.gz -o $output_folder/warped_funcs/warped_$ss_filename.nii
done

cd $func_folder     
gunzip *.gz