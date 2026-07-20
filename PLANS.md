# 《雾乡如昨》Godot 迁移计划

## 状态口径

旧 Cocos 阶段 0～9 是历史技术基线，不代表本 Godot 仓库已实现。Godot 迁移仅使用 G0～G13。

## 已建立基线：G0～G1

### G0 旧项目审计

状态：已完成并包含于首个 `main` 基线。

- 已只读检查旧 Git 状态；旧仓库存在用户未提交变更，未触碰。
- 已优先使用旧 `.codegraph` 理解 TypeScript 调用路径。
- 已盘点文档、代码、数据、TMX、场景、资源源文件、平台、存档与测试。
- 已形成 `docs/MIGRATION_AUDIT.md` 与 `docs/MIGRATION_MATRIX.md`。
- 未复制旧 `.codegraph`、Cocos 缓存、`.meta` 或未清权候选素材。

### G1 Godot 工程基础

状态：已验收并推送；基线提交 `02a442da46549c814e332b5dd36c50822d31dc5c`。

入口：`res://scenes/Main.tscn`。

验收标准：

- Godot 4.7.1 stable 能完成 headless 导入与脚本解析。
- Main 场景能启动，composition root 返回 G1 状态。
- 640×360、`canvas_items + keep` 与 Compatibility Renderer 设置生效。
- 数据只迁移稳定 ID/拓扑清单，未声称玩法已实现。
- Git 仓库独立初始化，`main` 已跟踪新的 `origin/main`。
- `.godot`、构建输出、editor_data 和临时文件不进入 Git。

自动验证（2026-07-20）：

- `--headless --editor --quit`：exit 0，无项目解析错误；self-contained editor_data 写入 D 盘。
- `tests/smoke/test_g1_smoke.gd`：7 项 PASS，输出 `G1_SMOKE_OK`。
- 默认 Main 场景 `--quit-after 2`：exit 0，输出 composition root ready。
- 6 个 JSON：全部通过 PowerShell `ConvertFrom-Json`。
- Git：G0～G1 根提交已推送；`.godot` 与构建输出忽略命中。
- 新项目无大文件；除默认 Godot 运行日志外，长期文件均在 D 盘。

## 当前验收点：G2

状态：实现与验收已完成；用户已于 2026-07-20 明确授权建立并推送 G2 基线。

入口：`res://scenes/Main.tscn`，状态文字显示 G2；自动测试位于 `tests/g2/`。

已实现：

- 七份 JSON 的版本、结构、枚举、范围、重复 ID、本地化和交叉引用原子校验，含 15 名 NPC 稳定身份与关系边界。
- 强类型 `GameCatalog` 及物品、作物、工具、地图、portal、语义资源查询。
- 不依赖 Node 的 `InventoryState`、八格选择和全有或全无增减事务。
- 不依赖 Node 的 `FarmState`、稀疏耕作格状态和开垦事务。
- 新 Godot `SaveSnapshot.schemaVersion=1` 与纯 `SaveCodec` 往返/损坏校验。
- `PlatformService`、`SaveService`、`InputService`、`AudioService`、`AnalyticsService` abstract contracts。
- composition root 实际读取目录并只在完整验证后发布给启动场景。

验收标准：

- Godot headless editor/import、全部 G2 测试、G1 smoke 和默认 Main 启动均为 exit 0。
- 旧 Cocos `saveVersion` 不由新 codec 解码。
- 代码和文档不声称 G3～G13 能力已完成。
- `.godot`、日志、构建、大文件和未知来源资源没有进入 Git 变更。

自动验证（2026-07-20）：Godot editor/import、G1 smoke、六个 G2 测试和默认 Main 启动全部 exit 0；G1+G2 共 99 项行为检查通过。完整记录见 `docs/G2_VERIFICATION.md`。

## 后续里程碑（均未开始）

- G3：移动、碰撞、相机和瓦片交互垂直切片。
- G4：耕地、播种、浇水、成长、收获与背包闭环。
- G5：睡觉、跨天、三档位存档与状态恢复。
- G6：四地图导入、场景切换和地图触发器。
- G7：NPC、对白、好感与关系预览。
- G8：旧矿道、采矿、基础战斗和安全撤离。
- G9：开场、标题、存档界面、HUD 与设置。
- G10：已确认正式资源回接和画质档位。
- G11：Windows 导出与性能验证。
- G12：Web/微信小游戏可行性验证。
- G13：Steam adapter 与发行准备。

## 停止条件

用户已明确授权建立并推送 G2 基线；推送后仍停在 G2，不自动进入 G3。
