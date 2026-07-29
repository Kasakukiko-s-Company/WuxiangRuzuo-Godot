# Godot 技术规格

## 已实现（G0～G2 技术底座及当前 P1/P2 切片）

- Godot 4.7.1 stable、GDScript、Compatibility Renderer。
- 640×360 viewport，`canvas_items` + `keep` 横屏拉伸。
- `Main.tscn`、真实数据 composition root、G1 回归和 G2 headless 领域测试。
- D 盘 self-contained `editor_data` 与项目内 `.godot` 缓存策略。
- 七份版本化 JSON、强类型 `GameCatalog` 和原子交叉引用验证，含 15 名 NPC 稳定身份。
- 不依赖 Node 的 `InventoryState`、八格快捷栏事务和 `FarmState`。
- `SaveSnapshot.schemaVersion=2`、v1/v2 `SaveCodec` 往返/损坏校验、H01 强类型会话聚合、三档键空间、当前/受保护检查点和 D 盘开发期原子文件 adapter；不兼容旧 Cocos `saveVersion`。
- 平台能力 abstract contracts；运行环境与发行渠道分开。
- P1 的 CharacterBody2D/碰撞/Camera2D/语义输入，以及 P2 H01 生活闭环、统一资源/交换物资箱、数据驱动轻量交换、代表性 UI/视听反馈和本地自动保存/恢复。

## 未实现/制作方向

- P2：统一物资箱已消除“满背包无法先交易”的软锁，确定性节奏探针已锁定当前数值计算；仍需玩家节奏验证、经济参数校准和存档选择/管理 UI，当前技术切片不等于 P2 完成。
- P3/P4：人物关系与内容管线、探索/调查，以及确定要实现的战斗形态、AI、成长和失败恢复验证。
- P5～P8：可重复内容管线、完整流程、正式内容/资源、平衡、可访问性和性能。
- P9：Windows/Steam 发行链路；Web/微信通过独立可行性闸门决定。

## 代码规则

纯领域模块不继承 Node；参数/返回值强类型；错误通过显式结果或受控 assertion 表达。Node 只桥接生命周期、输入、物理、表现和场景。复杂规则有注释与测试。资源加载通过语义 manifest，不把 `.godot/imported`、UID 或具体平台路径写进玩法。

## 坐标和地图

权威领域格坐标统一为 `Vector2i`，原点/轴向由地图 adapter 明确转换。地图表现层候选为 Ground、Ground_Detail、Water、Path、Objects_Back、Characters、Objects_Front、Effects。碰撞、可耕、出生、出口和触发器必须从可验证数据生成。P1 先以代表灰盒验证 seam；正式地图数量和结构由完整世界设计决定。

## 视觉预算

所有粒子、动态灯、Shader 和后处理可按档位关闭。低档必须用 Sprite/静态覆盖/轮廓/文本表达全部功能。避免每 Tile/树独立材质和多实时灯。

## 数据与存档

目录 JSON、交换 offer JSON 与存档均有各自的 `schemaVersion`，版本生命周期分开。目录跨引用由对应 validator 校验。`SaveCodec` 不读取 Cocos localStorage 或文件系统；`GameSaveModule` 负责 profile/current/protected 语义，`AtomicFileSaveAdapter` 只处理不透明载荷和同目录临时文件替换。开发期文件固定在 D 盘项目 `builds/save-dev/`，发行期 Windows、Steam 与 Web/微信路径仍通过 `SaveService` adapter 分离。显式旧档导入器只在确有玩家数据迁移需求时实现。
