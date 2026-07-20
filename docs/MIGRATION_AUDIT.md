# G0 旧 Cocos 项目迁移审计

> 历史定位：本审计准确记录旧仓库当时有哪些文件和技术语义，但其中“权威产品资料”、G3～G13 建议和复用结论已被 P0 产品重基线降级为候选输入，不得用于限制完整游戏规模。

审计日期：2026-07-20。来源只读路径：`D:\lzq\AI游戏\FarmGame`。目标唯一写入路径：`D:\lzq\AI游戏\WuxiangRuzuo-Godot`。

## 结论

旧工程拥有可复用的产品/叙事权威资料、稳定 ID、JSON 数据、一个原创 Tiled 冒烟地图和较完整的 TypeScript 技术 MVP。它并没有四张正式地图、完整三档存档、NPC 运行时、旧矿道战斗或正式资源回接。迁移策略应保留领域语义，按 Godot 边界重写实现，不能逐文件机械翻译或复制 Cocos 场景绑定。

G1 只迁移稳定数据与工程事实；玩法实现从 G2 分阶段开始。

## 工具与仓库状态

- Godot 编辑器：`D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe`。
- 实际版本输出：`4.7.1.stable.official.a13da4feb`。
- 同发行包控制台入口：`Godot_v4.7.1-stable_win64_console.exe`。
- self-contained 标记 `_sc_` 存在；`editor_data/` 与 `editor_settings-4.7.tres` 位于同一 D 盘发行目录。
- 旧仓库分支：`main...origin/main`；存在 13 个已修改文件和大量未跟踪资源/代码/测试。它们均为用户现有工作，审计未写入旧仓库。
- 旧 remote：`git@github.com:Kasakukiko-s-Company/AI-game-FarmGame.git`。
- 新远端在 2026-07-20 以只读 `git ls-remote` 检查，返回零引用；按空仓库处理。
- 旧项目存在 `.codegraph/`；代码理解先执行 `codegraph explore`。该目录未复制。
- Godot self-contained 的编辑器数据确实位于 D 盘；Windows 默认运行日志仍位于 `C:\Users\26478\AppData\Roaming\Godot\app_userdata\雾乡如昨\logs`，本轮为 2 个文件、0.56 KiB。它们不是项目资源或唯一副本。

## 有效文件盘点

以下统计排除了 `.git`、`.codegraph`、`library`、`temp`、`build` 和 `profiles`：

| 类别 | 数量/体积 | 审计结论 |
| --- | ---: | --- |
| Markdown 文档 | 57 | 产品/叙事权威文档复用；Cocos 技术记录归档为历史 |
| TypeScript `.ts` | 59 | 领域语义重写为 GDScript；Cocos 适配层全部重写 |
| 测试/工具 `.mts` | 38 | 测试意图适配 Godot；Cocos 元数据测试拒绝迁移 |
| 项目 JSON | 8 | 稳定 ID/拓扑复用；G2 建立强类型解码与验证 |
| Tiled TMX | 1 | 仅 `mvp_farm.tmx` 冒烟图，不是四张正式地图 |
| Cocos 场景 | 1 | `assets/scenes/Main.scene`，32.3 KiB；只作结构参考 |
| Cocos `.meta` | 97 | 全部拒绝迁移 |
| PNG | 127 | 两个 32×32 原创冒烟瓦片可适配；其余候选不进入运行时 |
| `art-source` | 151 文件，298.57 MiB | 概念/AI 候选，保留旧库；G1 不复制 |
| `audio-source` | 5 文件，约 0 MiB | 目录/工作流资料，无已确认运行时音频 |
| 旧有效 `assets` | 183 文件，约 0.28 MiB | 绝大部分为脚本、`.meta` 和小型测试资源 |

## TypeScript 边界

### 可保留语义的纯规则

- 农田/作物：`FarmState`、`CropPlanting`、`CropHarvesting`、`FarmDayCycle`、`CropInventoryActions`。
- 背包/快捷栏：`InventoryState`、`Quickbar`。
- 运动/网格：`PlayerMovement`、`GridCollision`、`CameraBounds`、`TileInteraction`、`TileFarmability`。
- 存档：`SaveData`、`SaveCodec`、`SaveGame`、`AutosaveSession`、`RuntimeSaveState`。
- 数据/资源目录：各 JSON decoder、`ResourceCatalog`、`DemoWorldCatalog`、`MapNavigation`。

