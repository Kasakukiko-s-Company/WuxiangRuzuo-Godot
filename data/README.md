# Data baseline

G1 迁移了稳定 ID、四地图拓扑和最小目录数据。G2 已由 `CatalogFileLoader` 在应用边界读取七份 JSON，并由 `GameCatalogCodec` 原子完成版本、结构、枚举、范围、重复 ID、默认本地化和交叉引用校验；只有完整通过时才发布强类型 `GameCatalog`。`npcs.json` 只固化 15 名 NPC 的身份、开场年龄、内容层级、关系边界和默认锚点，不代表 G7 玩法已实现。

`runtime_resources.json` 保留旧语义资源 ID，但所有 `godotPath` 目前均为 `null`，明确表示未回接任何运行时美术；不得把 `sourceStatus: not-migrated` 解释为资源已完成。
