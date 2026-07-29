# P2 H01 生活闭环切片

## 结论

2026-07-28 已在 H01 正式地产运行时上把首个农作闭环推进为可玩的日常生活闭环：

`前往北草甸选择当日资源 → 选择种子时耕地 → 播种 → 浇水 → 回家二次确认休息 → 跨日成长 → 成熟 → 收获入包 → 卖出雾叶 → 回购种子`

它验证了互斥资源选择、资源获得、农作事务、正式休息点、轻量交换、Godot 场景桥接和本地保存恢复。Main 选择的档位会在成功的持久状态变更和离开场景时更新 current 检查点，成功休息还更新 protected 恢复点；重进 H01 可恢复日期、玩家位置/朝向、农田、湿土/作物、背包/快捷栏、地产状态和每日领取记录。会话内 Esc/Start 可暂停、恢复或经二次确认安全返回标题；可写会话只有在显式退出保存成功后才导航，写入失败会保持暂停并允许重试；只读恢复则明确保留损坏证据而不承诺保存。HUD 还会从当前 session、领取记录和目录实时推导一个可执行的下一目标，或在异常恢复状态下诚实报告阻塞原因；它不是任务进度，也不进入存档。该技术切片仍不代表 P2 完成。

## 可玩入口与操作

从 `res://scenes/Main.tscn` 选择一个档位后点击“进入 H01 地产农作闭环”。正式入口调用 `AppCompositionRoot.create_h01_launch(selected_profile_id)`，不应绕过 application 层直接运行持久会话场景。

| 操作 | 键盘 | 手柄 |
| --- | --- | --- |
| 移动 | WASD / 方向键 | 左摇杆 |
| 打开/确认资源选择、收获、查询或在家门休息 | E / Enter | A |
| 使用当前快捷栏物品 | F / Space | X |
| 异常状态预览 | V | B |
| 选择快捷栏 | 1～8；平时用 Q/Tab 前后切换 | 左/右肩键 |
| 切换北草甸资源候选 | 资源选择打开时用 Q/Tab | 左/右肩键 |
| 切换北草甸交换项目 | 当日资源领取后打开交换，再用 Q/Tab | 左/右肩键 |
| 快速选择并使用浇水壶 | G | 暂无默认键 |
| 回安全出生点 | R | Y |
| 暂停/恢复；确认页中先取消危险操作 | Esc | Start |
| 调试信息 | F3 | Back |

初始背包固定为八格，只含锄头×1、浇水壶×1。H01 北草甸地图锚点 `resource_north_meadow` 绑定一个每日资源选择组，当前候选为“雾叶草种子×3”和“雾叶×1”。第一次交互只打开选择，Q/Tab 或手柄肩键切换，第二次交互确认；移动、使用物品、重置或与其他目标交互会取消待确认状态。背包无法容纳所选奖励时事务失败、选择资格保留，玩家可以切换另一项。

HUD 中的“预计收获价值 90”和“即时目录价值 30”由当前作物/物品目录计算。当前雾叶可以在当日资源领取后的北草甸物资箱兑换村社券，并用村社券回购种子；数值因此已经可兑现，但每日免费资源仍会显著影响稀缺性，尚不足以证明经济平衡已经成立。

## 领域规则

