# Data baseline

G1/G2 建立了稳定 ID、四地图种子拓扑和最小目录数据，并由 `CatalogFileLoader`/`GameCatalogCodec` 原子完成版本、结构、枚举、范围、重复 ID、本地化和交叉引用校验。这里的四地图和 15 名 NPC 是技术底座使用的种子内容与回归 fixture，不是完整游戏的正式数量、最终正史或未来内容上限；产品重基线可以通过显式 Schema/数据迁移扩充、替换或废弃。

`runtime_resources.json` 保留旧语义资源 ID，但所有 `godotPath` 目前均为 `null`，明确表示未回接任何运行时美术；不得把 `sourceStatus: not-migrated` 解释为资源已完成。
