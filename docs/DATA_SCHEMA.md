# 数据 Schema 基线

## G1 已迁移目录

- `data/crops.json`：`mistleaf`，种子 `mistleaf_seed`，收获物 `mistleaf`。
- `data/items.json`：`hoe_basic`、`watering_can_basic`、`mistleaf_seed`、`mistleaf`。
- `data/tools.json`：锄地/浇水语义与 1 格范围。
- `data/localization.json`：zh-CN 文本键。
- `data/demo_world.json`：四地图、稳定锚点和六条双向 portal。
- `data/runtime_resources.json`：保留语义资源 ID；路径全部为 null，表示未迁移。

这些 JSON 在 G1 只保证语法和审计来源；G2 才实现强类型 decoder、重复 ID/枚举/范围/交叉引用验证。

## 稳定 ID

地图：`home_interior`、`hometown_main`、`boundary_pass`、`old_mine`。NPC 见 `NPC_BIBLE.md`。事件：`anomaly.first_barrier_fold`。档位：`profile-1`～`profile-3`。ID 使用小写 ASCII、下划线/点/连字符的既定语义，不因显示名或资源路径改变。

## 新 Godot 存档目标（尚未实现）

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

档位容器还包含可重建 metadata、currentSnapshot 和未来 protectedRecoverySnapshot。三个档位物理/语义隔离，最近档与全局设置不放入玩法快照。

## 迁移原则

旧 Cocos `saveVersion=1`/`autosave` 不是新 schema。若以后导入，`CocosSaveImporter` 做显式、全有或全无转换；新 `SaveCodec` 只处理 Godot schema。无有效农田映射时不得悄悄丢弃作物后声称成功。

## 不变量

所有引用 ID 必须存在；背包数量和生命在范围内；每 NPC 只有一份关系记录；可有多条 dating 但最多一名配偶；世界日 `>=1`；同日矿洞 ID 不重复；持久快照不保存粒子、冷却、敌人瞬时位置或视觉预设。
