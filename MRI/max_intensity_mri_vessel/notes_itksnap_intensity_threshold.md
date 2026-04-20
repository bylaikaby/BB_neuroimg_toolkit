# ITK-SNAP Display Window vs Intensity Threshold

## User Question
"it is not showing the same as"

## Answer
The mismatch is expected because ITK-SNAP **Contrast** values (`Minimum` / `Maximum`) are display window settings, not direct segmentation thresholds.

- In display windowing:
  - values below minimum appear dark
  - values above maximum appear bright (saturated white)
- In the script, thresholding was done as:
  - `min_intensity <= value <= max_intensity`
  - so values above `max_intensity` were excluded from the mask

That is why the binary output can look different from what appears bright in the viewer.

### Practical Fix
- If you want "all bright values above a cutoff", use a high upper bound:
  - e.g., `min_intensity=9946`, `max_intensity=999999`
- If you want only a narrow intensity band, keep both min and max tight.
- For segmentation-like matching in ITK-SNAP, use threshold tools instead of only contrast window controls.

## Figures

**Figure 1.** ITK-SNAP contrast panel and initial visual comparison  
![Figure 1](./figures/figure1_itksnap_contrast.png)

**Figure 2.** IDE parameter settings used for intensity extraction  
![Figure 2](./figures/figure2_ide_params.png)

**Figure 3.** Earlier mask result view in ITK-SNAP  
![Figure 3](./figures/figure3_mask_earlier.png)

**Figure 4.** Latest result (this one)  
![Figure 4](./figures/figure4_mask_latest.png)
