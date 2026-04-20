#!/usr/bin/env python3
"""
Simple vessel extraction from NIfTI by intensity range.

Use this when you pick an intensity window by visual inspection (e.g., ITK-SNAP).

Python example:
  from intensity_vessel_extract import extract_vessel_mask_by_intensity
  result = extract_vessel_mask_by_intensity(
      input_path="HenryGroup_cm042_20250909b_46_1_1.nii",
      min_intensity=450,
      max_intensity=2000,
      out_mask="vessel_mask_intensity.nii.gz",
      opening_iters=1,
      closing_iters=1,
      min_component_size=100,
  )
  print(result["selected_voxels"], result["selected_percent"])
"""

from __future__ import annotations

from typing import Any

import nibabel as nib
import numpy as np
from scipy import ndimage as ndi


def keep_components_over_size(mask: np.ndarray, min_size: int) -> np.ndarray:
    labeled, num = ndi.label(mask)
    if num == 0:
        return mask
    sizes = ndi.sum(mask, labeled, index=np.arange(1, num + 1))
    keep_labels = np.where(sizes >= min_size)[0] + 1
    return np.isin(labeled, keep_labels)


def extract_vessel_mask_by_intensity(
    input_path: str,
    min_intensity: float,
    max_intensity: float,
    out_mask: str = "vessel_mask_intensity.nii.gz",
    opening_iters: int = 0,
    closing_iters: int = 0,
    min_component_size: int = 0,
    invert: bool = False,
) -> dict[str, Any]:
    """Extract and save a binary mask from a raw intensity range."""
    if max_intensity < min_intensity:
        raise ValueError("max_intensity must be >= min_intensity.")
    if opening_iters < 0 or closing_iters < 0:
        raise ValueError("opening_iters and closing_iters must be >= 0.")
    if min_component_size < 0:
        raise ValueError("min_component_size must be >= 0.")

    nii = nib.load(input_path)
    volume = nii.get_fdata()

    mask = (volume >= min_intensity) & (volume <= max_intensity)
    if invert:
        mask = ~mask

    if opening_iters:
        mask = ndi.binary_opening(mask, iterations=opening_iters)
    if closing_iters:
        mask = ndi.binary_closing(mask, iterations=closing_iters)
    if min_component_size:
        mask = keep_components_over_size(mask, min_component_size)

    mask_u8 = mask.astype(np.uint8)
    nib.save(nib.Nifti1Image(mask_u8, nii.affine, nii.header), out_mask)

    selected_voxels = int(mask_u8.sum())
    total_voxels = int(mask_u8.size)
    selected_percent = 100.0 * selected_voxels / max(total_voxels, 1)
    return {
        "out_mask": out_mask,
        "input_path": input_path,
        "min_intensity": min_intensity,
        "max_intensity": max_intensity,
        "invert": invert,
        "selected_voxels": selected_voxels,
        "total_voxels": total_voxels,
        "selected_percent": selected_percent,
    }


def main() -> None:
    # IDE-friendly: edit these values and click Run.
    result = extract_vessel_mask_by_intensity(
        input_path="HenryGroup_cm042_20250909b_46_1_1.nii",
        min_intensity=9946,
        max_intensity=999999,
        out_mask="vessel_mask_intensity.nii.gz",
        opening_iters=0,
        closing_iters=0,
        min_component_size=0,
    )

    print(f"Saved mask: {result['out_mask']}")
    print(f"Input: {result['input_path']}")
    print(f"Range: [{result['min_intensity']}, {result['max_intensity']}] (invert={result['invert']})")
    print(
        f"Selected voxels: {result['selected_voxels']} / {result['total_voxels']} "
        f"({result['selected_percent']:.3f}%)"
    )


if __name__ == "__main__":
    main()
# %%
