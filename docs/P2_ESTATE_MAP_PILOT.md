# P2 地产地图工程先导

日期：2026-07-24
状态：H01 正式工程先导已实现并自动验证；P2 核心生活循环尚未完成。

## 目的与边界

本先导把地产地图包从“隔离候选”推进到正式工程中的第一条可运行接入链，验证候选数据、正式目录、强类型运行时接口、玩家、碰撞、Camera2D 和主入口能够共同工作。它不决定八块地产最终全部成为可选玩家地产，也不把候选包的技术占位美术标记为发行资源。

本轮没有修改 `SaveSnapshot`、`SaveCodec` 或存档 Schema，没有实现跨图 portal、农耕/建造写入、NPC 日程、剧情触发、钓鱼、季节服务或发行许可。其余 H02～H08 仍是候选输入，等待沿同一接口逐图接入和验证。

## 输入权威与正式投影

- 唯一候选输入：`maps/handoff/estate-map-pack-v1/`，Pack ID `206154e890aeee3e182ac022a76abee9`。
- 正式运行目录投影：`data/estate_maps.json`。它保留八图稳定 ID、尺寸、32px 基础格、安全出生点、状态轴和笛卡尔组合数。
- H01 是当前唯一具有 `runtimeScenePath` 的地产；H02～H08 的路径保持 null，避免把尚未接入的候选误报为运行时能力。
- `EstateMapCatalogCodec` 拒绝重复身份、非法稳定 ID、缺失核心状态轴、空/重复状态值、错误组合数、非 32px 基线和候选目录场景路径。
- `test_estate_map_projection.gd` 逐图核对正式投影与原交接包，防止手工投影漂移。

## 正式运行时结构

```text
AppCompositionRoot
├── GameCatalog（G2 历史技术目录）
└── EstateMapCatalog（八地产候选契约）
    └── H01 runtimeScenePath
        └── P2EstatePilot
            ├── H01EstateMapRuntime
            ├── P1PlayerController
            ├── Camera2D
            └── 工程 HUD
```

`EstateMapRuntime` 是地图与玩法之间的统一 seam，公开稳定 map ID、世界边界、当前状态、强类型状态切换、命名锚点查询和格语义查询。`EstateAnchorResult` 明确区分已找到、未找到和被状态关闭；`EstateCellSemantics` 明确区分越界与地图内格，避免依赖候选节点组名或 Godot TileSet source ID。

`AppCompositionRoot` 从已验证目录取得 H01 `runtimeScenePath`，实例化正式地图并注入 `P2EstatePilot`；玩法层不再直接创建 `GodotInputService`，而是由 composition root 选择并注入平台 adapter。目录为空、H01 定义缺失、运行场景缺失或类型不匹配时，启动入口不会绕过验证继续运行。

`EstateMapState` 保留季节、发展、异常三个核心字段，同时携带强类型 map-specific axis 字典，避免 H02 的水文/桥梁等额外轴在接入时迫使公共 runtime seam 改签名。H01 会明确拒绝自己不支持的额外轴。

H01 正式实现位于：

- `scenes/world/estate/h01_open_meadow.tscn`
- `scripts/gameplay/world/estate/h01_estate_map_runtime.gd`
- `maps/runtime/estate/h01/`
- `assets/art/maps/estate/h01/`

正式场景不依赖 `maps/candidates/`、候选项目的 `res://runtime`、`res://tilesets` 或泄漏的 `h03_*` 组名。H01 安全出生点为 cell `(63, 31)`、world `(2032, 1008)`、面向下；Camera2D 边界为 `0,0 → 4096,3072`。

## 可玩入口

运行默认 `res://scenes/Main.tscn`，选择“进入 H01 地产地图工程先导”。`p2_estate_pilot.tscn` 是由 application 层注入地图与输入 adapter 的可组合场景，不作为无装配直接运行入口。

- WASD / 方向键：移动。
- E / Enter / 手柄 A：查询面前目标格。
- F / Space / 手柄 X：循环正常、轻度和中度异常预览。
- R / 手柄 Y：回到安全出生点。
- F3 / 手柄 Back：显示调试信息。
- M / 右肩键：切换减弱镜头运动。

这只是工程入口，不是最终玩家 UI。

## 资源、来源与 Git 边界

H01 正式 payload 为 1,427,275 bytes；最大文件 742,127 bytes。本轮 14 张正式 PNG 与 `h01-runtime-staging-v2` 对应候选逐一 SHA-256 相同，全部来自已登记的项目内确定性 native-32px 管线，没有新增第三方或来源不明像素。

正式 `.tres` 和 `.tscn` 是对候选的派生接入：资源路径改为正式 `res://assets` / `res://maps/runtime`，控制脚本改为正式强类型 runtime，候选依赖和错误组名已移除。当前资源仍为 `shippingApproval=false`，复垦、扩建和成熟阶段含技术占位，不可据此宣称正式美术完成。

本基线只提交：

- 正式 H01 小型运行 payload；
- 八图文本交接包；
- H01 最小权威 TMX/TSX/PNG 来源和可重复构建记录；
- `maps/candidates/.gdignore`。

不提交 300+ MiB 的全部候选树、预览、日志、导入缓存、嵌套 `project.godot` 或派生检查图。本轮文件均小于 Git LFS 门槛；后续批量接入其余七图前必须单独确定 LFS 策略。

## 自动验证

- `test_estate_map_catalog.gd`：目录解码、身份、状态轴、组合数和正式路径护栏。
- `test_estate_map_projection.gd`：八图正式投影与交接包一致性。
- `test_h01_estate_map_runtime.gd`：场景加载、状态切换、锚点、格语义和候选依赖隔离。
- `test_h01_estate_pilot.gd`：正式地图、玩家、移动、真实阻挡格撞墙、出生点、Camera2D、状态转发和减弱运动。
- `test_p2_main_entry.gd`：默认 Main 到 H01 工程先导的真实场景切换。
- G0～G2 和 P1 全部既有测试继续回归。

Compatibility Renderer 实际使用 Intel Iris Xe / OpenGL 3.3 启动并自动捕获 `builds/verification/h01_estate_pilot.png`。截图位于 D 盘被 Git 忽略目录；工程任务已检查角色、地图、HUD、出生点画面和 1280×720 的 2× 输出。

## 下一步

1. 把 H01 的可耕、可建造、水域/可钓和碰撞语义统一为领域可消费的地图查询，不让农田状态依赖 TileMap 节点。
2. 在不改存档 Schema 的前提下完成一条内存态耕作闭环，再设计需要持久化的最小状态。
3. 将 H01 portal 保持为“契约对象”，直到正式地图路由和返回点验证完成。
4. 按同一 runtime seam 接入第二张结构差异足够大的地产，优先验证 H03 的两阶段适配或 H02 的多轴过渡成本；这一步会作为重大产品/兼容性选择单独决策。
