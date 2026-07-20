# 资源来源台账

本台账不仅记录旧资源迁移，也记录完整游戏后续所有新制、委托、采购和 AI 辅助资源。任何资源进入运行时 `assets/` 前都必须补齐来源、许可、修改、审核与版本信息。

## G1 运行时资源

无。`assets/art`、`assets/audio`、`assets/effects`、`assets/fonts` 只有目录占位。`data/runtime_resources.json` 的 `godotPath` 全部为 null。

## P1 程序化原型资源（2026-07-20）

P1 没有复制旧素材，也没有引入外部二进制资源。地形、道路、水边、建筑轮廓、玩家、交互标记、前景遮挡、雾带和调试网格由仓库内原创 GDScript 在运行时绘制；环境循环、脚步和交互提示音由 `p1_prototype_audio.gd` 确定性生成 16-bit mono WAV 数据并仅保存在内存。

来源/作者：本项目 P1 实现；第三方来源：无；外部模型/素材：无；许可风险：无外来许可；状态：仅用于体验验证，不是正式美术或正式音频。代码位置：`scripts/gameplay/prototypes/`、`scripts/gameplay/player/p1_player_controller.gd`。自动审核截图位于被 Git 忽略的 `.godot/qa/`，可由 `tools/capture_p1_visual.gd` 重建，不是项目资源的唯一副本。

## 可在后续适配的旧测试资源

旧 `mvp_farm_ground.png` 和 `mvp_farm_stone.png` 是 2026-07-14 由项目内 Node 标准库脚本确定性生成的 32×32 RGBA 原创几何瓦片；旧台账含 SHA-256。`mvp_farm.tmx` 是 Tiled 1.12.2 导出的原创最小测试图。这三项只可作为 P1 坐标/碰撞验证的候选 fixture，当前未复制，也不是正式地图美术；P1 可以直接制作更符合新体验命题的灰盒。

## 阻塞资源

旧视觉候选约 298.57 MiB，来源/确认记录完整但现有 AI 图未完成商业清权、人工重构和运行时验收。任何文件都不允许直接导入 Godot `assets`。没有已确认音乐、音效或字体。
