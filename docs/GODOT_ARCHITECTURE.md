# Godot 架构基线

## 当前事实（G1）

项目只有最小 `Main.tscn`、`main.gd`、`AppCompositionRoot` 脚手架、JSON 清单与 headless 冒烟测试。没有领域玩法、地图、存档 adapter、NPC、战斗或正式 UI。此文档的其余内容是后续实现边界，不是完成声明。

## 目录与依赖方向

```text
scenes / scripts/gameplay / scripts/ui
                 |
                 v
          scripts/app (composition)
             /            \
            v              v
 scripts/domain      capability contracts
                         ^
                         |
 scripts/platform / scripts/persistence
```

- `domain` 不依赖 Node、SceneTree、Input、FileAccess、平台全局或渲染资源。
- `gameplay` 把 Godot 输入/碰撞/TileMapLayer 结果转换为领域命令，并投影领域状态。
- `platform` 提供环境/渠道、输入、音频、分析与生命周期 adapter。
- `persistence` 提供 SaveService adapter、原子文件写入、schema codec 与显式旧档导入。
- `app` 是唯一装配入口；release 构建不得静默使用内存存档。

## 目标深模块

| 目标模块 | 形态 | 职责 |
| --- | --- | --- |
| `FarmState` | `RefCounted`/值对象 | 农田权威状态与可耕格事务 |
| `InventoryState` | `RefCounted`/值对象 | 堆叠、容量、增减与八格快捷栏事务 |
| `CropPlanting` | 纯函数/服务 | 农田+背包原子播种 |
| `CropGrowth` | 纯函数/服务 | 浇水条件、跨天成长、阶段推导 |
| `CropHarvesting` | 纯函数/服务 | 成熟检查、背包容量与原子收获 |
| `FarmDayCycle` | 领域服务 | 睡觉、跨天顺序、当日重置 |
| `SaveCodec` | 纯 codec | 新 Godot schema 的编码/解码/校验 |
| `CocosSaveImporter` | 独立迁移器 | 显式读取旧 v1 payload；不污染正常 codec |
| `RelationshipLedger` | 领域服务 | 全员好感、多 dating、唯一配偶、年龄边界 |

## 平台能力

至少保留 `PlatformService`、`SaveService`、`InputService`、`AudioService`、`AnalyticsService`。运行环境：`windows-native`、`web`；发行渠道：`standalone`、`steam`、`wechat`。Steam 是 Windows 渠道；微信能力只能在 G12 技术验证后决定 adapter。

## 场景与状态

场景 Node 只拥有生命周期、信号、物理运动、碰撞、视觉与场景引用。领域状态不以节点树作为唯一事实源；跨场景状态由受控 session/application 层持有并通过 codec 保存。避免把所有状态堆入单一 Autoload。

## 地图 seam

地图定义提供稳定 map ID、场景路径、命名锚点、入口、功能层和安全回退。地图坐标转换集中在单一 adapter；领域瓦片坐标不得依赖 TMX 行号、Godot cell source ID 或世界像素。G3 先用小图验证，G6 才落地四张正式地图。

## 存档 seam

`SaveCodec` 只处理领域快照；`SaveService` 只处理不透明 payload；application session 决定何时捕获/恢复。Windows adapter 使用 D 盘可控的 Godot user data 路径/文件协议并实现临时文件替换；Web/微信和 Steam adapter 不改变领域 schema。

## 质量与测试

- 纯领域模块使用 headless GDScript 单元/场景测试。
- 场景垂直切片用可启动 `.tscn` 验证输入、碰撞、摄像机与坐标。
- JSON decoder 必须拒绝未知 ID、重复 ID、越界值和破损交叉引用。
- 每阶段同时运行上一阶段测试，避免回归。