这些模块包含有价值的不变量、事务和失败状态，但 G2/G3/G4/G5 应重写为强类型 GDScript，并按新的三档/schemaVersion 目标调整；不得假设旧 SaveData v1 已满足新方案。

### 必须重写的 Cocos 适配

- 所有导入 `cc` 的 `Component`：`PlayerController`、Tiled farming controllers/views、Camera follow、screen mapper、resource registry、autosave controller/bridge、quickbar view 等。
- `CocosLocalSaveService` 对 `sys.localStorage` 的绑定。
- `Main.scene` 的 Creator UUID/组件绑定。
- `Graphics` 占位画法与 Cocos `TiledMap` 坐标换算。

旧 `PlatformComposition` 只是接口护栏；Creator 场景未由该 composition root 启动，不能标记为真实平台装配完成。

## 地图审计

`assets/maps/mvp_farm.tmx` 的实际格式：Tiled 1.12.2、TMX 1.10、orthogonal、finite `30×30`、`32×32` tile、`renderorder=right-down`、嵌入 tileset、CSV 未压缩数据。层为 `Ground`、`Obstacles`、隐藏 `Blocking`；没有对象层、出生点、睡觉点、出口或正式四图锚点。

两个瓦片 PNG 为项目脚本确定性生成的原创几何占位，SHA-256 与来源在旧 `docs/ASSET_SOURCES.md` 有记录。它们可用于 G3 小地图坐标/碰撞验证，但不是正式美术。

Godot 4 的地图目标为 `TileMapLayer`，而不是继续依赖旧 Cocos `TiledMap`。G3 开始前必须验证：

- Tiled 左上原点/行列与旧领域底左坐标之间的 Y 翻转；
- Godot 世界坐标、TileMapLayer `local_to_map`/`map_to_local` 与角色锚点；
- `Ground`、`Ground_Detail`、`Water`、`Path`、`Objects_Back`、`Characters`、`Objects_Front`、`Effects` 的层级；
- 碰撞、可耕、床、出生、出口、异常触发器采用 tile custom data 还是对象层转换；
- 若 Godot 4.7.1 无法可靠直接导入当前 TMX，则建立确定性转换工具，不人工逐格重画。

## 存档审计

旧实现为 `saveVersion=1` 和固定槽 `autosave`，字段覆盖玩家地图/世界坐标/朝向、当前日、背包/选槽、农田/湿土/作物。它缺少三档、最近档、损坏隔离、受保护恢复点、NPC/关系/剧情和完整矿道状态。

Godot 新存档必须使用独立 schema，首字段名统一为 `schemaVersion`。旧 Cocos payload 以后只能由显式 `CocosSaveImporter` 导入，不进入新 `SaveCodec` 的正常读取路径。G1 没有迁移或读取用户的 localStorage。

## 资源、许可证与 LFS

- 旧运行时仅明确登记了两个原创 32×32 冒烟瓦片、测试 TMX 和代码绘制的雾叶草占位。
- `visual-pilot-001` 的 A-8 视觉方向、P-01～P-05 主角候选、SH-01 沈禾造型/比例虽有用户设计确认，但来源记录明确写明：现有 AI 图尚未商业清权、尚未完成严格像素/分层重构，不得复制到运行时 `assets/art`。
- SH-02～SH-05 尚未绑定 NPC；沈禾三组表情候选尚未选择。
- 旧 `art-source` 约 298.57 MiB，单文件最大约 4.957 MiB；当前无单文件超过常见 GitHub 100 MiB 硬限制，但二进制集合增长快、PNG 不适合普通 Git 历史。
- 建议在 G10 正式回接前确定 Git LFS：至少跟踪经确认的 `.psd`、`.kra`、`.aseprite`、无损音频和大 PNG；本轮不创建 LFS 属性，也不提交旧候选。
- 未发现可迁移的正式音乐、音效或字体。来源不明资源一律 `reject/blocked`。

## G0 输出边界

逐项处置与目标模块见 `MIGRATION_MATRIX.md`。G0 没有修改旧工程，没有复制缓存、`.meta`、Creator UUID、旧 `.git` 或旧 `.codegraph`。
