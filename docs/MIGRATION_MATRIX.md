# G0 逐项迁移矩阵

状态定义：`reuse` 原语义/内容可直接保留；`adapt` 轻度调整格式/事实；`rewrite` 保留语义但按 Godot 边界重写；`archive-only` 只保留旧库历史；`reject` 禁止进入新工程；`blocked` 需要授权、技术验证或用户决定。

## 权威文档

| 来源项 | 状态 | G1/Godot 目标 |
| --- | --- | --- |
| `AGENTS.md` | rewrite | 新根 `AGENTS.md`，Godot/GDScript 基线；Cocos 阶段标历史 |
| `PLANS.md` | rewrite | 新根 `PLANS.md`，独立 G0～G13 |
| `docs/DEMO_SCOPE.md` | adapt | 保留范围/四图/不做项，更新实现事实 |
| `docs/NARRATIVE_BIBLE.md` | reuse | 叙事真相、阶段与保密边界 |
| `docs/NPC_BIBLE.md` | adapt | 15 人稳定 ID/规则；移除旧阶段实现说明 |
| `docs/FIRST_BARRIER_ANOMALY.md` | adapt | 保留事件 ID、节拍、状态和回退；目标 Godot 表现接口 |
| `docs/DEMO_SAVE_AND_CALENDAR.md` | adapt | 新 Save Schema / adapters 的权威输入 |
| `docs/MINE_COMBAT_SLICE.md` | adapt | G8 目标；Cocos adapter 改 Godot |
| `docs/DEMO_MAP_FLOW.md` | adapt | G6 四地图拓扑/锚点输入 |
| `docs/GAME_DESIGN.md` | adapt | 产品愿景与 Demo 支柱；G1 重写，后续随当前里程碑维护事实 |
| `docs/TECH_SPEC.md` | rewrite | Godot 技术事实与里程碑 |
| `docs/PLATFORM.md` | rewrite | `windows-native`/`web` + 渠道抽象 |
| `docs/DATA_SCHEMA.md` | rewrite | JSON v1 目录与 Godot 新存档 schema |
| `docs/ART_BIBLE.md`、`ART_ASSET_LIST.md`、`ART_GUIDE.md` | adapt | 新 `ART_BIBLE.md`；资源状态分离 |
| `docs/UI_SPEC.md` | adapt | Godot Control/CanvasLayer 目标，保持 640×360/安全区 |
| `docs/DIALOGUE_SPEC.md` | adapt | 对白数据与显式表情状态，不绑定 Cocos |
| `docs/STORAGE_POLICY.md` | adapt | D 盘 Godot/editor_data/.godot/构建规则 |
| `docs/DUAL_TRACK_PRODUCTION.md` | adapt | Godot 主线与独立资源轨 |
| `docs/RESOURCE_CREATION_WORKFLOW.md` | adapt | 资源回接目标从 Cocos 改 Godot |
| `docs/LEGAL_AND_IP.md`、`ASSET_SOURCES.md` | adapt | 新法律/来源台账；G1 运行时资源为空 |
| `docs/MVP.md`、`docs/MANUAL_STEPS.md`、旧阶段 ADR/记录 | archive-only | 旧 Cocos 历史基线，只在审计引用，不当当前能力 |
| `CONTEXT.md`、旧 `README.md` | archive-only | 旧工程上下文；新 README 重写 |

## 数据与地图

| 来源项 | 状态 | Godot 目标 |
| --- | --- | --- |
| `assets/data/crops.json` | reuse | `data/crops.json`；G2 `CropCatalogCodec` |
| `assets/data/items.json` | reuse | `data/items.json`；G2 `ItemCatalogCodec` |
| `assets/data/tools.json` | reuse | `data/tools.json`；G2 `ToolCatalogCodec` |
| `assets/data/localization.json` | adapt | `data/localization.json`；地图名称更新为四图 |
| `assets/data/demo-world.json` | adapt | `data/demo_world.json`；场景路径保持 null 直到 G6 |
| `assets/data/runtime-resources.json` | adapt | `data/runtime_resources.json`；Cocos kind/path 改 Godot kind/null path |
| `assets/data/maps.json` | archive-only | 旧 `mvp_farm` 技术图定义；正式拓扑由 `demo_world` 管理 |
| `assets/maps/mvp_farm.tmx` | adapt | G3 `maps/smoke/` 小图验证输入；尚未复制/导入 |
| `mvp_farm_ground.png`、`mvp_farm_stone.png` | adapt | G3 原创冒烟 TileSet 输入；尚未复制 |
| 四张正式地图 TMX | blocked | 旧库不存在；G6 依灰盒/资源确认后制作或迁入 |
| Cocos `.meta` / Creator UUID | reject | 不进入 Godot；UID 由 4.7.1 生成 |

