# Godot 插件评估与采用护栏

状态：2026-07-20 调研完成；**当前没有安装任何插件，也没有修改 `project.godot` 或现有代码**。

## 结论

插件可以提高生产效率，但不能用一个“全套 RPG 框架”替换本项目已经确定的领域层、平台 adapter、版本化 JSON 和稳定 ID。最值得优先验证的是：

1. `Dialogue Manager 3.10.4`：首选对话候选；只让它解释对白，不让它成为关系、任务或存档状态的权威。
2. `Tiled 1.12.2` 自带 Godot 4 exporter 与 `YATI 2.2.7`：用同一张小地图做 A/B，选出可重复、可测试的转换链。
3. `Quest Manager 1.3.2`：仅在 P3 用代表性任务树验证；必须包在项目自己的任务边界后。
4. `Godot State Charts 0.22.5`：用于 NPC 日程或战斗状态的候选，不用它承载农田、关系、经济等领域真相。
5. `Aseprite Wizard 9.8.0`：仅作为开发期资源导入候选；也要与直接调用 Aseprite CLI 的可重复脚本比较。
6. `GodotSteam GDExtension 4.20.1`：P9 的 Steam adapter 候选，现在不接入核心玩法。

`Dialogic`、完整 RPG 框架、背包框架、通用存档插件、相机和复杂 AI 插件目前都不应直接进入主工程。这里的“采用候选”也只表示值得做独立试验，不表示现在安装。

## 不需要插件的部分

以下能力优先使用 Godot 4.7.1 自带功能，第三方插件不会让核心架构更简单：

- 地图运行时：`TileMapLayer`、`TileSet`、Terrain、物理层和 custom data。第三方工具只负责把 Tiled 权威源稳定转换进来。
- 玩家存档：`FileAccess`、`user://` 与项目自己的 `SaveCodec` / `SaveService`；编辑期 `Resource` 不等于玩家存档方案。
- 输入与相机：`InputMap`、`Camera2D`。现有实现不足以支持演出需求时，才复核相机插件。
- 寻路：`NavigationServer2D`、`NavigationRegion2D`、`NavigationAgent2D`。行为决策与寻路保持分离。
- 动画和音频：`AnimationPlayer`、`AnimationTree`、Audio Bus、`AudioStreamPlayer` 系列；先建立项目自己的资源和服务边界。
- 本地化：Godot TranslationServer、CSV/gettext 导入；对白插件只能消费稳定文本 ID，不能成为翻译数据的唯一副本。

## 决策表