- `FarmingTransactionState` 组合农田与背包，所有播种和收获事务要么完整成功，要么保持原输入对象。
- `FarmingSessionState` 增加从 1 开始的权威世界日；权威字段只读，公开场景查询返回 session snapshot。
- `DailyResourceSourceCatalog` 原子验证全局唯一来源 ID、所属地图、地图锚点、物品和数量；同一选择组还必须共享地图和锚点，组 ID 不得与普通来源 ID 冲突。领取命令只携带来源 ID/世界日，调用方不能临时伪造奖励。
- `DailyResourceClaims` 记录稳定领取键最近成功领取的世界日；普通来源以来源 ID 为键，互斥候选共享选择组 ID。`DailyResourceGathering` 同时更新背包和领取记录，重复领取同组其他候选、日期回退、错误地图与背包满均保持原状态。
- `DailyRestPointCatalog` 验证全局唯一休息点 ID、所属地图和地图锚点；`DailyRestCycle` 只接受目录中存在且属于当前地图的休息点，再委托 `FarmDayCycle` 原子结算。场景不能直接做 `world_day += 1`。
- `FarmDayAdvanceCommand.completed_day` 明确要结算的日子：已处理的旧日命令返回 `ALREADY_APPLIED` 且保持状态，未来日返回 `DAY_GAP`，只有当前日能推进。
- 只有 H01 runtime 判定 `farmable && !colliding` 的目标格可开垦；玩法不读取 TileSet source ID 或候选 staging 名称。
- 播种校验已耕地、空格、种子目录、季节和背包数量；成功恰好消耗一粒种子。
- 同日重复浇水幂等；需水作物在干燥日结算但不成长，不能在未来补浇后回填成长。
- 每株作物必须按连续世界日结算，跳日会以 `DAY_GAP` 拒绝整个批次；同批一株异常时不会留下其他作物的部分结算。
- 当前雾叶草的三个成长阶段各需一个已浇水日；第 4 天进入成熟阶段。
- 收获先验证背包能完整容纳产物，再移除作物；背包满时成熟作物保留。
- `FarmState.tile_at()` 与 `InventoryState.stack_at()` 返回防御性副本，场景层不能绕过事务修改权威状态。
- `FarmState.restore()` 验证自身结构、作物目录、阶段派生和种植/结算日关系，不再错误依赖旧四地图目录；地图 ID 的世界/地产目录校验留在 `SaveCodec`/application 边界。
- `SaveSnapshot.schemaVersion=2` 新增 H01 `estateMapState` 与 `dailyResourceClaims`；decoder 仍能读取 Godot v1，但不伪造缺失的 H01 状态。
- `TradeOfferCatalog` 校验端点、稳定 offer ID、正数量和游戏目录物品引用；`TradeBook` 对不可变背包执行原子交换，奖励容量失败时不会留下部分扣除。
- `village_scrip` 是普通背包 material，不是已定稿的通用货币；它通过既有 inventory slots 持久化，因此本批不修改 schema v2。
- `P2PersistentState` 是场景和保存模块之间的强类型聚合；`GameSaveModule` 隔离 current/protected 语义，`SaveService` 只看到不透明字符串。

## Godot 场景桥接

- `P2EstatePilot` 持有当前 session、每日领取记录及可取消的资源/交换选择 UI 状态；每个物理帧采样一次语义输入、查询 H01 格/锚点语义并刷新视图。它只捕获/安装 `P2PersistentState` 并发送 durable commit signal，不读取 JSON、档位键或文件路径。P2 中的 Player 明确进入 external-snapshot 模式并关闭自身物理采样，避免父子双重驱动和速度被清零。
- `resource_north_meadow` 仍是地图提供的资源生成区域数据包络；Area2D 物理监测关闭不等于其语义数据不可查询。玩法用强类型来源定义把领域 ID 投影到锚点和中心位置，不读取候选路径或 TMX 对象序号。
- `home_door` 是当前正式日终交互点：第一次交互只显示确认，第二次才结算当天；移动、重置或与其他目标交互会取消确认。旧 `N` 原型动作不再推进 P2 日历。
- `EstateDailyInteractionOverlay` 只绘制可替换的资源箱、两个选择标记、当前选择环、家门提示和领取/确认状态；休息成功使用可关闭的短淡出，不拥有领域状态。
- `FarmPlotOverlay` 使用程序化绘制表现耕地、当日湿土和 0～3 阶段作物；它不是状态源，也不是正式资源。
- `P2InteractionFeedback` 只消费成功动作 ID 和目标格位置，以 Tween/自绘表现耕地、播种、浇水、收获、采集、交换和休息；减少动态效果时切换为极短静态反馈。
- `H01LifeLoopGuide` 是不依赖 Node、I/O 或存档的只读投影：它以真实领取、交易和背包事务做 dry-run，再生成强类型 `P2LifeLoopObjective`。时间敏感的浇水优先于被满背包阻塞的收获；已照料一株即可建议休息，不强迫种完全部种子；当日免费资源优先于回购，已有种子时不会持续诱导购买。缺少必要工具或无可执行领取/收获时显示明确阻塞原因，不承诺必然失败的操作。
- Main 只向 `AppCompositionRoot` 请求所选 profile 的 H01 launch；组合根注入通过校验的 `GameCatalog`、`TradeOfferCatalog`、`TradeBook`、H01 runtime、`InputService`、`AudioService`、`GameSaveModule` 和具体 `SaveService`。
- `P2PauseMenu` 只拥有会话内模态显示和语义信号；`P2EstatePilot` 负责暂停树并锁住瞬态玩法输入，`P2SessionNavigationBinding` 先向 `P2PersistenceBinding` 取得强类型退出准备结果，只有已保存或明确只读时才使用自己拥有的 Main 场景路径执行 `SceneTree.change_scene_to_file()`。写入失败保持在确认页，支持重试且不会触发场景切换。玩法节点不硬编码标题路径，也不直接决定退出时的存储位置。
- `GodotAudioService` 通过 `data/audio_catalog.json` 将稳定 ID 映射到 1 个音乐播放器和 4 个 SFX 播放器；玩法不读取音频路径。当前接入 8 个 P2 SFX 和 1 个 H01 春季日间音乐候选。
- HUD 始终显示世界日、八格快捷栏和真实保存模式。空档、当前档、受保护恢复点和存档故障不会冒充同一状态。
- 播种季节和 HUD 季节均来自当前 `EstateMapState.season`，不再硬编码春季；它仍是地产状态轴，不冒充完整历法。

