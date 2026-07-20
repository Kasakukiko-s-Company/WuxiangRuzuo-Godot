# 雾乡如昨 / WuxiangRuzuo

《雾乡如昨》是一个原创 2D 农场生活模拟与可选悬疑探索游戏。本仓库是从旧 Cocos Creator 工程迁移而来的全新 Godot 4 项目。

当前状态：**迁移里程碑 G1 验收候选**。项目可以启动并显示最小启动场景；旧玩法尚未迁移，四张正式地图尚未导入，存档/NPC/战斗/UI 等能力仍是计划项。旧 Cocos 阶段 0～9 只作为历史技术基线，不代表本仓库现状。

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
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 2
```

迁移事实见 `docs/MIGRATION_AUDIT.md`，逐项处置见 `docs/MIGRATION_MATRIX.md`，架构边界见 `docs/GODOT_ARCHITECTURE.md`。
