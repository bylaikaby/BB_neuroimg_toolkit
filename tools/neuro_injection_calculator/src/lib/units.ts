export type LengthUnit = "um" | "mm" | "cm" | "m" | "inch";

/** Multipliers to convert a value into centimeters. */
export const LENGTH_TO_CM: Record<LengthUnit, number> = {
  um: 1e-4,
  mm: 0.1,
  cm: 1,
  m: 100,
  inch: 2.54,
};

export function toCm(value: number, unit: LengthUnit): number {
  return value * LENGTH_TO_CM[unit];
}
