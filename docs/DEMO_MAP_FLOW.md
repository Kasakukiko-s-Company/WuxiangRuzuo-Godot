# Demo 四地图拓扑与锚点

## 拓扑

```text
home_interior <-> hometown_main <-> boundary_pass
                       |
                       +-------------> old_mine
```

禁止住宅直达边界/矿道或矿道直达边界。所有切换使用 map ID + anchor ID + condition ID，不散落硬编码坐标；失败留在来源图并给出可本地化反馈。

## 初始灰盒预算

| 地图 | 格数 | 世界像素 | 安全点 |
| --- | --- | --- | --- |
| `home_interior` | 20×12 | 640×384 | `home_bed` |
| `hometown_main` | 64×48 | 2048×1536 | `main_safe_spawn` |
| `boundary_pass` | 40×24 | 1280×768 | `boundary_entry`/`boundary_return` |
| `old_mine` | 32×24 | 1024×768 | `mine_safe_return` |

完整必需锚点与 portal 已迁入 `data/demo_world.json` 并通过 G2 交叉校验；`scenePath` 仍全为 null，表示四图场景尚不存在。

## 地图层语义

表现层目标：Ground、Ground_Detail、Water、Path、Objects_Back、Characters、Objects_Front、Effects。逻辑层/对象表达碰撞、farmable、sleep、spawn、portal、anomaly trigger 和 safe anchor。具体采用 TileSet custom data 或对象层转换，必须在 G3 小图验证后决定。

## 坐标护栏

旧 TMX 是有限正交、right-down、左上行序；旧领域代码曾把 Cocos Tiled Y 转为底左原点。Godot 不能照抄 Cocos 世界坐标。G3 必须逐点验证 map/local/world、角色锚点、碰撞、遮挡和 Camera2D limits，并将转换集中到单一 adapter。

## 当前事实

旧库没有四张正式 TMX，只有 `mvp_farm.tmx` 冒烟图。截至 G2 未复制或导入地图；G3 先验证小图，G6 才实现四图与切换。
