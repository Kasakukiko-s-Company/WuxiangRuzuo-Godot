# P2 H01 本地保存与恢复切片

## 当前结论

2026-07-29 已为 H01 生活闭环建立可运行的 application session、Godot schema v2、开发期 Windows 原子文件 adapter、current 自动保存和 protected 安全恢复点。Main 现提供三个独立档位、最近档位、恢复/损坏状态摘要和带确认的完整删除；H01 只使用玩家选中的档位。档位目录使用独立 metadata schema v1，没有修改 `SaveSnapshot` schema v2。

这批关闭的是 P2 的“本地技术保存恢复”缺口，不表示完整游戏存档体验或 P2 整体完成。

## 依赖方向

```text
Main
  -> SaveProfileRoster (read-only summaries / recent / delete)
      -> GameSaveModule.inspect()
      -> SaveService
  -> AppCompositionRoot.create_h01_launch(selected_profile_id)
      -> GameSaveModule
          -> SaveCodec
          -> SaveService (opaque payload)
              -> AtomicFileSaveAdapter
      -> P2EstatePilot
          <-> P2PersistenceBinding
          <-> P2PersistentState
```

- `P2EstatePilot` 只捕获/安装强类型状态并发送 durable commit signal。
- `P2PersistenceBinding` 把成功动作连接到固定 profile 的 `GameSaveModule`。
- `GameSaveModule` 隐藏 current/protected、v1/v2 provenance、H01 上下文检查和损坏隔离。
- `SaveProfileRoster` 隐藏三档只读巡检、最近档 metadata 和档位命名空间删除；UI 不解析存档 JSON。
- `AtomicFileSaveAdapter` 是保存路径与不透明 save payload I/O 的唯一具体层；其他 application 目录/音频加载器仍各自在自己的边界使用文件 API。

## 快照范围

schema v2 当前保存：

- `schemaVersion`、保存时间、profile、世界日和当前地图；
- 玩家位置、四方向朝向、安全回退锚点和生命；
- H01 农田、湿土/作物、背包与快捷栏选择；
- H01 季节/发展/异常状态轴；
- 每日资源选择组最近成功领取日；
- G2 已有剧情、关系、配偶与矿洞字段（未被 H01 切片使用的字段在后续保存中保持）。

不保存 Tween、粒子、可取消资源选择、休息二次确认、调试面板或其他瞬时表现。

## 写入与恢复语义

1. 耕地、播种、浇水、收获、资源领取和地产状态变更成功后写 current。
2. 离开 H01 时再捕获玩家最后位置并写 current。
3. 成功确认休息先写 current，再写 `profile-N.protected`。
4. protected 失败时 current 仍算成功，结果明确为 recovery degraded。
5. current primary 有效时始终权威；若它无效，再同时验证 current previous、protected primary 和 protected previous，并按 `worldDay`、`savedAt`、稳定来源优先级选取最新 fallback，避免旧 `.bak` 压过较新的 protected 恢复点。
6. 四个候选都 missing 才创建新 session。
7. 使用 fallback 前，把更早的可读无效载荷复制到稳定 quarantine slot；后续自动保存不会删除这份证据。
8. 如果 quarantine 因权限、空间或已有不同证据而不能完成，仍允许从已验证 fallback 进入只读会话，不写回原档。
9. 所有候选都不可用时阻止启动，原始载荷不被覆盖。

业务恢复点与物理 `.bak` 不同：`profile-N.protected.json` 是休息边界的完整快照；`profile-N.json.bak` 只保护一次文件替换。

## 三档目录与删除语义

- `SaveProfileRoster.refresh()` 复用 `GameSaveModule.inspect()` 的候选顺序，但严格不执行 write、remove 或 quarantine；打开标题页不会改变任何档位证据。
- 档位摘要强类型区分空档、可继续、可从恢复点继续、损坏、不支持 schema、内容不兼容和存储读取失败，并携带世界日、地图、保存时间和恢复来源。
- 最近档位保存于独立逻辑键 `profile-directory`，文档为 `{"schemaVersion":1,"lastPlayedProfileId":"profile-N"}`；只在 H01 成功装配后记录。最近档损坏时仍保持选中且禁止启动，不静默跳到其他档位。
- 删除必须先显式确认。取消不写存储；确认后依次删除四个 quarantine 键、protected、最后才删除 current，并在每个逻辑键后验证 current/previous 均 missing。
- 任一步删除失败都返回 partial，不把档位谎报为空；current 最后删除，尽量保留最有价值的可玩证据。删除最近档后再清除 `profile-directory`。
- `profile-directory` 是应用元数据协议，不进入或改变 `SaveSnapshot` schema v2。

