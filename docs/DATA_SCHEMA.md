# 数据 Schema 基线

## G2 目录实现

- `data/crops.json`：`mistleaf`，种子 `mistleaf_seed`，收获物 `mistleaf`。
- `data/items.json`：`hoe_basic`、`watering_can_basic`、`mistleaf_seed`、`mistleaf`。
- `data/tools.json`：锄地/浇水语义与 1 格范围。
- `data/npcs.json`：15 名 NPC 稳定 ID、开场年龄、内容层级、关系边界和默认锚点。
- `data/localization.json`：zh-CN 文本键。
- `data/demo_world.json`：四地图、稳定锚点和六条双向 portal。
- `data/runtime_resources.json`：保留语义资源 ID；路径全部为 null，表示未迁移。

G2 的 `GameCatalogCodec` 将七份文档作为一个事务解码；任一版本、结构、枚举、范围、重复 ID、本地化或交叉引用错误都会拒绝整个目录。成功结果是强类型 `GameCatalog`，玩法不直接读取 JSON Dictionary。关系快照中的 NPC ID 必须存在于 NPC 目录。

## 稳定 ID

地图：`home_interior`、`hometown_main`、`boundary_pass`、`old_mine`。NPC 见 `NPC_BIBLE.md`。事件：`anomaly.first_barrier_fold`。档位：`profile-1`～`profile-3`。普通 ID 使用小写 ASCII、下划线/点/连字符的既定语义，不因显示名或资源路径改变。旧数据中已经稳定使用的条件键（例如 `opening.elderConversationCompleted`）单独按条件键规则保留 camelCase，不在迁移中静默改名。

## 新 Godot 存档 Schema（G2 已实现纯 codec）

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
storyFlags
relationships { affinity, relationshipState, spouseCharacterId }
mineRun { worldDay, brokenNodeIds, defeatedEncounterIds }
```

`SaveSnapshot` 和 `SaveCodec` 已覆盖上述权威字段、八格背包、引用范围和损坏拒绝，并能完成 JSON 往返。档位容器、metadata、currentSnapshot、未来 protectedRecoverySnapshot、三个物理隔离档位、最近档和原子文件仍属于 G5，尚未实现。

## 迁移原则

旧 Cocos `saveVersion=1`/`autosave` 不是新 schema。若以后导入，`CocosSaveImporter` 做显式、全有或全无转换；新 `SaveCodec` 只处理 Godot schema。无有效农田映射时不得悄悄丢弃作物后声称成功。

## 不变量

所有引用 ID 必须存在；背包数量和生命在范围内；每 NPC 只有一份关系记录；可有多条 dating 但最多一名配偶；世界日 `>=1`；同日矿洞 ID 不重复；持久快照不保存粒子、冷却、敌人瞬时位置或视觉预设。
