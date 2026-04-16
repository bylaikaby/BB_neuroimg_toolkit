#%%
import nibabel as nib
import numpy as np
from pathlib import Path
from typing import Union, Tuple, Optional, List
import warnings

def convert_dicom_to_nifti(
    dicom_folder: Union[str, Path],
    output_path: Optional[Union[str, Path]] = None,
    series_pattern: Optional[str] = None,
    sort_by: str = 'InstanceNumber',
    rescale_hu: bool = True
) -> str:
    """
    Convert DICOM CT series to NIfTI format.
    
    Requires pydicom package. Install with: pip install pydicom
    
    Parameters
    ----------
    dicom_folder : str or Path
        Folder containing DICOM files
    output_path : str or Path, optional
        Output NIfTI path. Auto-generated if None
    series_pattern : str, optional
        Pattern to filter DICOM files (e.g., '202' to match series 202)
        If None, uses the first matching series found
    sort_by : str
        DICOM tag to sort slices by: 'InstanceNumber' (default) or 'SliceLocation'
    rescale_hu : bool
        If True, apply rescale slope/intercept to convert to Hounsfield Units
    
    Returns
    -------
    Path to saved NIfTI file
    
    Examples
    --------
    # Convert all DICOMs in folder
    convert_dicom_to_nifti('path/to/dicom_folder', 'output.nii.gz')
    
    # Convert specific series
    convert_dicom_to_nifti('path/to/dicom_folder', 'ct_native.nii.gz', series_pattern='202')
    """
    try:
        import pydicom
    except ImportError:
        raise ImportError(
            "pydicom is required for DICOM conversion. Install with: pip install pydicom"
        )
    
    dicom_folder = Path(dicom_folder)
    
    # Get all DICOM files
    dicom_files = sorted(dicom_folder.glob('*.dcm'))
    if not dicom_files:
        raise FileNotFoundError(f"No .dcm files found in {dicom_folder}")
    
    # Read and sort DICOMs
    datasets = []
    for f in dicom_files:
        try:
            ds = pydicom.dcmread(f, stop_before_pixels=False)
            datasets.append(ds)
        except Exception as e:
            warnings.warn(f"Could not read {f}: {e}")
    
    if not datasets:
        raise ValueError("No valid DICOM files could be read")
    
    # Filter by series pattern if specified
    if series_pattern:
        datasets = [ds for ds in datasets if series_pattern in str(ds.SeriesInstanceUID or '')]
        if not datasets:
            raise ValueError(f"No DICOMs found matching series pattern '{series_pattern}'")
    
    # Sort by specified attribute
    if sort_by == 'InstanceNumber':
        datasets.sort(key=lambda ds: int(ds.InstanceNumber) if hasattr(ds, 'InstanceNumber') else 0)
    elif sort_by == 'SliceLocation':
        datasets.sort(key=lambda ds: float(ds.SliceLocation) if hasattr(ds, 'SliceLocation') else 0)
    
    # Extract pixel array and metadata
    try:
        pixel_array = np.stack([ds.pixel_array.astype(np.float32) for ds in datasets], axis=-1)
    except Exception as e:
        raise ValueError(f"Could not stack pixel arrays: {e}")
    
    # Get rescale parameters for HU conversion
    first_ds = datasets[0]
    
    if rescale_hu:
        slope = float(first_ds.RescaleSlope) if hasattr(first_ds, 'RescaleSlope') else 1.0
        intercept = float(first_ds.RescaleIntercept) if hasattr(first_ds, 'RescaleIntercept') else 0.0
        pixel_array = pixel_array * slope + intercept
    
    # Get affine from DICOM position
    affine = np.eye(4)
    
    # Pixel spacing (row, column)
    if hasattr(first_ds, 'PixelSpacing'):
        pixel_spacing = first_ds.PixelSpacing
        affine[0, 0] = pixel_spacing[1]  # Column direction
        affine[1, 1] = pixel_spacing[0]  # Row direction
    
    # Slice thickness
    if hasattr(first_ds, 'SliceThickness'):
        affine[2, 2] = first_ds.SliceThickness
    
    # Image position (origin)
    if hasattr(first_ds, 'ImagePositionPatient'):
        position = first_ds.ImagePositionPatient
        affine[0, 3] = position[0]
        affine[1, 3] = position[1]
        affine[2, 3] = position[2]
    
    # Create NIfTI header
    header = nib.Nifti1Header()
    header.set_data_shape(pixel_array.shape)
    
    # Create NIfTI image
    nii_img = nib.Nifti1Image(pixel_array, affine, header)
    
    # Generate output path
    if output_path is None:
        output_path = dicom_folder.parent / (dicom_folder.name + '.nii.gz')
    else:
        output_path = Path(output_path)
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    nib.save(nii_img, output_path)
    
    print(f"Converted {len(datasets)} slices to NIfTI")
    print(f"Shape: {pixel_array.shape}, HU range: [{pixel_array.min():.1f}, {pixel_array.max():.1f}]")
    print(f"Saved to: {output_path}")
    
    return str(output_path)


