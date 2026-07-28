# P2 H01 生活闭环切片

## 结论

2026-07-28 已在 H01 正式地产运行时上把首个农作闭环推进为可玩的日常生活闭环：

`前往北草甸获得种子 → 耕地 → 播种 → 浇水 → 回家二次确认休息 → 跨日成长 → 成熟 → 收获入包`

它验证了资源获得、农作事务、正式休息点与 Godot 场景桥接，但当前 session 和每日资源领取记录只在运行内存中存在。退出场景或关闭游戏后状态会丢失；本轮没有修改 `SaveSnapshot`、`SaveCodec` 或存档 schema，也没有宣称 P2 已完成。

## 可玩入口与操作

从 `res://scenes/Main.tscn` 点击“进入 H01 地产农作闭环”，或直接通过 application composition root 装配 `res://scenes/vertical_slices/p2_estate_pilot.tscn`。

| 操作 | 键盘 | 手柄 |
| --- | --- | --- |
| 移动 | WASD / 方向键 | 左摇杆 |
| 采集、收获、查询或在家门休息 | E / Enter | A |
| 使用当前快捷栏物品 | F / Space | X |
| 异常状态预览 | V | B |
| 选择快捷栏 | 1～8；Q/Tab 前后切换 | 左/右肩键 |
| 快速选择并使用浇水壶 | G | 暂无默认键 |
| 回安全出生点 | R | Y |
| 调试信息 | F3 | Back |

初始背包固定为八格，只含锄头×1、浇水壶×1。领域来源 `home.h01.resource.north_meadow` 绑定 H01 北草甸地图锚点 `resource_north_meadow`，当前提供每日一次的雾叶草种子×3；背包满时事务失败且不会消耗当日来源。它是 P2 的代表性资源来源，不是正式开局经济、商店或最终采集平衡。

## 领域规则

- `FarmingTransactionState` 组合农田与背包，所有播种和收获事务要么完整成功，要么保持原输入对象。
- `FarmingSessionState` 增加从 1 开始的权威世界日；权威字段只读，公开场景查询返回 session snapshot。
- `DailyResourceSourceCatalog` 原子验证全局唯一来源 ID、所属地图、地图锚点、物品和数量；领取命令只携带来源 ID/世界日，调用方不能临时伪造奖励。
- `DailyResourceClaims` 只记录稳定来源 ID 最近成功领取的世界日；`DailyResourceGathering` 同时更新背包和领取记录，重复领取、日期回退、错误地图与背包满均保持原状态。
- `DailyRestPointCatalog` 验证全局唯一休息点 ID、所属地图和地图锚点；`DailyRestCycle` 只接受目录中存在且属于当前地图的休息点，再委托 `FarmDayCycle` 原子结算。场景不能直接做 `world_day += 1`。
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

- `P2EstatePilot` 只持有当前 in-memory session 与每日领取记录、每个物理帧采样一次语义输入、查询 H01 格/锚点语义并刷新视图。P2 中的 Player 明确进入 external-snapshot 模式并关闭自身物理采样，避免父子双重驱动和速度被清零。
- `resource_north_meadow` 仍是地图提供的资源生成区域数据包络；Area2D 物理监测关闭不等于其语义数据不可查询。玩法用强类型来源定义把领域 ID 投影到锚点和中心位置，不读取候选路径或 TMX 对象序号。
- `home_door` 是当前正式日终交互点：第一次交互只显示确认，第二次才结算当天；移动、重置或与其他目标交互会取消确认。旧 `N` 原型动作不再推进 P2 日历。
- `EstateDailyInteractionOverlay` 只绘制可替换的资源箱、家门提示和领取/确认状态；休息成功使用可关闭的短淡出，不拥有领域状态。
- `FarmPlotOverlay` 使用程序化绘制表现耕地、当日湿土和 0～3 阶段作物；它不是状态源，也不是正式资源。
- Main 只从 `AppCompositionRoot` 注入通过校验的 `GameCatalog`、H01 runtime 与 `InputService`。
- HUD 始终显示世界日、八格快捷栏和“不写存档”，避免把原型状态误认为已持久化。
- 播种季节和 HUD 季节均来自当前 `EstateMapState.season`，不再硬编码春季；它仍是地产状态轴，不冒充完整历法。

## 自动验证

Godot `4.7.1.stable`：

- headless editor/import/parse：exit 0。
- 25 个 G1、G2、P1、地图和 P2 测试文件：全部 exit 0。
- 新增领域测试：
  - `tests/p2/test_crop_planting.gd`
  - `tests/p2/test_crop_day_cycle.gd`
  - `tests/p2/test_crop_harvesting.gd`
  - `tests/p2/test_daily_resource_gathering.gd`
  - `tests/p2/test_daily_rest_cycle.gd`
- 新增场景闭环测试：`tests/p2/test_h01_farming_loop.gd`。
- 真实输入路由：`tests/p2/test_h01_input_route.gd` 把物理 E/F/N 键事件送入 InputMap，经 `GodotInputService` 到 P2 场景，验证资源领取、休息确认、正式跨日、耕地和 N 不再跨日。
- Compatibility Renderer：Intel Iris Xe / OpenGL 3.3，实际生成并检查三张 1280×720 截图：
  - `builds/verification/p2_h01_resource_source.png`
  - `builds/verification/p2_h01_rest_confirmation.png`
  - `builds/verification/p2_h01_farming_loop.png`
- 截图和运行日志位于 D 盘 Git 忽略目录，不进入提交。

## 本轮明确不做

- 文件存档、三档位、原子写入、恢复点或旧档导入。
- 室内床铺场景、完整过夜演出、体力、水量、经济、商店或多类资源生态。
- 多作物平衡、季节死亡、肥料、工具升级、机器加工或建造。
- 正式作物/工具动画、UI 美术、音乐、环境音和音效。
- H02～H08 批量运行时接入、正式世界路由、NPC、剧情或战斗。

## P2 剩余出口

下一批应先设计 application session 与 Windows `SaveService` 的原子存档边界；这会涉及不可逆 schema 兼容选择，实施前单独形成可测试的快照和迁移方案。P2 还需要代表性反馈音/动作、资源与作物成本基线、至少一项有意义的玩家选择，以及实际保存恢复后才能验收。
