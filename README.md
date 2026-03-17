# Imaging Toolkit

A Python toolkit for medical image processing, specifically for CT scan analysis and threshold-based extraction.

## Features

- Extract CT voxels within Hounsfield Unit (HU) threshold ranges
- Create binary masks or masked volumes for specific tissue types
- Convenience functions for common tissue types (bone, lung, soft tissue)

## Usage

```python
from nifti_ct_extraction import extract_ct_threshold, extract_ct_bone

# Extract bone using threshold range
extract_ct_threshold(
    'input_ct.nii.gz',
    hu_min=200, 
    hu_max=3000,
    mode='mask'
)

# Or use the convenience function
extract_ct_bone('input_ct.nii.gz', output_path='bone_mask.nii.gz')
```

## Requirements

- nibabel
- numpy

## Installation

```bash
pip install nibabel numpy
```
