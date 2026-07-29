# 数据 Schema 基线

## G2 目录实现

- `data/crops.json`：`mistleaf`，种子 `mistleaf_seed`，收获物 `mistleaf`。
- `data/items.json`：`hoe_basic`、`watering_can_basic`、`mistleaf_seed`、`mistleaf`。
- `data/tools.json`：锄地/浇水语义与 1 格范围。
- `data/npcs.json`：15 名 NPC 稳定 ID、开场年龄、内容层级、关系边界和默认锚点。
- `data/localization.json`：zh-CN 文本键。
- `data/demo_world.json`：四地图、稳定锚点和六条双向 portal。
- `data/runtime_resources.json`：保留语义资源 ID；路径全部为 null，表示未迁移。
- `data/estate_maps.json`：地产候选契约的正式运行投影，包含八图稳定身份、尺寸、安全出生点和状态轴；当前只有 H01 具有正式运行场景路径。

G2 的 `GameCatalogCodec` 将七份文档作为一个事务解码；任一版本、结构、枚举、范围、重复 ID、本地化或交叉引用错误都会拒绝整个目录。成功结果是强类型 `GameCatalog`，玩法不直接读取 JSON Dictionary。关系快照中的 NPC ID 必须存在于 NPC 目录。

`EstateMapCatalogCodec` 独立解码地产目录，拒绝重复 map/estate/candidate ID、非法稳定 ID、非 32px 格、空或重复状态值、缺失 season/development/anomaly、错误状态组合数和候选 staging 场景路径。它不修改 G2 `demo_world.json`，也不把八块候选地产写入存档 Schema。

## 稳定 ID

地图：`home_interior`、`hometown_main`、`boundary_pass`、`old_mine`。NPC 见 `NPC_BIBLE.md`。事件：`anomaly.first_barrier_fold`。档位：`profile-1`～`profile-3`。普通 ID 使用小写 ASCII、下划线/点/连字符的既定语义，不因显示名或资源路径改变。旧数据中已经稳定使用的条件键（例如 `opening.elderConversationCompleted`）单独按条件键规则保留 camelCase，不在迁移中静默改名。

## 新 Godot 存档 Schema（当前版本 2）

顶层至少包含：

```text
schemaVersion
savedAt
profileId
worldDay
currentMapId
player { position/anchor, facing, health }
farm { tilled/watered/crops }
inventory { slots, quickbar, selectedIndex }
estateMapState { mapId, axes }
dailyResourceClaims { claimKey, lastClaimedDay }
storyFlags
relationships { affinity, relationshipState, spouseCharacterId }
mineRun { worldDay, brokenNodeIds, defeatedEncounterIds }
```

`SaveSnapshot.schemaVersion=2` 和 `SaveCodec` 已覆盖上述字段、八格背包、引用范围、H01 地产状态与每日领取记录，并能完成确定性 JSON 往返。decoder 继续接受 Godot schema v1，返回 `source_schema_version` 与 `requires_resave`，但不会凭空补造 v1 中不存在的地产或领取历史；因此有效的旧 G2 技术快照仍可由 codec 读取，却不能伪装成可恢复的 H01 P2 会话。

P2 application 层当前使用 `profile-1`～`profile-3` 作为互相隔离的当前检查点键，以 `profile-N.protected` 保存成功休息后的受保护恢复点。恢复还验证每个键的物理 previous 候选；current primary 无效时按世界日、保存时间和稳定来源优先级选取最新 fallback。fallback 前隔离可读无效载荷，隔离失败则只读恢复。没有有效候选时阻止启动并保留原载荷，不静默创建新局覆盖证据。尚未实现最近档 metadata、三档选择 UI、档案删除 UI、Steam 云或 Web/微信 adapter。

## 迁移原则

旧 Cocos `saveVersion=1`/`autosave` 不是新 schema。若以后导入，`CocosSaveImporter` 做显式、全有或全无转换；新 `SaveCodec` 只处理 Godot schema。无有效农田映射时不得悄悄丢弃作物后声称成功。

## 不变量

所有引用 ID 必须存在；背包数量和生命在范围内；每 NPC 只有一份关系记录；可有多条 dating 但最多一名配偶；世界日 `>=1`；同日矿洞 ID 不重复；地产 map ID、玩家位置/回退锚点、状态轴、农田格和领取日必须通过相应目录与地图边界校验；领取日不得晚于世界日。持久快照不保存粒子、Tween、可取消确认、冷却、敌人瞬时位置或视觉预设。
