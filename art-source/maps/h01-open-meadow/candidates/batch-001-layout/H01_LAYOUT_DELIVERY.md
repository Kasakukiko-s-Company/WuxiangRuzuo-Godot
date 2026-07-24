# H01 开阔草甸 Batch 001 交付说明

- 地图 ID：`home_h01_open_meadow`
- 地图尺寸：128×96 tiles；32×32 px；4096×3072 px
- 权威源：`D:\lzq\AI游戏\WuxiangRuzuo-Godot\art-source\maps\h01-open-meadow\candidates\batch-001-layout\source\h01_open_meadow_authoritative.tmx`
- 默认状态：开局荒废；建设后 TMX 仅为可重建审阅派生物。
- 技术状态：`layout-only`；春季荒废布局已完整，夏/秋/冬与轻/中异常均为 `hook_only_art_pending`，不是 runtime-ready。
- Godot 转换交接：`D:\lzq\AI游戏\WuxiangRuzuo-Godot\art-source\maps\h01-open-meadow\candidates\batch-001-layout\H01_GODOT_IMPORT_HANDOFF.json`
- 自动验证：`D:\lzq\AI游戏\WuxiangRuzuo-Godot\art-source\maps\h01-open-meadow\candidates\batch-001-layout\H01_LAYOUT_VALIDATION.json`（构建成功要求全部检查通过）。
- 来源与授权：见 `H01_LAYOUT_ASSET_RECORD.json`；概念图像素未进入地图图集。
- Tiled：由 D 盘安装的 `tmxrasterizer.exe` 实际解析和栅格化。
- 尚未接入：Godot、正式场景、运行时季节/异常/发展状态切换。
- 未修改：`project.godot`、核心代码、存档 Schema、Git 历史。
- `runtimeIntegrated=false`；`shippingApproval=false`。
