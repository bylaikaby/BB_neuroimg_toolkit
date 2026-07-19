# 神经科学注射管路体积 / 麻醉到达时间计算器

Web 工具，用于：

1. **管路体积**：多段圆管（内径 + 长度）体积求和，并加上死腔 (μL)。
2. **麻醉到达时间**：在同一管路配置下，根据注射泵流速 (mL/h) 估算液体到达实验动物（如猕猴）所需时间。

公式：`到达时间 (小时) = 管路总容积 (mL) ÷ 流速 (mL/h)`

流速请使用泵屏上的 **流速**（例如 Mindray BeneFusion 体重模式下的 mL/h）。

## 本地运行

```bash
cd tools/neuro_injection_calculator
npm install
npm run dev
```

## 构建（含 Arena 单文件部署）

```bash
npm run build
```

产物为 `dist/index.html`（单文件，内联 JS/CSS），可上传到 [Arena Code](https://arena.ai/code) 替换现有部署。

## 与原版 Arena 应用的关系

基于 [已部署版本](https://019d04d0-2957-7f5a-bc63-a5cd8d76caf7.arena.site/) 的体积计算逻辑重建，并新增「麻醉到达时间」模式。
