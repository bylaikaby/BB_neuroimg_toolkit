#%%
import nibabel as nib
import numpy as np
from pathlib import Path
from typing import Union, Tuple, Optional

def extract_ct_threshold(
    input_path: Union[str, Path],
    output_path: Optional[Union[str, Path]] = None,
    hu_min: float = -1000,
    hu_max: float = 1000,
    mode: str = 'mask',
    fill_value: float = 0,
    save: bool = True
) -> Union[np.ndarray, Tuple[np.ndarray, np.ndarray, nib.Nifti1Header]]:
    """
    Extract CT voxels within HU threshold range.
    
    Parameters
    ----------
    input_path : str or Path
        Path to input CT (.nii or .nii.gz)
    output_path : str or Path, optional
        Path for output. Auto-generated if None and save=True
    hu_min : float
        Minimum HU threshold (inclusive)
    hu_max : float
        Maximum HU threshold (inclusive)
    mode : str
        'mask' - Binary mask (0/1)
        'masked' - Original HU values inside range, fill_value outside
        'extracted' - HU values inside range, fill_value outside (alias for masked)
    fill_value : float
        Value for voxels outside threshold (default 0)
    save : bool
        Whether to save NIfTI file (returns array only if False)
        
    Returns
    -------
    If save=False: numpy array of extracted data
    If save=True: Path to saved file
    
    Examples
    --------
    # Extract bone (HU > 200)
    extract_ct_threshold('ct.nii.gz', hu_min=200, hu_max=3000, mode='mask')
    
    # Extract soft tissue, keeping original values
    extract_ct_threshold('ct.nii.gz', hu_min=-50, hu_max=100, mode='masked', 
                        output_path='soft_tissue.nii.gz')
    """
    
    # Load CT
    img = nib.load(input_path)
    data = img.get_fdata()
    affine = img.affine
    header = img.header.copy()
    
    # Create binary mask for threshold range
    mask = (data >= hu_min) & (data <= hu_max)
    
    # Generate output based on mode
    if mode == 'mask':
        result = mask.astype(np.uint8)
        # Update header for binary data
        header.set_data_dtype(np.uint8)
    elif mode in ['masked', 'extracted']:
        result = data.copy()
        result[~mask] = fill_value
        # Preserve original dtype if possible
        header.set_data_dtype(data.dtype)
    else:
        raise ValueError(f"Mode '{mode}' not recognized. Use 'mask' or 'masked'")
    
    # Save or return
    if not save:
        return result
    
    # Generate output path if not provided
    if output_path is None:
        input_path = Path(input_path)
        suffix = f"_th{hu_min}_{hu_max}.nii.gz"
        output_path = input_path.parent / (input_path.stem.replace('.nii', '') + suffix)
    else:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Save NIfTI
    out_img = nib.Nifti1Image(result, affine, header)
    nib.save(out_img, output_path)
    
    print(f"Extracted {mask.sum()} voxels ({mask.sum()/mask.size*100:.2f}%) in range [{hu_min}, {hu_max}]")
    print(f"Saved to: {output_path}")
    
    return output_path


# Convenience functions for common CT tissue types
def extract_ct_bone(input_path, output_path=None, hu_min=200, hu_max=3000):
    """Extract bone (HU > 200)"""
    return extract_ct_threshold(input_path, output_path, hu_min, hu_max, mode='mask')

def extract_ct_lung(input_path, output_path=None, hu_min=-1000, hu_max=-500):
    """Extract lungs/air (HU -1000 to -500)"""
    return extract_ct_threshold(input_path, output_path, hu_min, hu_max, mode='mask')

def extract_ct_soft_tissue(input_path, output_path=None, hu_min=-50, hu_max=100):
    """Extract soft tissue"""
    return extract_ct_threshold(input_path, output_path, hu_min, hu_max, mode='masked')

# %%
# Example usage
if __name__ == "__main__":
    # Example 1: Create bone mask
    extract_ct_threshold(
        r"V:\cm037\injection_surgery\ct_cropped.nii",
        hu_min=100, 
        hu_max=3000,
        mode='masked',
        output_path="V:\cm037\injection_surgery\ct_cropped_skull.nii"
    )
    
    # # Example 2: Extract soft tissue with original HU values
    # extract_ct_threshold(
    #     'input_ct.nii.gz',
    #     hu_min=-50,
    #     hu_max=80,
    #     mode='masked',
    #     fill_value=-1000,  # Set background to air value
    #     output_path='soft_tissue.nii.gz'
    # )
    
    # # Example 3: Just get the array without saving
    # lung_mask = extract_ct_threshold(
    #     'input_ct.nii.gz',
    #     hu_min=-1000,
    #     hu_max=-600,
    #     mode='mask',
    #     save=False
    # )
# %%