## 自动验证

Godot `4.7.1.stable`：

- headless editor/import/parse：exit 0。
- 保存专项测试覆盖 v1/v2 codec、typed state bridge、current/protected 回退、三 profile 隔离、原子替换、损坏隔离和 composition root 端到端启动。最新完整测试数量与结果以 `PLANS.md` 和 `P2_SAVE_RESTORE.md` 为准。
- 新增领域测试：
  - `tests/p2/test_crop_planting.gd`
  - `tests/p2/test_crop_day_cycle.gd`
  - `tests/p2/test_crop_harvesting.gd`
  - `tests/p2/test_daily_resource_gathering.gd`
  - `tests/p2/test_daily_rest_cycle.gd`
- 新增场景闭环测试：`tests/p2/test_h01_farming_loop.gd`。
- 下一目标纯状态测试：`tests/p2/test_h01_life_loop_guide.gd` 覆盖领取、耕地、播种、浇水、休息、成熟、收获、出售、必要回购、满背包和混合作物优先级；场景闭环同步验证常驻 HUD 随真实动作更新。
- 新增音频 adapter 测试：`tests/p2/test_godot_audio_service.gd`；场景闭环同步验证 8 个稳定 SFX ID、H01 music ID 与交互动画。
- 真实输入路由：`tests/p2/test_h01_input_route.gd` 把物理 E/Q/F/N 键事件送入 InputMap，经 `GodotInputService` 到 P2 场景，验证资源选择、互斥领取、交易打开/取消/卖出/回购、次日恢复、休息确认、正式跨日、耕地和 N 不再跨日。
- 暂停与安全返回：`tests/p2/test_p2_pause_navigation.gd` 覆盖同帧 pause+move 的暂停优先级、真实 Escape/Start 跨 physics frame 恢复且不反弹重开、二次确认默认聚焦取消、返回标题前显式保存所选档位、写失败保持暂停并可重试、重进位置恢复，以及只读恢复不覆盖损坏证据。
- Compatibility Renderer：Intel Iris Xe / OpenGL 3.3，实际生成并检查八张 640×360 截图：
  - `builds/verification/p2_h01_resource_source.png`
  - `builds/verification/p2_h01_resource_choice.png`
  - `builds/verification/p2_h01_trade_choice.png`
  - `builds/verification/p2_h01_rest_confirmation.png`
  - `builds/verification/p2_h01_farming_loop.png`
  - `builds/verification/p2_h01_pause_menu.png`
  - `builds/verification/p2_h01_return_confirmation.png`
  - `builds/verification/p2_h01_return_save_failure.png`
