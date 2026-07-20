# 雾乡如昨 / WuxiangRuzuo

《雾乡如昨》是一个原创 2D 农场生活模拟与可选悬疑探索游戏。本仓库是从旧 Cocos Creator 工程迁移而来的全新 Godot 4 项目。

当前状态：**迁移里程碑 G2 验收候选**。项目可以启动、原子校验七份目录 JSON（含 15 名 NPC 稳定身份），并运行纯 GDScript 的背包、农田状态和新存档 Schema；移动、完整农耕闭环、存档文件、四张正式地图、NPC 对白/关系玩法、战斗和正式 UI 仍是计划项。旧 Cocos 阶段 0～9 只作为历史技术基线，不代表本仓库现状。

## 当前技术基线

- Godot `4.7.1.stable`，GDScript，Godot 2D。
- Compatibility Renderer。
- `640×360` 逻辑分辨率，横屏，`canvas_items + keep` 拉伸。
- 32×32 地图瓦片；Tiled 为外部地图编辑器。
- JSON 数据与稳定语义 ID。
- Windows/Steam 优先；Web/微信小游戏仅保留抽象，尚未验证发布链路。

## 本地验证

```powershell
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --quit
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/smoke/test_g1_smoke.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/g2/test_catalog_codec.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/g2/test_inventory_state.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/g2/test_farm_state.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/g2/test_save_codec.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/g2/test_platform_contracts.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/g2/test_g2_bootstrap.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 2
```

迁移事实见 `docs/MIGRATION_AUDIT.md`，逐项处置见 `docs/MIGRATION_MATRIX.md`，架构边界见 `docs/GODOT_ARCHITECTURE.md`。
