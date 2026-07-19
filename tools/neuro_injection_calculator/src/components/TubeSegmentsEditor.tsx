import { Plus, Trash2 } from "lucide-react";
import { segmentVolumeCm3, type TubeSegment } from "../lib/volumes";
import type { LengthUnit } from "../lib/units";

const LENGTH_UNITS: { value: LengthUnit; label: string }[] = [
  { value: "um", label: "μm" },
  { value: "mm", label: "mm" },
  { value: "cm", label: "cm" },
  { value: "m", label: "m" },
  { value: "inch", label: "in" },
];

type Props = {
  segments: TubeSegment[];
  onChange: (segments: TubeSegment[]) => void;
};

export default function TubeSegmentsEditor({ segments, onChange }: Props) {
  const addSegment = () => {
    onChange([
      ...segments,
      {
        id: Date.now().toString(),
        name: `管段 ${segments.length + 1}`,
        diameter: "",
        diameterUnit: "mm",
        length: "",
        lengthUnit: "cm",
      },
    ]);
  };

  const removeSegment = (id: string) => {
    onChange(segments.filter((segment) => segment.id !== id));
  };

  const updateSegment = <K extends keyof TubeSegment>(
    id: string,
    key: K,
    value: TubeSegment[K],
  ) => {
    onChange(segments.map((segment) => (segment.id === id ? { ...segment, [key]: value } : segment)));
  };

  return (
    <div className="space-y-4">
      {segments.map((segment, index) => {
        const segmentVolume =
          typeof segment.diameter === "number" && typeof segment.length === "number"
            ? segmentVolumeCm3(
                segment.diameter,
                segment.diameterUnit,
                segment.length,
                segment.lengthUnit,
              )
            : 0;

        return (
          <div
            key={segment.id}
            className="grid grid-cols-1 md:grid-cols-6 gap-4 p-4 border border-slate-200 rounded-lg items-end bg-slate-50/50"
          >
            <div className="md:col-span-1 font-bold text-slate-700">第 {index + 1} 段</div>

            <div className="md:col-span-2">
              <label className="block text-xs font-semibold text-slate-600 uppercase">
                内径 (Diameter)
              </label>
              <div className="flex gap-2">
                <input
                  type="number"
                  step="any"
                  value={segment.diameter}
                  onChange={(event) =>
                    updateSegment(segment.id, "diameter", parseFloat(event.target.value) || "")
                  }
                  className="w-full p-2 border border-slate-300 rounded shadow-sm focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="0.00"
                />
                <select
                  value={segment.diameterUnit}
                  onChange={(event) =>
                    updateSegment(segment.id, "diameterUnit", event.target.value as LengthUnit)
                  }
                  className="p-2 border border-slate-300 rounded bg-white shadow-sm"
                >
                  {LENGTH_UNITS.map((unit) => (
                    <option key={unit.value} value={unit.value}>
                      {unit.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="md:col-span-2">
              <label className="block text-xs font-semibold text-slate-600 uppercase">
                长度 (Length)
              </label>
              <div className="flex gap-2">
                <input
                  type="number"
                  step="any"
                  value={segment.length}
                  onChange={(event) =>
                    updateSegment(segment.id, "length", parseFloat(event.target.value) || "")
                  }
                  className="w-full p-2 border border-slate-300 rounded shadow-sm focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="0.00"
                />
                <select
                  value={segment.lengthUnit}
                  onChange={(event) =>
                    updateSegment(segment.id, "lengthUnit", event.target.value as LengthUnit)
                  }
                  className="p-2 border border-slate-300 rounded bg-white shadow-sm"
                >
                  {LENGTH_UNITS.map((unit) => (
                    <option key={unit.value} value={unit.value}>
                      {unit.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="flex items-center justify-between gap-2">
              <div className="text-sm font-mono text-slate-800 bg-white p-2 rounded border border-slate-200 w-full text-center">
                {segmentVolume.toFixed(4)}{" "}
                <span className="text-[10px] text-slate-500">cm³</span>
              </div>
              <button
                type="button"
                onClick={() => removeSegment(segment.id)}
                className="text-slate-400 hover:text-red-500 p-2 transition-colors"
                aria-label={`删除第 ${index + 1} 段`}
              >
                <Trash2 size={20} />
              </button>
            </div>
          </div>
        );
      })}

      <button
        type="button"
        onClick={addSegment}
        className="flex items-center gap-2 text-blue-600 hover:text-blue-800 font-medium"
      >
        <Plus size={20} />
        添加管道段
      </button>
    </div>
  );
}
