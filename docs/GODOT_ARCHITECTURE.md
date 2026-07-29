# Godot 架构基线

## 当前事实（G2 技术底座 + P1 体验原型 + P2 生活闭环切片）

项目有可启动 `Main.tscn`、按入口隔离的真实目录装配、强类型 `GameCatalog`、`InventoryState`、`FarmState`、Godot `SaveSnapshot`/`SaveCodec` 与五类平台契约。无类型 JSON 和 `FileAccess` 只存在于 application 数据加载边界、codec 或具体 persistence adapter，不进入 domain/gameplay；领域状态不继承 Node。P1 新增 `MovementIntent`、`TileCoordinateMapper`、`P1PlayerController` 与 `GodotInputService`。P2 地产地图工程先导新增强类型 `EstateMapCatalog`、统一 `EstateMapRuntime` 查询 seam、H01 正式场景、真实 TileMapLayer 碰撞、Camera2D 与主入口。当前 H01 已接入纯领域农作事务、统一资源/交换物资箱、家门二次确认休息、八格快捷栏、跨天成长、程序化状态投影，以及 profile-1 的 D 盘原子自动保存/恢复和受保护恢复点。H01 美术资源仍为 `shippingApproval=false`；项目仍没有档位选择 UI、正式世界路由、NPC 日程/关系事件、战斗切片或最终 UI。

## 目录与依赖方向

```text
scenes / scripts/gameplay / scripts/ui
                 |
                 v
          scripts/app (composition)
             /            \
            v              v
 scripts/domain      capability contracts
                         ^
                         |
 scripts/platform / scripts/persistence
```

- `domain` 不依赖 Node、SceneTree、Input、FileAccess、平台全局或渲染资源。
- `gameplay` 把 Godot 输入/碰撞/TileMapLayer 结果转换为领域命令，并投影领域状态。
- `platform` 提供环境/渠道、输入、音频、分析与生命周期 adapter。
- `persistence` 提供 SaveService adapter、原子文件写入、schema codec 与显式旧档导入。
- `app` 是唯一装配入口；release 构建不得静默使用内存存档。

## 深模块状态

| 目标模块 | 形态 | 职责 |
| --- | --- | --- |
| `GameCatalogCodec` | 已实现 G2 | 七份目录文档的原子强类型解码与交叉校验 |
| `FarmState` | 已实现 G2 | 农田权威状态与开垦格事务；地图可耕查询后续接入 |
| `InventoryState` | 已实现 G2 | 堆叠、容量、增减与八格快捷栏事务 |
| `CropPlanting` | 已实现 P2 切片 | 校验地图/日期/季节/种子并原子更新农田与背包 |
| `FarmWatering` | 已实现 P2 切片 | 按权威世界日浇水并保持同日幂等 |
| `CropGrowth` | 已实现 P2 切片 | 浇水条件、连续跨天成长、阶段与成熟推导 |
| `CropHarvesting` | 已实现 P2 切片 | 成熟检查、背包容量与原子收获 |
| `FarmDayCycle` | 已实现 P2 切片 | 严格按连续世界日结算全部作物 |
| `DailyResourceSourceCatalog` | 已实现 P2 切片 | 原子验证来源 ID、选择组、地图/锚点、物品和数量 |
| `DailyResourceGathering` | 已实现 P2 切片 | 按稳定来源 ID 执行奖励，按来源或互斥组领取键记录世界日 |
| `DailyRestPointCatalog` | 已实现 P2 切片 | 原子验证休息点 ID、地图与锚点 |
| `DailyRestCycle` | 已实现 P2 切片 | 通过地图/休息点/完成日命令触发日终结算 |
| `TradeOfferCatalog` | 已实现 P2 切片 | 解码并索引受验证的稳定端点与交换项目 |
| `TradeBook` | 已实现 P2 切片 | 对不可变背包执行原子交换；失败返回原状态 |
| `NorthMeadowCrateFlow` | 已实现 P2 切片 | 合并 H01 每日资源/交换行动、可执行性预检、瞬时选择与领域结果翻译 |
| `AppEntryStatus` / `AppCatalogSource` | 已实现入口隔离 | 以生产/测试 adapter 加载目录，并让局部 H01 故障只阻断 H01 入口 |
| `SaveCodec` | 已实现 v2 | Godot schema v1/v2 的编码/解码/完整快照校验；不负责存储或档位策略 |
| `GameSaveModule` | 已实现 P2 切片 | 固定 profile 的 current/protected 选择、H01 强类型聚合和损坏隔离 |
| `AtomicFileSaveAdapter` | 已实现开发期 Windows adapter | 同目录 `.tmp` 写入、`.rollback` 提交保护、`.bak` 崩溃回退和不透明载荷读写；路径由 composition root 注入 |
| `CocosSaveImporter` | 独立迁移器 | 显式读取旧 v1 payload；不污染正常 codec |
| `RelationshipLedger` | 领域服务 | 全员好感、多 dating、唯一配偶、年龄边界 |

