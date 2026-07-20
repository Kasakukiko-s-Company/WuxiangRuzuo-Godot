# Godot 技术规格

## 已实现（G1）

- Godot 4.7.1 stable、GDScript、Compatibility Renderer。
- 640×360 viewport，`canvas_items` + `keep` 横屏拉伸。
- `Main.tscn`、最小 composition root、headless smoke test。
- D 盘 self-contained `editor_data` 与项目内 `.godot` 缓存策略。
- 稳定 JSON 清单和四地图拓扑（未接运行时）。

## 未实现/计划

- G2：强类型 catalog codec、领域状态与平台契约。
- G3：CharacterBody2D、碰撞滑动、Camera2D、瓦片坐标与 InputMap。
- G4/G5：农作闭环、三档存档和跨天。
- G6：TileMapLayer 地图、触发器和场景切换。
- G7～G10：NPC/对白、战斗、应用 UI、正式资源与画质。
- G11～G13：Windows/Web/微信/Steam 验证与发行 adapter。

## 代码规则

纯领域模块不继承 Node；参数/返回值强类型；错误通过显式结果或受控 assertion 表达。Node 只桥接生命周期、输入、物理、表现和场景。复杂规则有注释与测试。资源加载通过语义 manifest，不把 `.godot/imported`、UID 或具体平台路径写进玩法。

## 坐标和地图

权威领域格坐标统一为 `Vector2i`，原点/轴向由地图 adapter 明确转换。正式地图层：Ground、Ground_Detail、Water、Path、Objects_Back、Characters、Objects_Front、Effects。碰撞、可耕、床、出生、出口和触发器必须从可验证数据生成。G3 先小图，G6 再四图。

## 视觉预算

所有粒子、动态灯、Shader 和后处理可按档位关闭。低档必须用 Sprite/静态覆盖/轮廓/文本表达全部功能。避免每 Tile/树独立材质和多实时灯。

## 数据与存档

目录 JSON 与存档均有 `schemaVersion`，但版本生命周期分开。跨引用由 G2 validator 校验。新 SaveCodec 不读取 Cocos localStorage；显式旧档导入器只在未来需要时实现。
