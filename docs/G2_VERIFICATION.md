# G2 验证记录

> 本文件是 2026-07-20 技术基线的历史验收证据。下文 G3～G13 只表示当时明确未实现的旧路线范围；产品重基线后不再将其当作正式 backlog。

## 入口

- 运行入口：`res://scenes/Main.tscn`。
- 数据入口：`CatalogFileLoader.load_catalog()` 读取 `res://data` 七份文档，再由 `GameCatalogCodec.decode_documents()` 原子发布强类型目录。
- 纯领域入口：`InventoryState`、`FarmState`、`SaveCodec`。
- 平台边界：`PlatformService`、`SaveService`、`InputService`、`AudioService`、`AnalyticsService`。

## 验收标准

- Godot 4.7.1 stable 实际解析全部新增强类型 GDScript。
- 有效目录产生四物品、一作物、15 名 NPC、四地图、六 portal 和语义资源索引。
- 重复 ID、未知交叉引用、非法枚举或破损本地化会拒绝整个目录。
- 背包增减和八格选择是全有或全无事务。
- 普通地面不进入 `FarmState`；成功开垦只加入目标 `Vector2i` 格。
- 新 `SaveCodec` 使用 `schemaVersion`，完成完整快照往返，拒绝旧 Cocos payload、未知版本、非法 JSON 和破损引用。
- 运行环境与发行渠道分别表达；Steam/Web、微信/Windows 的错误组合被拒绝。
- `Main.tscn` 启动时实际装配已校验目录，且 G1 smoke 不回归。

## TDD 证据

每个公共 seam 都先执行过红灯：目录 codec、背包、农田状态、SaveCodec、平台契约和 composition root 在对应脚本不存在或能力缺失时均以非零状态失败；实现后逐项转绿。测试只通过公共接口观察行为，没有 mock 项目内部模块。

## 明确未实现

- G3 的移动、碰撞、Camera2D、InputMap、瓦片坐标和小地图。
- G4 的播种、浇水、成长、收获、背包 UI 和完整农耕闭环。
- G5 的三档文件、最近档、原子写入、自动保存、跨天和恢复流程。
- G6～G13 的正式地图、NPC、战斗、应用 UI、正式资源、导出与渠道 adapter。
- `CocosSaveImporter`；正常 `SaveCodec` 永远不读取旧 `saveVersion`。

## 人工步骤

无。G2 验收全部可由 headless、启动场景和文件检查完成。

## 自动结果（2026-07-20）

- Godot `4.7.1.stable.official.a13da4feb` headless editor/import：exit 0。
- G1 smoke：7 项 PASS，`G1_SMOKE_OK`。
- G2 catalog：22 项 PASS，`G2_CATALOG_OK`。
- G2 inventory：18 项 PASS，`G2_INVENTORY_OK`。
- G2 farm state：12 项 PASS，`G2_FARM_STATE_OK`。
- G2 save codec：16 项 PASS，`G2_SAVE_CODEC_OK`。
- G2 platform contracts：16 项 PASS，`G2_PLATFORM_CONTRACTS_OK`。
- G2 bootstrap：8 项 PASS，`G2_BOOTSTRAP_OK`。
- 默认 Main headless 启动：exit 0，输出 `G2 ready · 4 items · 4 maps · pure domain active`。
- 合计 99 项行为检查通过；无 GDScript 解析错误。
- 项目 `.godot`：D 盘项目目录内 24 个文件、670057 bytes，Git 忽略命中。
- C 盘 Godot 自动日志：5 个、合计 2709 bytes；无项目资源、存档或唯一副本。
- 工作树无 1 MiB 以上新增文件，`assets/` 仍只有四个 `.gitkeep`，未引入来源不明资源。

## Git 状态

G0～G1 基线为 `02a442da46549c814e332b5dd36c50822d31dc5c`。用户已于 2026-07-20 明确授权建立并推送 G2 基线；本轮发布结果以交接中的 commit/hash 为准。