def batch_convert_ct_folders(
    base_folder: Union[str, Path],
    output_base: Optional[Union[str, Path]] = None,
    pattern: str = '*'
) -> dict:
    """
    Convert multiple CT DICOM folders to NIfTI.
    
    Parameters
    ----------
    base_folder : str or Path
        Base folder containing subfolders with DICOM files
    output_base : str or Path, optional
        Base output folder. Defaults to same location as input
    pattern : str
        Glob pattern to match subfolder names
        
    Returns
    -------
    Dictionary mapping folder names to output NIfTI paths
    """
    base_folder = Path(base_folder)
    
    if output_base is None:
        output_base = base_folder
    else:
        output_base = Path(output_base)
    
    results = {}
    
    # Find matching subfolders
    for folder in sorted(base_folder.glob(pattern)):
        if folder.is_dir():
            # Check if folder contains DICOM files
            dcm_files = list(folder.glob('*.dcm'))
            if dcm_files:
                output_name = folder.name + '.nii.gz'
                output_path = output_base / output_name
                
                try:
                    result_path = convert_dicom_to_nifti(folder, output_path)
                    results[folder.name] = result_path
                except Exception as e:
                    results[folder.name] = f"ERROR: {e}"
    
    return results


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


def subtract_contrast_ct(
    ct_contrast: Union[str, Path],
    ct_native: Union[str, Path],
    output_path: Optional[Union[str, Path]] = None,
    threshold: float = None,
    mode: str = 'vessel',
    algorithm: str = 'ratio',
    normalize: bool = False,
    body_hu_min: float = -300.0,
    min_vessel_size: int = 30,
    native_hu_max: float = 300.0,
    contrast_hu_min: float = 120.0,
    contrast_hu_max: float = 500.0,
    min_relative_increase: float = 0.25,
    save: bool = True
) -> Union[np.ndarray, Tuple[np.ndarray, np.ndarray, nib.Nifti1Header]]:
    """
    Generate vessel mask by comparing non-contrast CT from contrast-enhanced CT.

    This technique enhances blood vessels by detecting areas where contrast
    agent has accumulated (primarily vasculature).

    Parameters
    ----------
    ct_contrast : str or Path
        Path to contrast-enhanced CT (.nii or .nii.gz)
    ct_native : str or Path
        Path to non-contrast (native) CT (.nii or .nii.gz)
    output_path : str or Path, optional
        Path for output. Auto-generated if None and save=True
    threshold : float, optional
        Minimum value to consider as vessel. If None, uses Otsu auto-threshold.
        Higher values = stricter vessel detection.
    mode : str
        'vessel' - Binary mask of vessels (default)
        'enhancement' - Raw enhancement values
    algorithm : str
        'ratio' - Ratio method: contrast / native (default). Vessels show > 1
        'difference' - Positive difference: max(0, contrast - native)
        'signed_difference' - Raw signed subtraction: contrast - native
        'relative' - Relative enhancement: (contrast - native) / native * 100
    normalize : bool
        Whether to normalize images before comparison (False preserves HU space)
    body_hu_min : float
        Lower HU bound for coarse body mask. Used to suppress air/background
        false positives in vessel mode.
    min_vessel_size : int
        Minimum connected component size (voxels) kept in vessel mode.
    native_hu_max : float
        Upper HU bound in native scan for vessel candidates. Helps suppress
        bone/calcification false positives.
    contrast_hu_min : float
        Lower HU bound in contrast scan for vessel candidates. Helps suppress
        low-HU skin/soft-tissue noise.
    contrast_hu_max : float
        Upper HU bound in contrast scan for vessel candidates. Helps suppress
        very dense bone/calcification leakage.
    min_relative_increase : float
        Minimum relative enhancement required for vessel candidates:
        (contrast - native) / max(native, 1).
    save : bool
        Whether to save NIfTI file (returns array only if False)

    Returns
    -------
    If save=False: numpy array of result
    If save=True: Path to saved file

    Examples
    --------
    # Ratio-based vessel extraction (recommended)
    subtract_contrast_ct(
        'ct_with_contrast.nii.gz',
        'ct_without_contrast.nii.gz',
        output_path='vessels.nii.gz',
        algorithm='ratio'
    )

    # Difference-based with manual threshold
    subtract_contrast_ct(
        'ct_contrast.nii.gz',
        'ct_native.nii.gz',
        algorithm='difference',
        threshold=100
    )
    """

    # Load both CT scans
    img_contrast = nib.load(ct_contrast)
    img_native = nib.load(ct_native)

    data_contrast = img_contrast.get_fdata()
    data_native = img_native.get_fdata()

    # Check shape compatibility
    if data_contrast.shape != data_native.shape:
        raise ValueError(
            f"Shape mismatch: contrast={data_contrast.shape}, "
            f"native={data_native.shape}. Images must have same dimensions."
        )

    affine = img_contrast.affine
    header = img_contrast.header.copy()

    # Normalize if requested (handles intensity differences between scans)
    if normalize:
        # Percentile normalization to handle intensity variations
        contrast_norm = (data_contrast - np.percentile(data_contrast, 1)) / \
                       (np.percentile(data_contrast, 99) - np.percentile(data_contrast, 1))
        native_norm = (data_native - np.percentile(data_native, 1)) / \
                     (np.percentile(data_native, 99) - np.percentile(data_native, 1))
    else:
        contrast_norm = data_contrast
        native_norm = data_native

    # Compute enhancement based on algorithm
    if algorithm == 'ratio':
        # Ratio method: vessels show higher values in contrast
        # Add small epsilon to avoid division by zero
        epsilon = 1e-6
        enhancement = contrast_norm / (native_norm + epsilon)
        # Clip to reasonable range (0.5 to 5)
        enhancement = np.clip(enhancement, 0.5, 5)
        # Shift so that unchanged tissues are at 1 (not 0)
        enhancement = enhancement - 1.0

    elif algorithm == 'difference':
        # Positive difference only (ignore negative values from noise)
        enhancement = np.maximum(0, contrast_norm - native_norm)

    elif algorithm == 'signed_difference':
        # Raw signed subtraction; useful for HU inspection/QC.
        enhancement = contrast_norm - native_norm

    elif algorithm == 'relative':
        # Relative enhancement as percentage
        # Avoid division by zero
        mask = np.abs(native_norm) > 0.01
        enhancement = np.zeros_like(contrast_norm)
        enhancement[mask] = (contrast_norm[mask] - native_norm[mask]) / native_norm[mask] * 100
        # Clip to reasonable range
        enhancement = np.clip(enhancement, 0, 500)

    else:
        raise ValueError(
            f"Algorithm '{algorithm}' not recognized. Use 'ratio', 'difference', 'signed_difference', or 'relative'"
        )

    # Auto-threshold using Otsu's method if threshold not specified
    if threshold is None:
        # For binary thresholding, use Otsu's method
        # Flatten and compute histogram-based threshold
        flat_enh = enhancement.flatten()
        # Only use positive values for threshold computation
        flat_positive = flat_enh[flat_enh > 0]

        if len(flat_positive) > 0:
            # Otsu's method implementation
            threshold = otsu_threshold(flat_positive)
        else:
            threshold = 0.1  # Fallback

    # Generate output based on mode
    if mode == 'vessel':
        vessel_mask = (enhancement > threshold)

        # Keep candidates inside coarse body tissue to reduce background artifacts.
        body_mask = (data_native > body_hu_min) | (data_contrast > body_hu_min)
        vessel_mask &= body_mask

        # HU gating to suppress common non-vascular artifacts.
        # - Exclude very dense native voxels (bone/calcification)
        # - Keep only sufficiently enhanced/dense voxels in contrast scan
        hu_gate = (
            (data_native < native_hu_max)
            & (data_contrast > contrast_hu_min)
            & (data_contrast < contrast_hu_max)
        )
        vessel_mask &= hu_gate

        # Require meaningful relative increase to reduce high-density leakage.
        denom = np.maximum(data_native, 1.0)
        relative_increase = (data_contrast - data_native) / denom
        vessel_mask &= (relative_increase > min_relative_increase)

        # Remove tiny disconnected components when scipy is available.
        if min_vessel_size > 1:
            try:
                from scipy import ndimage as ndi
                labels, n_labels = ndi.label(vessel_mask)
                if n_labels > 0:
                    sizes = np.bincount(labels.ravel())
                    keep = sizes >= min_vessel_size
                    keep[0] = False
                    vessel_mask = keep[labels]
            except Exception:
                # Keep extraction robust even if scipy is unavailable.
                pass

        result = vessel_mask.astype(np.uint8)
        header.set_data_dtype(np.uint8)
    elif mode == 'enhancement':
        result = enhancement.astype(np.float32)
        header.set_data_dtype(np.float32)
    else:
        raise ValueError(f"Mode '{mode}' not recognized. Use 'vessel' or 'enhancement'")

    # Save or return
    if not save:
        return result

    # Generate output path if not provided
    if output_path is None:
        ct_contrast_path = Path(ct_contrast)
        suffix = f"_vessel.nii.gz" if mode == 'vessel' else f"_enhancement.nii.gz"
        output_path = ct_contrast_path.parent / (ct_contrast_path.stem.replace('.nii', '') + suffix)
    else:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

    # Save NIfTI
    out_img = nib.Nifti1Image(result, affine, header)
    nib.save(out_img, output_path)

    if mode == 'vessel':
        vessel_count = (result > 0).sum()
        print(f"Vessel mask: {vessel_count} voxels ({vessel_count/result.size*100:.3f}%)")
    else:
        print(f"Enhancement range: [{enhancement.min():.3f}, {enhancement.max():.3f}]")
    print(f"Threshold used: {threshold:.4f}")
    print(f"Algorithm: {algorithm}")
    print(f"Saved to: {output_path}")

    return output_path