## 纯规则与数据 TypeScript

所有 `rewrite` 项都必须有对应的强类型 GDScript 目标；迁移测试意图，不复制 TypeScript 文件结构。

| 来源文件 | 状态 | 目标 Godot 模块/里程碑 |
| --- | --- | --- |
| `data/GameDataTypes.ts` | rewrite | `scripts/domain/catalog/game_data_types.gd` / G2 |
| `data/GameDataValidator.ts` | rewrite | `scripts/domain/catalog/game_data_validator.gd` / G2 |
| `data/CropDataDecoder.ts` | rewrite | `scripts/domain/catalog/crop_catalog_codec.gd` / G2 |
| `data/ItemDataDecoder.ts` | rewrite | `scripts/domain/catalog/item_catalog_codec.gd` / G2 |
| `data/DemoWorldCatalog.ts` | rewrite | `scripts/domain/world/demo_world_catalog.gd` / G2 |
| `data/index.ts` | reject | GDScript 不建机械 barrel 文件 |
| `farming/FarmState.ts` | rewrite | `scripts/domain/farming/farm_state.gd` / G2 |
| `farming/CropPlanting.ts` | rewrite | `scripts/domain/farming/crop_planting.gd` / G4 |
| `farming/CropHarvesting.ts` | rewrite | `scripts/domain/farming/crop_harvesting.gd` / G4 |
| `farming/CropInventoryActions.ts` | rewrite | `scripts/domain/farming/crop_inventory_transaction.gd` / G4 |
| `farming/CropProjection.ts` | rewrite | `scripts/gameplay/farming/crop_projector.gd` / G4 |
| `farming/FarmDayCycle.ts` | rewrite | `scripts/domain/farming/farm_day_cycle.gd` / G4/G5 |
| `farming/TilledSoilProjection.ts` | rewrite | `scripts/gameplay/farming/soil_projector.gd` / G4 |
| `farming/WateredSoilProjection.ts` | rewrite | `scripts/gameplay/farming/soil_projector.gd` / G4 |
| `farming/SleepPointProjection.ts` | rewrite | `scripts/gameplay/interactions/sleep_point.gd` / G5 |
| `inventory/InventoryState.ts` | rewrite | `scripts/domain/inventory/inventory_state.gd` / G2/G4 |
| `inventory/Quickbar.ts` | rewrite | `scripts/domain/inventory/quickbar_state.gd` / G2/G4 |
| `player/PlayerMovement.ts` | rewrite | `scripts/domain/player/movement_intent.gd` / G3 |
| `player/index.ts` | reject | 不建立机械 barrel |
| `world/GridCollision.ts` | rewrite | `scripts/domain/world/grid_collision.gd` / G3 |
| `world/CameraBounds.ts` | rewrite | `scripts/domain/world/camera_bounds.gd` / G3 |
| `world/TileInteraction.ts` | rewrite | `scripts/domain/world/tile_coordinates.gd` / G3 |
| `world/TileFarmability.ts` | rewrite | `scripts/domain/world/farmability.gd` / G3/G4 |
| `world/MapNavigation.ts` | rewrite | `scripts/domain/world/map_navigation.gd` / G2/G6 |
| `resources/ResourceCatalog.ts` | rewrite | `scripts/domain/catalog/resource_manifest.gd` / G2/G10 |
| `core/save/SaveData.ts` | rewrite | `scripts/domain/save/save_snapshot.gd`（新 schema）/ G2/G5 |
| `core/save/SaveCodec.ts` | rewrite | `scripts/domain/save/save_codec.gd` / G2/G5 |
| `core/save/SaveGame.ts` | rewrite | `scripts/app/save/save_session.gd` / G5 |
| `core/save/AutosaveSession.ts` | rewrite | `scripts/app/save/autosave_session.gd` / G5 |
| `core/save/RuntimeSaveState.ts` | rewrite | `scripts/domain/save/runtime_snapshot.gd` / G5 |
| `core/save/index.ts` | reject | 不建立机械 barrel |
| `platform/PlatformContracts.ts` | rewrite | `scripts/platform/contracts/*.gd` / G2 |
| `platform/PlatformAdapters.ts` | rewrite | `scripts/platform/adapters/`；Memory 仅测试 / G2/G5 |
| `platform/PlatformComposition.ts` | rewrite | 扩展 `scripts/app/composition_root.gd` / G2/G5 |
| `platform/index.ts` | reject | 不建立机械 barrel |

## Cocos Node、场景与表现适配

