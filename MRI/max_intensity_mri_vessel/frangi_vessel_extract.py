#!/usr/bin/env python3
"""
Frangi 3D vessel extraction for angiogram NIfTI volumes.

Example:
  python frangi_vessel_extract.py ^
    --input HenryGroup_cm042_20250909b_46_1_1.nii ^
    --out-vesselness vesselness_frangi.nii.gz ^
    --out-mask vessel_mask_frangi.nii.gz ^
    --sigma-min 0.5 --sigma-max 3.0 --sigma-step 0.5 ^
    --alpha 0.5 --beta 0.5 --gamma 15 ^
    --threshold-percentile 98 --min-component-size 100
"""

from __future__ import annotations

import argparse
from pathlib import Path

import nibabel as nib
import numpy as np
from scipy import ndimage as ndi
from skimage.filters import frangi


def robust_normalize(volume: np.ndarray, low_pct: float = 1.0, high_pct: float = 99.0) -> np.ndarray:
    """Normalize to [0, 1] with percentile clipping."""
    low, high = np.percentile(volume, (low_pct, high_pct))
    norm = (volume - low) / (high - low + 1e-8)
    return np.clip(norm, 0.0, 1.0).astype(np.float32)


def keep_components_over_size(mask: np.ndarray, min_size: int) -> np.ndarray:
    labeled, num = ndi.label(mask)
    if num == 0:
        return mask
    sizes = ndi.sum(mask, labeled, index=np.arange(1, num + 1))
    keep_labels = np.where(sizes >= min_size)[0] + 1
    return np.isin(labeled, keep_labels)


def guess_input_path() -> str | None:
    """Pick a likely NIfTI in the current folder when --input is omitted."""
    preferred = Path("HenryGroup_cm042_20250909b_46_1_1.nii")
    if preferred.exists():
        return str(preferred)

    candidates = sorted(Path(".").glob("*.nii")) + sorted(Path(".").glob("*.nii.gz"))
    if candidates:
        return str(candidates[0])
    return None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Extract vessels from MRA using 3D Frangi vesselness.")
    parser.add_argument(
        "--input",
        default=guess_input_path(),
        help="Input NIfTI path (.nii or .nii.gz). Optional for IDE run if file is in current folder.",
    )
    parser.add_argument("--out-vesselness", default="vesselness_frangi.nii.gz", help="Output vesselness NIfTI")
    parser.add_argument("--out-mask", default="vessel_mask_frangi.nii.gz", help="Output binary vessel mask NIfTI")
    parser.add_argument("--sigma-min", type=float, default=0.5, help="Minimum Frangi sigma in voxels")
    parser.add_argument("--sigma-max", type=float, default=3.0, help="Maximum Frangi sigma in voxels")
    parser.add_argument("--sigma-step", type=float, default=0.5, help="Sigma step in voxels")
    parser.add_argument("--alpha", type=float, default=0.5, help="Frangi alpha (plate-like suppression)")
    parser.add_argument("--beta", type=float, default=0.5, help="Frangi beta (blob-like suppression)")
    parser.add_argument("--gamma", type=float, default=15.0, help="Frangi gamma (background suppression)")
    parser.add_argument(
        "--norm-low-pct",
        type=float,
        default=1.0,
        help="Lower percentile for robust normalization clipping",
    )
    parser.add_argument(
        "--norm-high-pct",
        type=float,
        default=99.0,
        help="Upper percentile for robust normalization clipping",
    )
    parser.add_argument(
        "--threshold-percentile",
        type=float,
        default=98.0,
        help="Percentile threshold on vesselness map (e.g., 95-99)",
    )
    parser.add_argument(
        "--min-component-size",
        type=int,
        default=100,
        help="Remove connected components smaller than this voxel count",
    )
    parser.add_argument(
        "--black-ridges",
        action="store_true",
        help="Enable if vessels are dark on bright background (default assumes bright vessels).",
    )
    parser.add_argument(
        "--opening-iters",
        type=int,
        default=1,
        help="Binary opening iterations for mask cleanup (set 0 to disable)",
    )
    parser.add_argument(
        "--closing-iters",
        type=int,
        default=1,
        help="Binary closing iterations for mask cleanup (set 0 to disable)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not args.input:
        raise SystemExit(
            "No input NIfTI found. Pass --input path/to/file.nii (or place a .nii/.nii.gz in this folder)."
        )

    if args.sigma_step <= 0:
        raise SystemExit("--sigma-step must be > 0.")
    if args.sigma_max < args.sigma_min:
        raise SystemExit("--sigma-max must be >= --sigma-min.")
    if not (0 <= args.threshold_percentile <= 100):
        raise SystemExit("--threshold-percentile must be in [0, 100].")
    if not (0 <= args.norm_low_pct <= 100 and 0 <= args.norm_high_pct <= 100):
        raise SystemExit("--norm-low-pct and --norm-high-pct must be in [0, 100].")
    if args.norm_low_pct >= args.norm_high_pct:
        raise SystemExit("--norm-low-pct must be smaller than --norm-high-pct.")
    if args.opening_iters < 0 or args.closing_iters < 0:
        raise SystemExit("--opening-iters and --closing-iters must be >= 0.")

    nii = nib.load(args.input)
    volume = nii.get_fdata().astype(np.float32)
    volume_norm = robust_normalize(volume, low_pct=args.norm_low_pct, high_pct=args.norm_high_pct)

    sigmas = np.arange(args.sigma_min, args.sigma_max + 1e-9, args.sigma_step)
    vesselness = frangi(
        volume_norm,
        sigmas=sigmas,
        alpha=args.alpha,
        beta=args.beta,
        gamma=args.gamma,
        black_ridges=args.black_ridges,
    ).astype(np.float32)

    threshold = np.percentile(vesselness, args.threshold_percentile)
    mask = vesselness > threshold
    if args.opening_iters:
        mask = ndi.binary_opening(mask, iterations=args.opening_iters)
    if args.closing_iters:
        mask = ndi.binary_closing(mask, iterations=args.closing_iters)
    mask = keep_components_over_size(mask, args.min_component_size).astype(np.uint8)

    nib.save(nib.Nifti1Image(vesselness, nii.affine, nii.header), args.out_vesselness)
    nib.save(nib.Nifti1Image(mask, nii.affine, nii.header), args.out_mask)

    print(f"Saved vesselness: {args.out_vesselness}")
    print(f"Saved vessel mask: {args.out_mask}")
    print(f"Sigmas: {sigmas}")
    print(f"Frangi params: alpha={args.alpha}, beta={args.beta}, gamma={args.gamma}")
    print(f"Normalization percentiles: low={args.norm_low_pct}, high={args.norm_high_pct}")
    print(f"Threshold percentile: {args.threshold_percentile}")
    print(f"Threshold value: {threshold:.6f}")


if __name__ == "__main__":
    main()
