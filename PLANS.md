# 《雾乡如昨》Godot 迁移计划

## 状态口径

旧 Cocos 阶段 0～9 是历史技术基线，不代表本 Godot 仓库已实现。Godot 迁移仅使用 G0～G13。

## 当前验收点：G0～G1

### G0 旧项目审计

状态：已完成审计写入，等待与 G1 一并验收。

- 已只读检查旧 Git 状态；旧仓库存在用户未提交变更，未触碰。
- 已优先使用旧 `.codegraph` 理解 TypeScript 调用路径。
- 已盘点文档、代码、数据、TMX、场景、资源源文件、平台、存档与测试。
- 已形成 `docs/MIGRATION_AUDIT.md` 与 `docs/MIGRATION_MATRIX.md`。
- 未复制旧 `.codegraph`、Cocos 缓存、`.meta` 或未清权候选素材。

### G1 Godot 工程基础

状态：工程已落地并通过自动验证，等待用户 G1 验收。

入口：`res://scenes/Main.tscn`。

验收标准：

- Godot 4.7.1 stable 能完成 headless 导入与脚本解析。
- Main 场景能启动，composition root 返回 G1 状态。
- 640×360、`canvas_items + keep` 与 Compatibility Renderer 设置生效。
- 数据只迁移稳定 ID/拓扑清单，未声称玩法已实现。
- Git 仓库独立初始化，远端配置正确但不推送。
- `.godot`、构建输出、editor_data 和临时文件不进入 Git。

自动验证（2026-07-20）：

- `--headless --editor --quit`：exit 0，无项目解析错误；self-contained editor_data 写入 D 盘。
- `tests/smoke/test_g1_smoke.gd`：7 项 PASS，输出 `G1_SMOKE_OK`。
- 默认 Main 场景 `--quit-after 2`：exit 0，输出 composition root ready。
- 6 个 JSON：全部通过 PowerShell `ConvertFrom-Json`。
- Git：`main`、零提交，origin 已配置，未推送；`.godot` 与构建输出忽略命中。
- 新项目无大文件；除默认 Godot 运行日志外，长期文件均在 D 盘。

## 后续里程碑（均未开始）

- G2：数据 Schema 与纯领域模块迁移。
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

本轮完成自动与图形运行验证后停在 G1。用户已于 2026-07-20 明确授权“提交并推送 Godot G0～G1 基线”；当前仓库状态用于建立首个 `main` 基线提交。推送后仍不自动进入 G2，需先汇报发布结果。