def extract_vessels_best(
    ct_contrast: Union[str, Path],
    ct_native: Union[str, Path],
    output_path: Optional[Union[str, Path]] = None,
    threshold: Optional[float] = None,
    min_vessel_size: int = 50,
    save: bool = True
) -> Union[np.ndarray, str]:
    """
    Simplified high-quality vessel extraction with robust defaults.

    This path is intended as the default workflow:
    - signed HU subtraction (contrast - native)
    - fixed vessel-oriented HU gating to suppress bone/skin leakage
    - connected-component cleanup
    """
    img_contrast = nib.load(ct_contrast)
    img_native = nib.load(ct_native)
    data_contrast = img_contrast.get_fdata()
    data_native = img_native.get_fdata()

    if data_contrast.shape != data_native.shape:
        raise ValueError(
            f"Shape mismatch: contrast={data_contrast.shape}, native={data_native.shape}"
        )

    enhancement = data_contrast - data_native
    if threshold is None:
        threshold = 70.0

    vessel_mask = enhancement > threshold

    # Robust defaults tuned for CTA-like head scans.
    body_mask = (data_native > 20.0) | (data_contrast > 20.0)
    hu_gate = (
        (data_native < 160.0)
        & (data_contrast > 140.0)
        & (data_contrast < 320.0)
    )
    relative_increase = (data_contrast - data_native) / np.maximum(data_native, 20.0)
    rel_gate = relative_increase > 0.35

    vessel_mask &= body_mask
    vessel_mask &= hu_gate
    vessel_mask &= rel_gate

    if min_vessel_size > 1:
        try:
            from scipy import ndimage as ndi
            labels, n_labels = ndi.label(vessel_mask)
            if n_labels > 0:
                sizes = np.bincount(labels.ravel())
                keep = sizes >= min_vessel_size
                keep[0] = False
                vessel_mask = keep[labels]
        except Exception:
            pass

    result = vessel_mask.astype(np.uint8)
    if not save:
        return result

    if output_path is None:
        ct_contrast_path = Path(ct_contrast)
        output_path = ct_contrast_path.parent / (ct_contrast_path.stem.replace('.nii', '') + "_vessel_best.nii.gz")
    else:
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

    header = img_contrast.header.copy()
    header.set_data_dtype(np.uint8)
    out_img = nib.Nifti1Image(result, img_contrast.affine, header)
    nib.save(out_img, output_path)

    vessel_count = int((result > 0).sum())
    print(f"[Best Vessel Extraction] threshold={threshold}, min_vessel_size={min_vessel_size}")
    print(f"Vessel mask: {vessel_count} voxels ({vessel_count/result.size*100:.3f}%)")
    print(f"Saved to: {output_path}")
    return str(output_path)