| 来源文件/项 | 状态 | 目标 Godot 模块/里程碑 |
| --- | --- | --- |
| `player/PlayerController.ts` | rewrite | `CharacterBody2D` `scripts/gameplay/player/player_controller.gd` / G3 |
| `player/PlayerPlaceholderView.ts` | rewrite | `Sprite2D`/`Polygon2D` 可替换占位 / G3 |
| `world/TiledCollisionBridge.ts` | rewrite | `TileMapLayer`/physics adapter / G3 |
| `world/BoundedCameraFollow.ts` | rewrite | `Camera2D` 跟随/limit bridge / G3 |
| `world/ScreenTileMapper.ts` | rewrite | Camera2D viewport→world→map adapter / G3 |
| `world/TileInteractionDebugView.ts` | rewrite | `Line2D`/自绘 debug overlay / G3 |
| `farming/TiledTillingController.ts` | rewrite | farming input bridge / G4 |
| `farming/TiledPlantingController.ts` | rewrite | farming input bridge / G4 |
| `farming/TiledWateringController.ts` | rewrite | farming input bridge / G4 |
| `farming/TiledSleepingController.ts` | rewrite | sleep interaction bridge / G5 |
| `farming/CropView.ts` | rewrite | Sprite2D/AnimationPlayer crop presenter / G4/G10 |
| `farming/TilledSoilView.ts` | rewrite | TileMapLayer overlay presenter / G4 |
| `farming/SleepPointView.ts` | rewrite | interaction marker/presenter / G5 |
| `ui/QuickbarView.ts` | rewrite | Control/CanvasLayer quickbar / G4/G9 |
| `platform/KeyboardInputBridge.ts` | rewrite | InputMap-backed desktop adapter / G3 |
| `platform/TouchInputPort.ts` | rewrite | semantic touch adapter / G9/G12 |
| `platform/CocosLocalSaveService.ts` | rewrite | Windows file SaveService; Web adapter later / G5/G12 |
| `resources/CocosResourceRegistry.ts` | rewrite | Godot ResourceLoader/manifest resolver / G10 |
| `save/RuntimeSaveBridge.ts` | rewrite | scene/session snapshot bridge / G5 |
| `save/LocalAutosaveController.ts` | rewrite | application save coordinator / G5 |
| `world/CocosMapRuntimePort.ts` | rewrite | Godot map scene port / G6 |
| `world/DemoMapNavigator.ts` | rewrite | Godot scene transition coordinator / G6 |
| `world/MapAnchor.ts` | rewrite | Marker2D/group-based named anchor / G6 |
| `world/MapSceneRoot.ts` | rewrite | per-map Node2D root contract / G6 |
| `assets/scenes/Main.scene` | rewrite | 新 `.tscn`；G1 只建最小 Main，玩法树后续分阶段 |
| Cocos Graphics 视觉 | reject | 不复制引擎绘图实现；只保留色板/语义 |

## 测试与工具

| 来源项 | 状态 | Godot 目标 |
| --- | --- | --- |
| `tests/data/*.test.mts` | adapt | G2 JSON codec tests |
| `tests/farming/*.test.mts` | adapt | G2/G4 domain tests |
| `tests/inventory/*.test.mts` | adapt | G2/G4 transaction tests |
| `tests/world/*.test.mts` | adapt | G3 coordinate/collision tests |
| `tests/player/PlayerMovement.test.mts` | adapt | G3 movement tests |
| `tests/player/CocosComponentMetadata.test.mts` | reject | Creator 元数据无 Godot 价值 |
| `tests/platform/*.test.mts` | adapt | G2/G5 service contract tests |
| `tests/core/*.test.mts` | adapt | G2/G5 codec/session/corruption tests |
| `tests/resources/ResourceCatalog.test.mts` | adapt | G2/G10 manifest tests |
| `tools/generate-stage3-smoke-assets.mts` | adapt | G3 确定性地图 fixture 工具；输出留 D 盘 |
| `tests/support/registerProjectTypeScriptResolver.mts` | reject | Node/TypeScript 专用 |

## 资源源文件与生成目录

| 来源项 | 状态 | 处理 |
| --- | --- | --- |
| `art-source/concepts/visual-pilot-001` 文档 | reuse | 许可/确认事实已写入审计；完整旧记录留旧库 |
| A-8、P-01～P-05、SH-01 等 AI 原图/总览 | blocked | 尚未商业清权与人工重构；G1 不复制，不进 `assets` |
| SH-02～SH-05 | blocked | 未绑定具体 NPC |
| 沈禾 neutral/smile/surprised 候选 | blocked | 尚未用户选择 |
| `audio-source` 工作流占位 | adapt | 新目录/`.gdignore`；无音频可迁 |
| `library`、`temp`、`build`、`profiles`、缓存 | reject | 永不复制 |
| `.git`、`.codegraph` | reject | 新仓库独立初始化/以后独立索引 |
| `.creator`、`settings` | archive-only | 旧编辑器历史配置，不适用于 Godot |
| 来源不明或无许可素材 | reject | 不进入仓库/构建 |