- 截图和运行日志位于 D 盘 Git 忽略目录，不进入提交。

## 当前保存边界

- 开发期存档固定在 D 盘项目 `builds/save-dev/profile-N.json`；该目录由 `.gdignore`/`.gitignore` 隔离，不是发行路径承诺。
- `.tmp`、`.rollback`、`.bak` 与目标文件位于同一目录；现有目标先转为 `.rollback`，新目标提交成功后才更新 `.bak`。`.bak` 是物理写入保护，不等于业务上的 `profile-N.protected`。
- 普通成功动作和离开场景更新 current；成功确认休息再更新 protected。protected 写失败会报告降级，但不否认 current 已成功。
- current primary 有效时直接恢复；否则同时验证 current previous、protected primary 和 protected previous，并按世界日、保存时间与稳定来源优先级选择最新 fallback。pre-promote 的 `.rollback` 会作为 primary 暴露，不会被更旧 `.bak` 隐藏。无效载荷先隔离；无法隔离时仍可只读恢复，但不会写回。没有任何有效候选时阻止 H01 启动并保留载荷。
- `profile-1`～`profile-3` 的键空间和 codec 已隔离；Main 已提供三档选择、最近档、状态摘要和带确认的完整档位删除，H01 只绑定所选档位。

## 本轮明确不做

- 最终标题/档位视觉、设置页、发行期 Windows 路径、Steam 云、Web/微信 adapter 或旧 Cocos 档导入。
- 室内床铺场景、完整过夜演出、体力、水量、正式商店、独立钱包或多类资源生态。
- 正式通用货币、批量交易、动态价格，以及经玩家测试的选择平衡。
- 多作物平衡、季节死亡、肥料、工具升级、机器加工或建造。
- 最终发行级逐帧作物/工具动画、UI 美术、完整音乐/环境音/音效覆盖与主观混音验收。
- H02～H08 批量运行时接入、正式世界路由、NPC、剧情或战斗。

## 本地节奏证据

H01 现在通过 application 层的 `P2PacingEvidenceBinding` 观察独立的 `playtest_action_committed` 语义信号；玩法节点仍不知道 `AnalyticsService`、JSONL 或文件路径。物资箱成功结果显式返回稳定 source/offer ID，耕地、播种、浇水、休息和收获沿用稳定动作 ID；证据层只接受白名单，不从 UI 文案或背包差值猜测选择。

普通编辑器、日常调试、headless 和自动截图默认都不采集；只有显式 `--p2-pacing-human` 的知情内部试玩，或显式 `--p2-pacing-automation`/测试注入，才逐行写入 D 盘 Git 忽略目录 `builds/playtest-evidence/p2-pacing/`。记录按事件执行严格字段类型和逐值注册，不接收 profile ID、绝对路径、坐标、未注册自由文本或存档 payload；写入失败不会回滚合法玩法或 schema v2 保存事务。首次循环完成仅接受新档中的有序动作链，恢复档单独排除，并携带 build/content revision。完整契约见 `P2_PACING_EVIDENCE.md`。

当前仅可声明 `instrumentationReady=true`；`humanEvidenceCollected=false`、`designDecisionReviewed=false`。自动测试仍不能替代实际玩家节奏判断。

## P2 剩余出口

代表性反馈音与动作已经进入运行切片；当前候选仍需后续主观听感和最终混音，不冒充发行资源。本地 current/protected 保存恢复、三档技术管理、会话安全返回和首轮生活循环目标可发现性的技术缺口已经关闭；发行 adapter 与最终标题视觉仍属于后续。北草甸二选一与轻量交换已经提供可运行的延迟产出、即时物品、卖出和必要回购闭环，但每日免费资源仍会削弱稀缺性，且自动目标不能替代真实玩家节奏证据。下一批应安排实际玩家验证，再依据证据调整早期资源压力；不能仅凭当前引导和确定性测试宣布 P2 完成。完整交换边界见 `P2_LIGHTWEIGHT_ECONOMY.md`。