def otsu_threshold(image: np.ndarray, nbins: int = 256) -> float:
    """
    Compute Otsu's threshold for binary segmentation.

    Parameters
    ----------
    image : np.ndarray
        1D array of image values
    nbins : int
        Number of histogram bins

    Returns
    -------
    float
        Optimal threshold value
    """
    hist, bin_edges = np.histogram(image, bins=nbins)
    hist = hist.astype(float)

    # Total pixels
    total = hist.sum()
    sum_total = np.dot(np.arange(nbins), hist)

    sum_background = 0.0
    weight_background = 0.0
    weight_foreground = 0.0

    threshold = 0.0
    max_variance = 0.0

    for i in range(nbins):
        weight_background += hist[i]
        if weight_background == 0:
            continue

        weight_foreground = total - weight_background
        if weight_foreground == 0:
            break

        sum_background += i * hist[i]
        mean_background = sum_background / weight_background
        mean_foreground = (sum_total - sum_background) / weight_foreground

        # Between-class variance
        variance = weight_background * weight_foreground * (mean_background - mean_foreground) ** 2

        if variance > max_variance:
            threshold = i
            max_variance = variance

    # Convert bin index to actual value
    threshold_value = bin_edges[threshold]

    return threshold_value


# Convenience wrapper for generating vessel mask from contrast subtraction
def extract_vessels_contrast(
    ct_contrast: Union[str, Path],
    ct_native: Union[str, Path],
    output_path: Optional[Union[str, Path]] = None,
    threshold: float = 50
) -> Union[str, Path]:
    """
    Extract blood vessels using contrast agent subtraction.
    
    This is a convenience wrapper around subtract_contrast_ct with mode='vessel'.
    
    Parameters
    ----------
    ct_contrast : str or Path
        Path to contrast-enhanced CT
    ct_native : str or Path
        Path to non-contrast CT
    output_path : str or Path, optional
        Path for output mask
    threshold : float
        Minimum HU difference threshold (default 50)
        
    Returns
    -------
    Path to saved vessel mask
    """
    return subtract_contrast_ct(
        ct_contrast=ct_contrast,
        ct_native=ct_native,
        output_path=output_path,
        threshold=threshold,
        mode='vessel',
        normalize=True,
        save=True
    )


# %%
