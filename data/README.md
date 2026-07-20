# Data baseline

G1 只迁移稳定 ID、四地图拓扑和最小目录数据。JSON 尚未接入运行时，也未完成 G2 的强类型解码与交叉引用验证。

`runtime_resources.json` 保留旧语义资源 ID，但所有 `godotPath` 目前均为 `null`，明确表示未回接任何运行时美术；不得把 `sourceStatus: not-migrated` 解释为资源已完成。
