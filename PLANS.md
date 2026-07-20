# 《雾乡如昨》完整游戏制作计划

## 状态口径

旧 Cocos 工程是未达到 Demo 标准的雏形，只能提供可选素材、技术经验和反例。G0～G2 记录已经完成的迁移审计与技术底座，不定义完整游戏规模；旧 G3～G13 已停止，不再按 Cocos 功能清单推进。

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

## P0 产品重基线

状态：产品方向与 P1 规格已获用户确认；相关文件仍与 P1 一起位于未提交工作区，尚未建立或推送基线。

已形成 `FULL_GAME_VISION.md`、`PRODUCT_BRIEF.md`、`FULL_GAME_ROADMAP.md`、`CONTENT_AND_ASSET_STRATEGY.md`、`CONTENT_BUDGET.md`、`P0_DECISION_LOG.md` 与 `P1_EXPERIENCE_PROTOTYPE.md`。正式游戏目标、内容生产轨和“战斗必须存在”已经取代旧 Cocos 雏形范围。

## 当前验收点：P1 体验原型

状态：实现、自动回归和 Compatibility Renderer 画面检查已完成；尚未提交或推送，未进入 P2。

可玩入口：默认 `res://scenes/Main.tscn` 的“进入 P1 体验原型”按钮，或直接运行 `res://scenes/prototypes/p1_experience_probe.tscn`。

已实现：

- 40×28、32px 基础格的全新 `prototype_mist_edge` 灰盒，不复用旧四图。
- 强类型移动意图、四方向面向、对角归一化、96 px/s 移动、`CharacterBody2D` 碰撞与贴墙滑动。
- Camera2D 边界、平滑跟随和 reduce-motion 回退。
- world/cell/facing-cell 坐标 seam，以及 F3 调试叠层。
- 键盘/手柄共用的语义输入 adapter；移动、交互、画质、暂停、重置与调试动作均有默认绑定。
- 8 个可检查对象，一次性/可重复反馈，交互锁定与自动恢复。
- 可整体替换的程序化地形、玩家、前景遮挡、高低画质和原创生成式原型音频；未导入来源不明资源。
- Main 场景明确入口和可重复的非 headless 视觉捕获工具。

自动验证（2026-07-20）：

- Godot 4.7.1 stable editor/import、默认 Main 与 P1 直接启动均为 exit 0，最终日志无解析错误或对象泄漏警告。
- G1+G2 原有 99 项行为检查和 P1 35 项行为检查全部通过，共 134 项。
- Compatibility Renderer 实际使用 Intel Iris Xe / OpenGL 3.3 渲染；自动生成高、低画质与调试视图，均为 640×360 逻辑视口的 2× 物理输出（1280×720）。
- 高/低画质像素输出不同；低画质仍保留路径、角色、碰撞边界和交互提示。完整记录见 `docs/P1_VERIFICATION.md`。

## 后续制作阶段

正式阶段见 `docs/FULL_GAME_ROADMAP.md`。概要为 P1 体验原型、P2 核心生活循环垂直切片、P3 城镇与关系垂直切片、P4 探索与叙事垂直切片、P5 内容生产管线和质量标杆、P6 全流程 Alpha、P7 内容完成、P8 Beta、P9 Windows/Steam 发行候选。Web/微信实际开发已确认后置到 P9 之后，依次执行 W0 标准 Web、W1 微信可行性和 W2 发布决策；当前不下载模板、不安装微信插件、不承诺发布。

## 停止条件

当前停在 P1 验收点。未经用户明确授权，不提交或推送 P0～P1 工作区基线，也不开始 P2。
