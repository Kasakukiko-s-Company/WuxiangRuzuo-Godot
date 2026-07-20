# 资源来源台账

## G1 运行时资源

无。`assets/art`、`assets/audio`、`assets/effects`、`assets/fonts` 只有目录占位。`data/runtime_resources.json` 的 `godotPath` 全部为 null。

## 可在后续适配的旧测试资源

旧 `mvp_farm_ground.png` 和 `mvp_farm_stone.png` 是 2026-07-14 由项目内 Node 标准库脚本确定性生成的 32×32 RGBA 原创几何瓦片；旧台账含 SHA-256。`mvp_farm.tmx` 是 Tiled 1.12.2 导出的原创最小测试图。这三项仅允许在 G3 作为坐标/碰撞冒烟 fixture，当前未复制，不是正式地图美术。

## 阻塞资源

旧视觉候选约 298.57 MiB，来源/确认记录完整但现有 AI 图未完成商业清权、人工重构和运行时验收。任何文件都不允许直接导入 Godot `assets`。没有已确认音乐、音效或字体。