| 方向 | 候选与一手事实 | 侵入性与主要风险 | 决策 |
| --- | --- | --- | --- |
| 对话 | [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) 是 MIT、无状态对白运行时；3.x 面向 Godot 4.4/4.5，仓库当前 4.x 主线明确仍未正式发布并建议使用 v3；官方 Asset Library 的 [3.10.4 条目](https://godotengine.org/asset-library/asset/3654) 标记 Godot 4.4。 | 4.7.1 未被已发布版本明确列为测试目标；表达式/Mutation 若直连游戏对象，会绕过领域 API。 | **采用候选，优先隔离试验**。锁定 `3.10.4`，自制 balloon；对白只能调用 `DialogueFacade`。 |
| 对话 | [Dialogic 2](https://github.com/dialogic-godot/dialogic) 为 MIT，最新发布是 [2.0 Alpha 19](https://github.com/dialogic-godot/dialogic/releases)，最低 Godot 4.4；发布说明仍列有 breaking changes，并修改过变量、音频和存档相关语义。 | Alpha、功能面大、Autoload/时间线/变量/布局较深，升级和存档耦合风险高；自动更新器也不符合固定版本策略。 | **暂缓**。只有 Dialogue Manager 无法满足立绘演出和编剧工作流时才做对照试验；禁止自动更新。 |
| 地图 | [Tiled 1.12.2](https://github.com/mapeditor/tiled/releases) 自带 Godot 4 exporter；[官方导出文档](https://doc.mapeditor.org/en/stable/manual/export-tscn/)说明它自 Tiled 1.10 提供，可导出层、tile custom data 和带 `resPath` 的对象，但不支持 image-collection tileset、image layer 等若干特性。 | 文档仍以 Godot `TileMap` 输出描述，而 Godot 已将 `TileMap` 标为弃用并推荐多个 [`TileMapLayer`](https://docs.godotengine.org/en/4.3/classes/class_tilemaplayer.html)；不能假定 4.7.1 输出结构正好满足项目层级、碰撞和触发器语义。 | **采用候选，必须隔离试验**。保留 TMX/TSX 为权威源，用小地图验证输出并决定是否加项目自有后处理器。 |
| 地图 | [YATI 2.2.7](https://github.com/Kiamo2/YATI) 为 MIT、Godot 4.3+，维护者记录测试环境为 Godot 4.6.1 + Tiled 1.12；支持 GDScript 版本、对象、碰撞、动画、模板和 custom properties。 | 维护者同时警告 Windows 多地图多线程导入可能冻结/崩溃，并列出坐标渲染、椭圆和动画限制；未声明 4.7.1。 | **隔离 A/B 候选**，不是默认依赖。只测 GDScript 包；与 Tiled 官方 exporter 比较确定性、节点结构和再导入差异。 |
| 任务 | [Quest Manager 1.3.2](https://github.com/Rubonnek/quest-manager) 为 MIT、纯 GDScript、Godot 4.2.1+；提供层级任务树、多种任务状态、Callable 条件、信号、调试 viewer 和序列化。[官方 Asset Library](https://godotengine.org/asset-library/asset/3470)记录了相同版本。 | 4.7.1 未明确测试；Callable 不是内容 Schema，插件序列化也不能取代项目存档迁移、损坏隔离和原子写入。 | **隔离试验**。P3 用一条跨日、关系门槛、可失败任务验证；插件进度必须映射到项目稳定 ID/SaveCodec。 |
| 背包 | [GLoot 3.0.1](https://github.com/peter-kish/gloot) 为 MIT、Godot 4.4+，提供 JSON item prototype、Node 型 inventory/constraint/slot、UI 和序列化；3.0 对 2.x 有不兼容改动。 | 会与现有纯领域 `InventoryState`、事务和存档 Schema 重叠；动态 item property 容易扩大 Variant 面。 | **暂缓**。可以参考约束/UI，但不作为核心背包权威，除非 P2 基准证明自研明显不足。 |
| RPG 框架 | [GDQuest Open RPG](https://github.com/gdquest-demos/godot-open-rpg) 明确写明它是 Godot 4.6.2 的学习 demo，“not trying to build a framework”；[Godot JRPG 0.0.3](https://godotengine.org/asset-library/asset/5099)仍是 early alpha，多个系统只是 skeleton；[Skelerealms 0.6](https://godotengine.org/asset-library/asset/3296)是 2024 年的 Bethesda 风格 3D open-world early alpha。 | 导入整套工程会反转架构、带入无关资源/规则，并把生活模拟、关系叙事和即时战斗强行套入他人产品结构。 | **拒绝作为依赖**。Open RPG 只可只读学习；其余不进入试验队列。 |
| RPG Maker 式事件 | 目前没有找到同时具备 4.7.1 明确支持、稳定发布、低侵入和适配本项目语义的通用事件插件；Godot JRPG 仍是上述 early alpha。 | “地图事件”常把条件、对白、任务、传送、奖励和存档塞进单个 Node/解释器，形成新的巨型全局系统。 | **拒绝通用框架**。项目应做稳定 ID + JSON 的 World Event 定义和小型解释器；对话、任务、传送通过显式端口组合。 |
| 存档 | Godot 官方说明 [`Resource`](https://docs.godotengine.org/en/latest/classes/class_resource.html) 是可序列化数据容器；但官方[保存游戏指南](https://docs.godotengine.org/en/4.5/tutorials/io/saving_games.html)也明确指出存档高度项目化，并使用 `user://`、`FileAccess` 与 JSON/binary；JSON 有类型与体积限制。 | `.tres` 能写盘不等于具备 schemaVersion、三档位、原子替换、恢复点、损坏隔离、平台 adapter 或旧档迁移。第三方 save manager 会与这些硬需求重叠。 | **拒绝通用存档插件作为权威**。继续项目自己的 `SaveCodec` + `SaveService` adapter；Resource 只用于编辑期定义或显式转换后的数据。 |
| 状态/NPC | [Godot State Charts 0.22.5](https://github.com/derkork/godot-statecharts) 为 MIT、纯 GDScript，提供层级/并行状态、guard、延时 transition、编辑器校验和运行调试；作者强调业务代码只接触单一 `StateChart` API，便于移除。 | 仍会给场景树增加状态节点；不应让状态图直接修改背包、关系或存档。版本页只写 Godot 4，没有 4.7.1 专项声明。 | **隔离试验**。优先用于一名 NPC 的日程/对话中断或一个战斗敌人，不用于领域状态。 |
| 复杂 AI | [LimboAI 1.8.0](https://store.godotengine.org/asset/limbonaut/limboai/) 为 MIT C++ GDExtension，发布变更明确加入 Godot 4.7 支持，含行为树、HSM、编辑器和调试器；下载约 32.22 MB。 | 原生二进制、平台/导出组合和仓库体积风险显著；对少量 2D 敌人可能过度设计，Web/微信还要单独验证。 | **暂缓到 P4**。只有自有 FSM/State Charts 无法表达代表性敌人时再试；进入 Git 前先定二进制/LFS 策略。 |
| 复杂 AI | [Beehave](https://github.com/bitbrain/beehave) 为 MIT、纯 GDScript 行为树；仓库说明 Godot 4.5+ 应使用 2.10+，但截至本次核验最新正式 release 仍为 2.9.2。 | 官方兼容表与已发布版本不闭合，不能把开发分支当稳定依赖。 | **暂缓当前已发布版本**；等有满足自身兼容表的稳定 release 后再复核。 |
| 相机 | [Phantom Camera 0.11](https://godotengine.org/asset-library/asset/1822) 为 MIT、最低 Godot 4.4，封装 Camera2D/3D 的跟随、多目标构图和镜头切换。 | 当前 P1 相机已通过验证；接入会替换已有、足够小的 Camera2D seam，且无 4.7.1 明确测试声明。 | **暂缓**。P3/P4 出现多目标构图或大量演出镜头时再隔离比较。 |
| 像素资源 | [Aseprite Wizard 9.8.0](https://github.com/viniciusgerevini/godot-aseprite-wizard) 为 MIT、Godot 4 分支，支持 SpriteFrames、AnimationPlayer、tag、slice、帧时长和 tileset texture；只在开发期需要，移除后已导入动画仍可工作。[官方配置文档](https://thisisvini.com/aseprite-wizard/en/9.x-4/introduction/index.html)要求配置 Aseprite 可执行文件。 | 最低版本只标到 Godot 4.4，未明确 4.7.1；自动 importer 与 `.gdignore` 的 `art-source/` 策略存在冲突，并依赖另行授权/安装的 Aseprite CLI。 | **采用候选，隔离试验**。先比较 Wizard 与 [Aseprite 官方 CLI](https://www.aseprite.org/docs/cli/)脚本；保证源文件留在 D 盘、导出可重现、无运行时依赖。 |
| 测试 | [GUT](https://github.com/bitwes/Gut) 为 MIT；9.6.x 正式版面向 Godot 4.6，仓库只有 `godot_4_7` 分支而无对应稳定 release。[gdUnit4 6.1.3](https://github.com/godot-gdunit-labs/gdUnit4)为 MIT，发布兼容表到 Godot 4.6.2；即将发布的 6.2 只列过 4.7 beta1。 | 为迁就测试插件改引擎版本不可接受；开发分支也不应进入当前基线。 | **暂缓**。继续现有 headless 测试；等任一框架正式声明 4.7.1 stable，再用相同测试集比较迁移收益。 |
| Steam | [GodotSteam GDExtension 4.20.1](https://godotengine.org/asset-library/asset/2445) 为 MIT、面向 Godot 4.4+，基于 Steamworks SDK 1.64；官方 GitHub 已归档并[明确迁移到 Codeberg](https://github.com/GodotSteam/GodotSteam)，2026-07-16 仍发布 4.20.1。 | 原生二进制、Steam SDK、打包和平台差异；官方条目列 Windows/Linux/macOS/Android，没有 Web。若核心代码直接调用 `Steam`，会破坏 standalone/web 渠道隔离。 | **P9 条件采用候选**。只实现 `SteamPlatformAdapter`，Steam 不可用时必须无插件依赖地启动；先做 4.7.1 Windows smoke、成就和云存档冲突试验。 |

## Godot 4.7.1 隔离验证流程

Godot Asset Library 的最低版本字段只表示插件声明的最低同主版本，不等于作者已在 4.7.1 上回归；官方提交说明可见[这里](https://godotengine.org/asset-library/asset/submit)。因此所有候选都必须：

1. 在主工程之外的 D 盘临时项目或独立 Git worktree 中，锁定 release tag 和完整 commit SHA；禁止追踪 `main`、自动更新或下载不明构建。
2. 只复制候选的必要 `addons/<name>`，保留 LICENSE、版本、来源 URL、SHA、下载时间和包大小；不得覆盖当前 P0～P1 文件。
3. 使用本项目固定的 `Godot 4.7.1.stable` 执行 headless import、全脚本 parse、候选最小场景和退出泄漏检查。
4. 用一个代表性垂直样例测试边界，而不是先迁移全量内容：一段立绘对白、一张小 TMX、一条跨日任务、一名 NPC 或一个敌人。
5. 验证卸载：停用并移除插件后，项目必须能恢复运行，或明确列出需要迁移的专有资源格式。
6. 对运行时插件检查 Windows/Compatibility Renderer；影响导出的还要检查 Web。GDExtension 另外检查目标平台二进制、包体和 Git LFS。
7. 只有试验结果、许可证和回退方案获确认后，才可单独请求把固定版本加入主工程；不能借“插件更新”自动升级依赖。

## 建议试验顺序

- P2 前：Tiled 官方 exporter vs YATI；Aseprite CLI vs Wizard。
- P3 前：Dialogue Manager 3.10.4；Quest Manager；State Charts。
- P4：先用项目自有 FSM/State Charts 做代表性战斗 AI，证据不足时才试 LimboAI。
- P8/P9：测试框架复核、Phantom Camera 需求复核、GodotSteam adapter。

## 当前执行决定

- 现在不创建 `addons/`，不修改 `project.godot`，也不下载任何插件或二进制包。
- 下一次真正接入前，单独建立一个“插件兼容性试验”验收点；一次只测一个候选，不把多个框架同时放进主工程。
- 优先级是地图转换，其次是对话创作工具；任务、状态图、AI、相机和 Steam 都等到相应玩法出现真实需求后再验证。
- 任何试验都不得改变现有存档 Schema、稳定 ID、领域模块或平台 adapter 的权威地位。

本文件是选型审计，不代表插件已安装、兼容性已验证或正式采用。