## 平台能力

G2 已建立抽象 `PlatformService`、`SaveService`、`InputService`、`AudioService`、`AnalyticsService` 和显式结果类型。运行环境：`windows-native`、`web`；发行渠道：`standalone`、`steam`、`wechat`。Steam 只允许 Windows，微信只允许 Web；微信能力只能通过独立可行性闸门决定。

当前已实现 `GodotInputService`、P2 `GodotAudioService` 和开发期 `AtomicFileSaveAdapter`。音频 adapter 从版本化 `data/audio_catalog.json` 解析稳定 ID，拥有独立音乐播放器与 SFX 播放器池；`P2EstatePilot` 只调用 `AudioService.play_music/play_sound`，不依赖 ElevenLabs、文件路径或平台音频 API。保存 adapter 只处理 opaque payload；H01 玩法不接触 JSON、档位名或路径。发行期 Windows、Steam、Web/微信和分析 adapter 仍未实现。

## 场景与状态

场景 Node 只拥有生命周期、信号、物理运动、碰撞、视觉与场景引用。领域状态不以节点树作为唯一事实源；跨场景状态由受控 session/application 层持有并通过 codec 保存。避免把所有状态堆入单一 Autoload。

## 地图 seam

地图定义提供稳定 map ID、场景路径、命名锚点、入口、功能层和安全回退。地图坐标转换集中在单一 adapter；领域瓦片坐标不得依赖 TMX 行号、Godot cell source ID 或世界像素。`EstateMapCatalog` 保存八地产候选契约，但只有已正式接入的 H01 具有运行场景路径；候选数量不等于最终玩家地产数量。正式世界可以包含任意经产品设计确认的区域数量，不受 G2 四图 fixture 限制。

P1 的实际坐标约定为左上原点、Y 向下、32×32 基础格；`TileCoordinateMapper` 负责 world/cell/cell-center/facing-cell 转换。`prototype_mist_edge` 只是 40×28 的验证场，不登记进正式 `world.json`。

P2 的 `EstateMapRuntime` 公开 map ID、世界边界、当前状态、强类型状态切换、命名锚点和格语义查询。`EstateMapState` 的三个核心字段之外还可携带强类型 map-specific axes，使水文、桥梁、灌溉等地产专属状态无需修改公共方法签名；具体 runtime 必须验证自己支持的轴。H01 的正式实现不让玩法读取候选组名、TMX 对象序号或 TileSet source ID；未知锚点与状态关闭锚点是不同结果。`runtime_disabled_semantic_area` 对资源生成区表示 Area2D 物理监测关闭，资源系统仍可按稳定 ID 查询其数据包络；portal/trigger 的业务关闭仍返回显式 disabled。H01 状态切换已经进入 schema v2 存档，但仍只允许在工程预览和安全过渡边界使用，尚未绑定完整历法或正式地图过渡流程。

`AppCompositionRoot.bootstrap()` 分别发布 P1 与 H01 的 `AppEntryStatus`；游戏、地产、交易或 H01 场景故障不会扩大成 P1 全局故障。`create_h01_launch(profile_id)` 仍要求 H01 入口可用，再根据 `runtimeScenePath` 实例化正式地图，创建输入/音频/存储 adapter，读取 current/protected，并在节点进入树前安装强类型 `P2PersistentState`。玩法场景不直接构造平台 adapter，也不能在目录、场景或档位验证失败时绕过 composition root 启动。

## P2 农作状态 seam

