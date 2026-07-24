# P2 H01 农作闭环切片

## 结论

2026-07-24 已在 H01 正式地产运行时上实现首个可玩的农作闭环：

`选择锄头 → 耕地 → 选择种子 → 播种 → 选择浇水壶 → 浇水 → 过夜成长 → 成熟 → 收获入包`

它验证了核心领域事务与 Godot 场景桥接，但当前 session 只在运行内存中存在。退出场景或关闭游戏后状态会丢失；本轮没有修改 `SaveSnapshot`、`SaveCodec` 或存档 schema，也没有宣称 P2 已完成。

## 可玩入口与操作

从 `res://scenes/Main.tscn` 点击“进入 H01 地产农作闭环”，或直接通过 application composition root 装配 `res://scenes/vertical_slices/p2_estate_pilot.tscn`。

| 操作 | 键盘 | 手柄 |
| --- | --- | --- |
| 移动 | WASD / 方向键 | 左摇杆 |
| 收获或查询目标格 | E / Enter | A |
| 使用当前快捷栏物品 | F / Space | X |
| 异常状态预览 | V | B |
| 推进一天（原型） | N | 暂无默认键 |
| 选择快捷栏 | 1～8；Q/Tab 前后切换 | 左/右肩键 |
| 快速选择并使用浇水壶 | G | 暂无默认键 |
| 回安全出生点 | R | Y |
| 调试信息 | F3 | Back |

原型初始背包固定为八格：锄头×1、浇水壶×1、雾叶草种子×3，其余为空。它用于验证循环成本，不是正式开局经济。

## 领域规则

- `FarmingTransactionState` 组合农田与背包，所有播种和收获事务要么完整成功，要么保持原输入对象。
- `FarmingSessionState` 增加从 1 开始的权威世界日；权威字段只读，公开场景查询返回 session snapshot。
- `FarmDayAdvanceCommand.completed_day` 明确要结算的日子：已处理的旧日命令返回 `ALREADY_APPLIED` 且保持状态，未来日返回 `DAY_GAP`，只有当前日能推进。
- 只有 H01 runtime 判定 `farmable && !colliding` 的目标格可开垦；玩法不读取 TileSet source ID 或候选 staging 名称。
- 播种校验已耕地、空格、种子目录、季节和背包数量；成功恰好消耗一粒种子。
- 同日重复浇水幂等；需水作物在干燥日结算但不成长，不能在未来补浇后回填成长。
- 每株作物必须按连续世界日结算，跳日会以 `DAY_GAP` 拒绝整个批次；同批一株异常时不会留下其他作物的部分结算。
- 当前雾叶草的三个成长阶段各需一个已浇水日；第 4 天进入成熟阶段。
- 收获先验证背包能完整容纳产物，再移除作物；背包满时成熟作物保留。
- `FarmState.tile_at()` 与 `InventoryState.stack_at()` 返回防御性副本，场景层不能绕过事务修改权威状态。
- `FarmState.restore()` 验证自身结构、作物目录、阶段派生和种植/结算日关系，不再错误依赖旧四地图目录；地图 ID 的世界目录校验留在 `SaveCodec`/application 边界。H01 农田状态已能在不修改存档 schema 的情况下完成领域往返。

## Godot 场景桥接

- `P2EstatePilot` 只持有当前 in-memory session、每个物理帧采样一次语义输入、查询 H01 格语义并刷新视图。P2 中的 Player 明确进入 external-snapshot 模式并关闭自身物理采样，避免父子双重驱动和速度被清零。
- `FarmPlotOverlay` 使用程序化绘制表现耕地、当日湿土和 0～3 阶段作物；它不是状态源，也不是正式资源。
- Main 只从 `AppCompositionRoot` 注入通过校验的 `GameCatalog`、H01 runtime 与 `InputService`。
- HUD 始终显示世界日、八格快捷栏和“不写存档”，避免把原型状态误认为已持久化。
- 播种季节和 HUD 季节均来自当前 `EstateMapState.season`，不再硬编码春季；它仍是地产状态轴，不冒充完整历法。

## 自动验证

Godot `4.7.1.stable`：

- headless editor/import/parse：exit 0。
- 23 个 G1、G2、P1、地图和 P2 测试文件：全部 exit 0。
- 新增领域测试：
  - `tests/p2/test_crop_planting.gd`
  - `tests/p2/test_crop_day_cycle.gd`
  - `tests/p2/test_crop_harvesting.gd`
- 新增场景闭环测试：`tests/p2/test_h01_farming_loop.gd`。
- 新增真实输入路由：`tests/p2/test_h01_input_route.gd` 把物理 F 键事件送入 InputMap，经 `GodotInputService` 到 P2 场景并验证实际耕地。
- Compatibility Renderer：Intel Iris Xe / OpenGL 3.3，实际生成 1280×720 截图 `builds/verification/p2_h01_farming_loop.png`。
- 截图和运行日志位于 D 盘 Git 忽略目录，不进入提交。

## 本轮明确不做

- 文件存档、三档位、原子写入、恢复点或旧档导入。
- 正式睡觉位置、过夜演出、体力、水量、经济、商店或资源获取。
- 多作物平衡、季节死亡、肥料、工具升级、机器加工或建造。
- 正式作物/工具动画、UI 美术、音乐、环境音和音效。
- H02～H08 批量运行时接入、正式世界路由、NPC、剧情或战斗。

## P2 剩余出口

下一批应在不扩大存档 schema 的前提下先补代表性的资源获得与睡眠交互，再单独设计 application session 和 Windows `SaveService` 原子存档。存档字段与兼容策略属于重大 seam，实施前要先形成可测试的快照边界；P2 只有在保存恢复、必要 UI/视听、玩家选择和成本基线都成立后才能验收。
