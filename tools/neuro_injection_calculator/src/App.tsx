import { useMemo, useState } from "react";
import TubeSegmentsEditor from "./components/TubeSegmentsEditor";
import {
  cm3ToMicroliters,
  computeTotals,
  microlitersToMilliliters,
  reachTimeFromFlow,
  type TubeSegment,
} from "./lib/volumes";

type CalculatorMode = "volume" | "reachTime";

const INITIAL_SEGMENTS: TubeSegment[] = [
  {
    id: "1",
    name: "管段 1",
    diameter: "",
    diameterUnit: "mm",
    length: "",
    lengthUnit: "cm",
  },
];

function formatDuration(hours: number, minutes: number, seconds: number): string {
  if (hours >= 1) {
    const wholeHours = Math.floor(hours);
    const remainderMinutes = Math.round((hours - wholeHours) * 60);
    return `${wholeHours} 小时 ${remainderMinutes} 分`;
  }
  if (minutes > 0) {
    return `${minutes} 分 ${seconds} 秒`;
  }
  return `${seconds} 秒`;
}

export default function App() {
  const [mode, setMode] = useState<CalculatorMode>("volume");
  const [segments, setSegments] = useState<TubeSegment[]>(INITIAL_SEGMENTS);
  const [deadSpaceUl, setDeadSpaceUl] = useState(0);
  const [flowRateMlPerHour, setFlowRateMlPerHour] = useState<number | "">("");

  const totals = useMemo(() => computeTotals(segments), [segments]);
  const pipeVolumeUl = cm3ToMicroliters(totals.volumeCm3);
  const totalVolumeUl = pipeVolumeUl + deadSpaceUl;
  const totalVolumeMl = microlitersToMilliliters(totalVolumeUl);

  const reachTime = useMemo(() => {
    if (typeof flowRateMlPerHour !== "number") {
      return null;
    }
    return reachTimeFromFlow(totalVolumeMl, flowRateMlPerHour);
  }, [flowRateMlPerHour, totalVolumeMl]);

  return (
    <div className="min-h-screen bg-slate-50 p-4 md:p-8">
      <div className="max-w-4xl mx-auto bg-white p-6 rounded-xl shadow-sm border border-slate-200">
        <h1 className="text-2xl font-bold mb-2 text-slate-800">神经科学注射：管道体积计算器</h1>
        <p className="text-sm text-slate-500 mb-6">
          支持多段管路体积汇总，以及根据注射泵流速估算麻醉剂到达实验动物（如猕猴）所需时间。
        </p>

        <div className="flex flex-wrap gap-2 mb-6 p-1 bg-slate-100 rounded-lg w-fit">
          <button
            type="button"
            onClick={() => setMode("volume")}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              mode === "volume"
                ? "bg-white text-slate-800 shadow-sm"
                : "text-slate-600 hover:text-slate-800"
            }`}
          >
            管路体积
          </button>
          <button
            type="button"
            onClick={() => setMode("reachTime")}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              mode === "reachTime"
                ? "bg-white text-slate-800 shadow-sm"
                : "text-slate-600 hover:text-slate-800"
            }`}
          >
            麻醉到达时间
          </button>
        </div>

        <TubeSegmentsEditor segments={segments} onChange={setSegments} />

        <div className="mt-8 pt-6 border-t border-slate-200">
          <div className="mb-4">
            <label className="block font-medium text-slate-700">
              死腔体积 (Dead Space) - 单位: μL
            </label>
            <input
              type="number"
              step="any"
              value={deadSpaceUl}
              onChange={(event) => setDeadSpaceUl(parseFloat(event.target.value) || 0)}
              className="w-full md:w-1/3 p-2 border border-slate-300 rounded"
              placeholder="0.00"
            />
            <p className="text-xs text-slate-500 mt-1">
              三通、延长管、留置针等未计入各管段长度时的附加死腔，建议一并计入到达时间。
            </p>
          </div>

          {mode === "reachTime" && (
            <div className="mb-6 p-4 border border-blue-100 bg-blue-50/50 rounded-lg">
              <label className="block font-medium text-slate-700 mb-1">
                注射泵流速 (Flow Rate) - 单位: mL/h
              </label>
              <input
                type="number"
                step="any"
                min="0"
                value={flowRateMlPerHour}
                onChange={(event) =>
                  setFlowRateMlPerHour(parseFloat(event.target.value) || "")
                }
                className="w-full md:w-1/3 p-2 border border-slate-300 rounded bg-white"
                placeholder="例如 8.85"
              />
              <p className="text-xs text-slate-500 mt-2">
                读取泵屏「流速」数值（如 BeneFusion 体重模式下的 mL/h）。公式：到达时间 = 管路总容积
                (mL) ÷ 流速 (mL/h)。
              </p>
            </div>
          )}

          <div className="p-6 bg-slate-800 text-white rounded-lg space-y-2">
            <h2 className="text-xl font-bold mb-2">计算结果</h2>

            <p>
              总管段长度:{" "}
              <span className="font-mono text-xl">{totals.lengthCm.toFixed(2)} cm</span>
            </p>
            <p>
              管道体积:{" "}
              <span className="font-mono text-xl">{pipeVolumeUl.toFixed(4)} μL</span>
              <span className="text-slate-400 text-sm ml-2">
                ({microlitersToMilliliters(pipeVolumeUl).toFixed(4)} mL)
              </span>
            </p>
            <p>
              死腔体积: <span className="font-mono text-xl">{deadSpaceUl.toFixed(4)} μL</span>
            </p>
            <p>
              包含死腔的总注射体积:{" "}
              <span className="font-mono text-2xl text-yellow-400">
                {totalVolumeUl.toFixed(4)} μL
              </span>
              <span className="text-slate-400 text-sm ml-2">({totalVolumeMl.toFixed(4)} mL)</span>
            </p>

            {mode === "reachTime" && (
              <div className="pt-4 mt-4 border-t border-slate-600">
                <p className="text-slate-300 text-sm mb-1">麻醉剂到达动物（管路充盈时间）</p>
                {reachTime ? (
                  <>
                    <p>
                      预计到达时间:{" "}
                      <span className="font-mono text-2xl text-yellow-400">
                        {formatDuration(reachTime.hours, reachTime.minutes, reachTime.seconds)}
                      </span>
                    </p>
                    <p className="text-sm text-slate-400 font-mono">
                      {reachTime.hours.toFixed(4)} 小时 · {reachTime.minutes} 分 {reachTime.seconds}{" "}
                      秒
                    </p>
                  </>
                ) : (
                  <p className="text-slate-400 text-sm">
                    请输入大于 0 的流速 (mL/h)，并确保管路总容积大于 0。
                  </p>
                )}
              </div>
            )}

            <p className="text-xs text-slate-400 mt-2">* 1 cm³ = 1000 μL (即 1 mL)</p>
          </div>
        </div>
      </div>
    </div>
  );
}