- `FarmingTransactionState` 把 `FarmState` 与 `InventoryState` 作为一次原子领域事务的输入/输出；`FarmingSessionState` 只再增加权威 `world_day`。这些权威引用为只读属性，外部场景查询取得 snapshot。
- `CropPlanting`、`FarmWatering`、`FarmDayCycle` 与 `CropHarvesting` 使用各自命令和结果类型，不让场景节点直接改作物字段。
- `DailyResourceSourceCatalog` 先验证来源 ID 到地图、锚点、物品和数量的唯一映射；同一每日选择组的来源必须共享地图和锚点，组 ID 不得与来源 ID 冲突。`DailyResourceClaims` 与 `DailyResourceGathering` 再以来源 ID 或共享组 ID 作为稳定领取键，把“每个领取键每天最多成功一次”放在纯领域层。背包满、日期回退或伪造来源时领取记录不前移。
- `DailyRestPointCatalog` 验证休息点的地图归属与锚点；`DailyRestCycle` 只接收目录 ID 与待完成世界日。场景的二次确认只负责发出命令，不能直接递增日期。
- `TradeOfferCatalog` 独立于场景验证 offer、endpoint、物品引用与数量；`TradeBook` 只暴露 `offers(endpoint_id)` 和 `execute(inventory, command)`。`NorthMeadowCrateFlow` 把每日资源与交换编排为四项 H01 行动牌组，以不可变 dry-run 决定 enabled/blocked 和默认选择；成功领取才更新 claim，交易从不修改 claim。H01 Node 不临时改价格或直接修改背包。
- `village_scrip` 作为普通 material 进入既有背包/存档 seam，不建立尚未通过产品验证的全局钱包。未来若改变为通用货币，必须显式迁移 schema 和语义。
- `FarmDayAdvanceCommand` 携带明确 `completed_day`，使已处理命令幂等、未来命令拒绝，并让整批作物在预检通过后才统一结算。
- `FarmState.restore()` 验证农田自身结构、作物引用、阶段派生与种植/结算日关系；世界地图 ID 是否存在由 codec/application 使用相应世界目录校验，避免领域层继续绑定退役的四地图 fixture。
- `P2EstatePilot.apply_input_snapshot()` 是语义输入转发 seam；实际 `_physics_process` 每帧只从注入的 `InputService` 采样一次，再把同一快照转发给玩家和农作桥接。P2 的 Player 明确启用 external-snapshot mode 并关闭自身 physics callback，避免双重物理所有权；独立 P1 场景仍由 Player 自己采样。
- `FarmPlotOverlay` 只投影农田；`EstateDailyInteractionOverlay` 只消费 `NorthMeadowCratePresentation` 与休息确认，不再拥有两套资源/交换 pending 状态。当前画面是可替换的程序化占位，不构成正式美术批准。
- 当前季节读取 `EstateMapRuntime.get_current_state().season`，同时驱动播种校验和 HUD；完整历法仍未实现。
- `P2EstatePilot` 在空档时创建 session，在恢复档时安装 application 层提供的 `P2PersistentState`。成功耕地、播种、浇水、收获、资源领取、交换、地产状态变更和日终休息发送 durable commit signal；离开场景还捕获最后位置。节点不知道保存格式或路径。

## P1 场景 seam

- `MovementIntent` 是纯 `RefCounted`，只把语义输入解析为归一化方向和四方向面向。
- `P1PlayerController` 是 `CharacterBody2D` 桥接层，负责物理帧、`move_and_slide` 与交互信号，不读取物理键。
- `GodotInputService` 是当前 Godot adapter，把键盘/手柄映射为 `InputSnapshot`；玩法场景只依赖语义快照。
- `P1ExperienceProbe` 负责场景装配、重置、交互显示、画质/减弱镜头开关和调试状态；程序化地形、玩家、前景和音频均可整体替换。

## 存档 seam

`SaveCodec` 只处理领域快照；`SaveService` 契约只处理不透明 payload。`P2PersistentState` 聚合 H01 farming session、玩家位置/朝向/生命、地产状态和每日领取记录。`GameSaveModule` 为一个固定 profile 决定 current/protected 的加载与保存；`P2PersistenceBinding` 把场景 durable signal 接到 module；`AppCompositionRoot` 隐藏场景、目录和具体存储装配。

开发期 Windows adapter 使用项目内 D 盘 `builds/save-dev/`，以同目录 `.tmp` 写入并 flush；旧目标先进入 `.rollback`，新目标提交成功后才把 rollback 晋升为 `.bak`。pre-promote 中断时 adapter 把较新的 rollback 暴露为 primary、旧 bak 暴露为 previous；post-promote 中断则把新 target 暴露为 primary、rollback 暴露为 previous。module 先验证 current primary；它无效时，再验证 current previous、protected primary 和 protected previous，并按世界日、保存时间与稳定来源优先级选择最新 fallback。无效载荷写入 quarantine，隔离失败则由 module 锁定只读恢复。普通动作只更新 current，成功休息同时更新 protected。没有有效候选时启动被阻止，原载荷不被覆盖。发行期 Windows user data、Web/微信和 Steam adapter 不改变领域 schema。

## 质量与测试

- 纯领域模块使用 headless GDScript 单元/场景测试。
- 场景垂直切片用可启动 `.tscn` 验证输入、碰撞、摄像机与坐标。
- JSON decoder 必须拒绝未知 ID、重复 ID、越界值和破损交叉引用。
- 每阶段同时运行上一阶段测试，避免回归。
