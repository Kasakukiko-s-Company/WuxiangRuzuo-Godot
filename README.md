# 雾乡如昨 / WuxiangRuzuo

《雾乡如昨》是一款正在正式制作的原创 2D 生活模拟与悬疑探索游戏。本仓库以 Godot 4 开发完整游戏；旧 Cocos Creator 工程只是早期雏形和可选参考，不是产品规格或内容上限。

当前状态：**G0～G2、P0～P1 与 H01 地产地图先导均已有独立远端基线；P2 正在实现核心生活循环**。默认 Main 可选择三个独立档位进入 H01 地产生活闭环，并以 schema v2 在 D 盘开发目录原子保存当前状态和受保护恢复点。耕地、播种、浇水、跨日成长、可确认日结反馈、收获、每日资源选择、轻量交换、暂停/安全返回和常驻目标均已可运行；本地节奏证据采集已就绪，但尚无真人样本和据此完成的平衡复盘，因此仍不代表 P2 完成。

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
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p2/test_crop_planting.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p2/test_crop_day_cycle.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p2/test_crop_harvesting.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p2/test_h01_farming_loop.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p2/test_h01_input_route.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/p2/test_p2_day_transition.gd
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 2
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --path . --resolution 1280x720 --script res://tools/capture_h01_estate_pilot.gd
```

完整游戏方向见 `docs/FULL_GAME_VISION.md` 与 `docs/PRODUCT_BRIEF.md`，制作阶段见 `docs/FULL_GAME_ROADMAP.md`，内容预算和视听资源策略见 `docs/CONTENT_BUDGET.md`、`docs/CONTENT_AND_ASSET_STRATEGY.md`。P2 当前农作切片和本地节奏证据边界见 `docs/P2_FARMING_LOOP.md`、`docs/P2_PACING_EVIDENCE.md`；迁移审计与矩阵仅保留为历史参考。
