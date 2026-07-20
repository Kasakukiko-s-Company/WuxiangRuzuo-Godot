# 雾乡如昨 / WuxiangRuzuo

《雾乡如昨》是一款正在正式制作的原创 2D 生活模拟与悬疑探索游戏。本仓库以 Godot 4 开发完整游戏；旧 Cocos Creator 工程只是早期雏形和可选参考，不是产品规格或内容上限。

当前状态：**G2 技术底座已推送，P0 产品重基线与 P1 体验原型已在工作区完成验收，尚未提交或推送**。默认 Main 可进入全新 `prototype_mist_edge` 灰盒，验证移动、碰撞、相机、交互、语义输入、画质回退和基础视听反馈；它是可丢弃的体验证据，不是正式地图或内容完成声明。

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
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p1/test_movement_intent.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p1/test_tile_coordinate_mapper.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p1/test_player_controller.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p1/test_p1_input_service.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p1/test_p1_scene.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p1/test_p1_main_entry.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 2
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --path . --script res://tools/capture_p1_visual.gd
```

完整游戏方向见 `docs/FULL_GAME_VISION.md` 与 `docs/PRODUCT_BRIEF.md`，制作阶段见 `docs/FULL_GAME_ROADMAP.md`，内容预算和视听资源策略见 `docs/CONTENT_BUDGET.md`、`docs/CONTENT_AND_ASSET_STRATEGY.md`。当前决策状态见 `docs/P0_DECISION_LOG.md`，P1 规格与验收证据见 `docs/P1_EXPERIENCE_PROTOTYPE.md`、`docs/P1_VERIFICATION.md`。迁移审计与矩阵仅保留为历史参考。
