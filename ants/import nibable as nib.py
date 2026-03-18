import nibabel as nib
import numpy as np

atlas=nib.load(r"D:\OPTO_fMRI_CM\Templates\NMT_v2.0_sym\NMT_v2.0_sym\supplemental_ARM\ARM_5_in_NMT_v2.1_sym.nii.gz")
atlas_data=atlas.get_fdata()
#get atlas data dimensions
atlas_shape=atlas_data.shape
print(atlas_shape)