## 文件协议与 D 盘边界

开发期根目录：

`D:\lzq\AI游戏\WuxiangRuzuo-Godot\builds\save-dev`

adapter 在目标同目录写 `.tmp` 并 flush/close。替换时先把当前目标暂存为 `.rollback`，保留原 `.bak` 不动；只有 `.tmp` 成功提升为新目标后，才用 `.rollback` 更新 `.bak`。pre-promote 中断时 target 缺失，`read()` 把更新的 `.rollback` 暴露为 primary，`read_previous()` 再暴露更旧 `.bak`；post-promote 中断时 target 仍是 primary，`.rollback` 是 previous。两份不透明候选分别经过 `SaveCodec` 验证，adapter 不猜 JSON。slot ID 只接受受控小写稳定格式，拒绝路径分隔符和遍历形式，base directory 必须是绝对路径。`builds/` 不被 Godot 导入，也不进入 Git。

无效 payload 的隔离键使用 `profile-N.quarantine-primary`、`profile-N.quarantine-previous` 及 protected 对应键。固定隔离位已含不同证据时不会覆盖；该次恢复改为只读。

发行期 Windows 路径、Steam 云、Web/微信另由 `SaveService` adapter 决定，不改变 schema。

## 兼容策略

- encoder 只写 schema v2。
- decoder 接受 Godot v1/v2，并报告来源版本与是否需要重存。
- v1 没有 H01 地产状态和每日领取历史；codec 不补造数据，因此旧 G2 技术快照不能静默冒充 H01 可恢复档。
- 旧 Cocos `saveVersion` 仍被拒绝；如确有玩家旧档需求，使用独立 `CocosSaveImporter`。

## 自动验收

- `tests/p2/test_p2_save_codec.gd`：v2 H01 往返、v1 provenance 和不补造字段。
- `tests/p2/test_game_save_module.gd`：current/protected、按世界日选择最新 fallback、损坏回退、双损坏隔离、恢复写降级、只读强制、非空叙事/关系/配偶/矿洞字段保留与 profile 隔离。
- `tests/p2/test_atomic_file_save_adapter.gd`：首次写入、替换、读取、删除、绝对根/slot 拒绝，以及 tmp-only、target+tmp、backup+tmp、有效/损坏 rollback 的 pre-promote 中断、post-promote 中断和损坏 target+有效 previous 等状态。
- `tests/p2/test_game_save_atomic_recovery.gd`：真实 adapter 与 module 组合下的损坏 target、previous 回退、quarantine、rollback 中断与后续重新提交。
- `tests/p2/test_p2_persistent_state_bridge.gd`：进树前恢复及玩法 durable signal。
- `tests/p2/test_h01_persistent_launch.gd`：composition root 端到端新局、保存、恢复、protected 回退和无覆盖阻断。
- `tests/maps/test_p2_main_entry.gd`：Main 入口实际拥有 profile-scoped persistence binding。
- `tests/p2/test_save_profile_roster.gd`：三个摘要、最近档、恢复/错误分类、只读刷新、完整删除顺序及部分失败。
- `tests/p2/test_save_profile_main_ui.gd`：档位选择、所选档启动、最近档恢复、损坏阻断、确认/取消和 640×360 布局。
- `tests/p2/test_save_profile_roster_atomic_adapter.gd`：真实 D 盘 adapter 下清除 target/previous/temp，且其他档位字节不变。

## 后续

- P2：继续玩家节奏验证、经济参数校准和当前生活切片剩余出口条件；三档技术 UI 不等于最终标题/存档美术完成。
- 后续 UI：P5/P7 以正式视觉、设置、可访问性和完整游戏流程替换当前技术档位页。
- 下一 schema：增加单调 `saveRevision`，取代同一世界日下对 `savedAt` 文本顺序的依赖。
- 发行级 adapter：把瞬态第三物理候选、previous 恢复后的冗余重建和 previous rotation 降级诊断纳入压力/故障注入测试。
- P6～P8：长流程、断电/磁盘满、跨版本 fixture、可访问性与多设备测试。
- P9：发行期 Windows/Steam adapter、云冲突与导出验证。
