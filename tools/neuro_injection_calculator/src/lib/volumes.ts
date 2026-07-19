import { toCm, type LengthUnit } from "./units";

export type TubeSegment = {
  id: string;
  name: string;
  diameter: number | "";
  diameterUnit: LengthUnit;
  length: number | "";
  lengthUnit: LengthUnit;
};

export type SegmentTotals = {
  volumeCm3: number;
  lengthCm: number;
};

export function segmentVolumeCm3(
  diameter: number,
  diameterUnit: LengthUnit,
  length: number,
  lengthUnit: LengthUnit,
): number {
  const radiusCm = toCm(diameter, diameterUnit) / 2;
  const lengthCm = toCm(length, lengthUnit);
  return Math.PI * radiusCm * radiusCm * lengthCm;
}

export function computeTotals(segments: TubeSegment[]): SegmentTotals {
  let volumeCm3 = 0;
  let lengthCm = 0;

  for (const segment of segments) {
    if (typeof segment.diameter !== "number" || typeof segment.length !== "number") {
      continue;
    }
    volumeCm3 += segmentVolumeCm3(
      segment.diameter,
      segment.diameterUnit,
      segment.length,
      segment.lengthUnit,
    );
    lengthCm += toCm(segment.length, segment.lengthUnit);
  }

  return { volumeCm3, lengthCm };
}

/** 1 cm³ = 1 mL = 1000 μL */
export function cm3ToMicroliters(cm3: number): number {
  return cm3 * 1000;
}

export function microlitersToMilliliters(ul: number): number {
  return ul / 1000;
}

export type ReachTimeResult = {
  hours: number;
  minutes: number;
  seconds: number;
};

export function reachTimeFromFlow(
  totalVolumeMl: number,
  flowRateMlPerHour: number,
): ReachTimeResult | null {
  if (!Number.isFinite(totalVolumeMl) || !Number.isFinite(flowRateMlPerHour)) {
    return null;
  }
  if (totalVolumeMl <= 0 || flowRateMlPerHour <= 0) {
    return null;
  }

  const hours = totalVolumeMl / flowRateMlPerHour;
  const totalSeconds = Math.round(hours * 3600);
  return {
    hours,
    minutes: Math.floor(totalSeconds / 60),
    seconds: totalSeconds % 60,
  };
}
