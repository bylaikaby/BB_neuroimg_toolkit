#!/usr/bin/env python3
"""
CT Vessel Extraction Workflow: DICOM to NIfTI to Contrast Subtraction

This script provides a complete pipeline for extracting blood vessels from CT scans
by subtracting non-contrast CT from contrast-enhanced CT.

Usage:
    python ct_vessel_workflow.py --dicom-native <native_folder> --dicom-contrast <contrast_folder> [options]

Examples:
    # Basic usage with folder paths
    python ct_vessel_workflow.py --dicom-native "0.55 x 0.55_202" --dicom-contrast "0.55 x 0.55_502"

    # With custom output paths
    python ct_vessel_workflow.py --dicom-native "native_folder" --dicom-contrast "contrast_folder" \
        --output-native "ct_native.nii.gz" --output-contrast "ct_contrast.nii.gz" \
        --output-vessel "vessels.nii.gz"

    # Already have NIfTI files
    python ct_vessel_workflow.py --ct-native "ct_native.nii.gz" --ct-contrast "ct_contrast.nii.gz"


Current setup (now default, and also what --best enforces):

threshold = 70
native-hu-max = 140
contrast-hu-min = 140
contrast-hu-max = 250
min-relative-increase = 0.45
min-vessel-size = 50
mode = vessel
algorithm = difference
normalize = off



"""

import argparse
import sys
from pathlib import Path

# Best preset tuned from current successful extraction runs.
BEST_PRESET = {
    'threshold': 70.0,
    'native_hu_max': 140.0,
    'contrast_hu_min': 140.0,
    'contrast_hu_max': 250.0,
    'min_relative_increase': 0.45,
    'min_vessel_size': 50,
}

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from nifti_ct_extraction import (
    convert_dicom_to_nifti,
    subtract_contrast_ct,
    extract_vessels_best,
    extract_vessels_contrast,
    batch_convert_ct_folders
)


