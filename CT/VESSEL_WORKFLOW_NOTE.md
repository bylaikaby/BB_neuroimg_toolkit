# CT Vessel Extraction Workflow Note

This note documents the current vessel extraction logic centered on
`CT/nifti_ct_extraction.py`.

## Main Function

- Use `subtract_contrast_ct()` for vessel extraction from two CT volumes:
  - `ct_native`: non-contrast CT
  - `ct_contrast`: contrast-enhanced CT

## Recommended Practical Setup

- `mode='vessel'`
- `algorithm='difference'` for robust positive enhancement
- `normalize=False` to preserve HU-space interpretation

## Core Extraction Logic

1. Compute enhancement map from native and contrast scans.
2. Threshold enhancement values to obtain vessel candidates.
3. Apply gating to suppress non-vascular structures:
   - body/background gate
   - native HU upper bound (`native_hu_max`) for dense bone suppression
   - contrast HU lower/upper bounds (`contrast_hu_min`, `contrast_hu_max`)
   - minimum relative increase gate (`min_relative_increase`)
4. Remove tiny connected components using `min_vessel_size`.

## Typical Command

```bash
python CT/ct_vessel_workflow.py --ct-native "CT/0.55 x 0.55_202.nii.gz" --ct-contrast "CT/0.55 x 0.55_502.nii.gz" --output-vessel "CT/vessels.nii.gz" --threshold 70 --native-hu-max 140 --contrast-hu-min 140 --contrast-hu-max 250 --min-relative-increase 0.45 --min-vessel-size 50
```

## Notes

- Direct subtraction does not guarantee vessel-only output; it highlights any
  changing structure. The gating steps are critical for suppressing skull/skin
  leakage.
- For continuous HU inspection instead of binary output, use
  `mode='enhancement'` and `algorithm='signed_difference'`.