def parse_args():
    parser = argparse.ArgumentParser(
        description='CT Vessel Extraction: DICOM to NIfTI to Contrast Subtraction',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    # Input arguments
    input_group = parser.add_argument_group('Input Options (choose one)')
    input_mode = input_group.add_mutually_exclusive_group(required=True)
    input_mode.add_argument(
        '--dicom-native', '--dn',
        help='Folder containing native (non-contrast) DICOM files'
    )
    input_mode.add_argument(
        '--ct-native', '--cn',
        help='Path to native CT NIfTI file (if already converted)'
    )
    input_mode.add_argument(
        '--dicom-folders', '--df',
        nargs=2,
        metavar=('NATIVE_FOLDER', 'CONTRAST_FOLDER'),
        help='Two folders: first=native, second=contrast DICOM folders'
    )
    
    input_group2 = parser.add_argument_group('Contrast Input Options')
    input_group2.add_argument(
        '--dicom-contrast', '--dc',
        help='Folder containing contrast-enhanced DICOM files'
    )
    input_group2.add_argument(
        '--ct-contrast', '--cc',
        help='Path to contrast CT NIfTI file (if already converted)'
    )
    
    # Output arguments
    output_group = parser.add_argument_group('Output Options')
    output_group.add_argument(
        '--output-native', '--on',
        help='Output path for native NIfTI (default: <dicom-native>_native.nii.gz)'
    )
    output_group.add_argument(
        '--output-contrast', '--oc',
        help='Output path for contrast NIfTI (default: <dicom-contrast>_contrast.nii.gz)'
    )
    output_group.add_argument(
        '--output-vessel', '--ov',
        help='Output path for vessel mask (default: vessels_<timestamp>.nii.gz)'
    )
    output_group.add_argument(
        '--output-subtraction', '--os',
        help='Output path for raw subtraction map (optional)'
    )
    
    # Processing arguments
    proc_group = parser.add_argument_group('Processing Options')
    proc_group.add_argument(
        '--threshold', '-t',
        type=float,
        default=70.0,
        help='Threshold for vessel detection (default: 70)'
    )
    proc_group.add_argument(
        '--normalize',
        action='store_true',
        help='Enable percentile normalization before comparison (off by default for HU-preserving subtraction)'
    )
    proc_group.add_argument(
        '--mode', '-m',
        choices=['vessel', 'enhancement'],
        default='vessel',
        help='Output mode (default: vessel)'
    )
    proc_group.add_argument(
        '--algorithm', '-a',
        choices=['ratio', 'difference', 'signed_difference', 'relative'],
        default='difference',
        help='Algorithm for vessel enhancement (default: difference)'
    )
    proc_group.add_argument(
        '--body-hu-min',
        type=float,
        default=-300.0,
        help='Lower HU bound for body mask used during vessel extraction (default: -300)'
    )
    proc_group.add_argument(
        '--min-vessel-size',
        type=int,
        default=50,
        help='Minimum connected component size (voxels) to keep in vessel mask (default: 50)'
    )
    proc_group.add_argument(
        '--native-hu-max',
        type=float,
        default=140.0,
        help='Upper HU bound in native scan for vessel candidates; suppresses bone/calcification (default: 140)'
    )
    proc_group.add_argument(
        '--contrast-hu-min',
        type=float,
        default=140.0,
        help='Lower HU bound in contrast scan for vessel candidates; suppresses low-HU skin/soft tissue (default: 140)'
    )
    proc_group.add_argument(
        '--contrast-hu-max',
        type=float,
        default=250.0,
        help='Upper HU bound in contrast scan for vessel candidates; suppresses very dense bone/calcification (default: 250)'
    )
    proc_group.add_argument(
        '--min-relative-increase',
        type=float,
        default=0.45,
        help='Minimum relative enhancement (contrast-native)/max(native,1) for vessel candidates (default: 0.45)'
    )
    proc_group.add_argument(
        '--advanced',
        action='store_true',
        help='Use advanced custom gating arguments instead of simplified best vessel extraction'
    )
    proc_group.add_argument(
        '--best',
        action='store_true',
        help='Force best vessel preset (recommended one-switch extraction settings)'
    )

    # Utility arguments
    util_group = parser.add_argument_group('Utility Options')
    util_group.add_argument(
        '--batch-convert',
        action='store_true',
        help='Convert all DICOM folders in current directory to NIfTI'
    )
    util_group.add_argument(
        '--skip-subtraction',
        action='store_true',
        help='Only convert DICOMs, skip vessel extraction'
    )
    util_group.add_argument(
        '--dry-run',
        action='store_true',
        help='Print commands without executing'
    )
    
    return parser.parse_args()


def main():
    args = parse_args()

    if args.best:
        args.mode = 'vessel'
        args.advanced = False
        args.algorithm = 'difference'
        args.normalize = False
        args.threshold = BEST_PRESET['threshold']
        args.native_hu_max = BEST_PRESET['native_hu_max']
        args.contrast_hu_min = BEST_PRESET['contrast_hu_min']
        args.contrast_hu_max = BEST_PRESET['contrast_hu_max']
        args.min_relative_increase = BEST_PRESET['min_relative_increase']
        args.min_vessel_size = BEST_PRESET['min_vessel_size']
    
    ct_native_path = None
    ct_contrast_path = None
    
    print("=" * 60)
    print("CT Vessel Extraction Workflow")
    print("=" * 60)
    
    # Handle batch conversion mode
    if args.batch_convert:
        print("\n[Batch Convert Mode]")
        results = batch_convert_ct_folders('.')
        print("\nConversion results:")
        for name, path in results.items():
            status = "OK" if path.endswith('.nii.gz') and Path(path).exists() else path
            print(f"  {name}: {status}")
        return
    
    # Convert DICOM to NIfTI if needed
    if args.dicom_native or args.dicom_folders:
        folders = args.dicom_folders if args.dicom_folders else (args.dicom_native, args.dicom_contrast)
        
        # Native CT
        if folders[0]:
            print(f"\n[1/2] Converting native DICOM: {folders[0]}")
            if args.dry_run:
                print(f"  Would convert to: {args.output_native or folders[0] + '_native.nii.gz'}")
            else:
                ct_native_path = convert_dicom_to_nifti(
                    folders[0],
                    args.output_native,
                    rescale_hu=True
                )
        else:
            ct_native_path = args.ct_native
        
        # Contrast CT
        if folders[1]:
            print(f"\n[2/2] Converting contrast DICOM: {folders[1]}")
            if args.dry_run:
                print(f"  Would convert to: {args.output_contrast or folders[1] + '_contrast.nii.gz'}")
            else:
                ct_contrast_path = convert_dicom_to_nifti(
                    folders[1],
                    args.output_contrast,
                    rescale_hu=True
                )
        else:
            ct_contrast_path = args.ct_contrast
    else:
        # Use provided NIfTI paths directly
        ct_native_path = args.ct_native
        ct_contrast_path = args.ct_contrast
    
    # Validate inputs
    if not ct_native_path:
        print("ERROR: No native CT path specified")
        return 1
    if not ct_contrast_path:
        print("ERROR: No contrast CT path specified")
        return 1
    
    if not Path(ct_native_path).exists():
        print(f"ERROR: Native CT not found: {ct_native_path}")
        return 1
    if not Path(ct_contrast_path).exists():
        print(f"ERROR: Contrast CT not found: {ct_contrast_path}")
        return 1
    
    # Skip subtraction if requested
    if args.skip_subtraction:
        print("\n[Skip Subtraction] Skipping vessel extraction")
        return 0
    
    # Perform contrast subtraction
    print(f"\n[3/3] Extracting vessels via contrast subtraction")
    print(f"  Native:  {ct_native_path}")
    print(f"  Contrast: {ct_contrast_path}")
    print(f"  Threshold: {args.threshold}")
    
    if args.dry_run:
        output = args.output_vessel or 'vessels.nii.gz'
        if args.mode == 'vessel' and not args.advanced:
            print(f"  Would compute: extract_vessels_best(...) -> {output}")
        else:
            print(f"  Would compute: subtract_contrast_ct(...) -> {output}")
        return 0
    
    # Run extraction
    if args.mode == 'vessel' and not args.advanced:
        result_path = extract_vessels_best(
            ct_contrast=ct_contrast_path,
            ct_native=ct_native_path,
            output_path=args.output_vessel,
            threshold=args.threshold,
            min_vessel_size=args.min_vessel_size,
            save=True
        )
    else:
        result_path = subtract_contrast_ct(
            ct_contrast=ct_contrast_path,
            ct_native=ct_native_path,
            output_path=args.output_vessel,
            threshold=args.threshold,
            mode=args.mode,
            algorithm=args.algorithm,
            normalize=args.normalize,
            body_hu_min=args.body_hu_min,
            min_vessel_size=args.min_vessel_size,
            native_hu_max=args.native_hu_max,
            contrast_hu_min=args.contrast_hu_min,
            contrast_hu_max=args.contrast_hu_max,
            min_relative_increase=args.min_relative_increase,
            save=True
        )

    print(f"\n[Vessel Extraction Complete]")
    print(f"  Output: {result_path}")

    # Optionally save enhancement map
    if args.output_subtraction:
        print(f"\n[Extra] Saving enhancement map")
        subtract_contrast_ct(
            ct_contrast=ct_contrast_path,
            ct_native=ct_native_path,
            output_path=args.output_subtraction,
            threshold=args.threshold,
            mode='enhancement',
            algorithm=args.algorithm,
            normalize=args.normalize,
            body_hu_min=args.body_hu_min,
            min_vessel_size=args.min_vessel_size,
            native_hu_max=args.native_hu_max,
            contrast_hu_min=args.contrast_hu_min,
            contrast_hu_max=args.contrast_hu_max,
            min_relative_increase=args.min_relative_increase,
            save=True
        )
    
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
