# AGENTS.md

## 项目目标

本仓库是《雾乡如昨》的 Godot 4 正式工程。当前完成迁移 G0～G2 验收候选；不得把旧 Cocos 工程或后续里程碑的能力写成当前 Godot 能力。

## 技术基线

- 引擎：已安装的 Godot `4.7.1.stable`；未经确认不升级。
- 语言：强类型 GDScript；不使用 C#/.NET。
- 渲染：Godot 2D、Compatibility Renderer。
- 画面：横屏、640×360 逻辑分辨率、32×32 基础瓦片、96×96 第一版角色画布。
- 地图：Tiled 源文件 + 经验证的可重复 Godot 导入/转换流程。
- 数据：版本化 JSON 和稳定 ID。
- 长期文件、导入缓存、构建与资源源文件都在 D 盘。

## 迁移来源边界

旧工程 `D:\lzq\AI游戏\FarmGame` 只读。禁止修改、删除或提交旧文件；禁止复制 `.git`、`.codegraph`、`library`、`temp`、`build`、`profiles`、缓存、Cocos `.meta`、组件 UUID 与自动场景依赖。新仓库自行建立索引与 Git 历史。

## 架构规则

1. 农田、背包、作物、历法、存档编码、关系判定等规则优先放入 `scripts/domain/`，不依赖 Node、场景树、物理帧或平台 API。
2. `scripts/gameplay/` 的 Node 只负责生命周期、输入转发、视觉、碰撞、场景引用与领域桥接。
3. 平台能力通过 `PlatformService`、`SaveService`、`InputService`、`AudioService`、`AnalyticsService` 边界注入；核心玩法不得访问 `window`、`localStorage`、`wx`、Steamworks 或具体文件路径。
4. 运行环境与发行渠道分开：环境 `windows-native`/`web`；渠道 `standalone`/`steam`/`wechat`。
5. 使用明确参数与返回类型；避免无边界 `Variant`、巨型全局单例和把全部状态放进 Autoload。
6. 地图、NPC、作物、物品、对白和存档字段的稳定 ID 不得随迁移随意更名。
7. Godot 的 `.godot` 缓存和资源 UID 由匹配版本引擎生成，不手工伪造。

## 产品与叙事护栏

- Demo 恰好四张玩法地图：`home_interior`、`hometown_main`、`boundary_pass`、`old_mine`。
- 第一处异常为 `anomaly.first_barrier_fold`；必须由玩家主动触发，之后可回归日常，不泄露核心真相。
- 十五名 NPC、稳定 ID、年龄与关系规则以 `docs/NPC_BIBLE.md` 为准。
- 重构村民是拥有独立意识的新生命，不是复活者、空壳或幻影。
- 恋爱资格不因主角/NPC 性别或幸存者/重构分类变化；未成年人必须保持明确成年边界；罗岑山、陈蕴仅有非恋爱关系。
- 视觉效果必须能按画质等级关闭；微信低档不依赖实时阴影、多灯、景深、体积雾或高成本后处理。
- 不在普通工程任务中生成或定稿大量视听资源；只接入来源清楚且经确认的资源。

## 存储与资源

- 新工程唯一写入根：`D:\lzq\AI游戏\WuxiangRuzuo-Godot`。
- 正式构建输出：`D:\lzq\AI游戏\WuxiangRuzuo-Godot-Builds`。
- `art-source/`、`audio-source/` 和 `builds/` 使用 `.gdignore`。
- 未登记或来源不明资源不得进入 `assets/` 或发行构建。
- 大型二进制在 Git LFS 策略获确认前不得提交。

## 迁移里程碑护栏

使用 G0～G13，不复用旧 Cocos 阶段号。每个阶段必须有入口、验收、可执行测试与回归检查；用户验收后才进入下一阶段和建立/推送基线。当前停在 G2 发布/验收点，不得自动开始 G3；用户已于 2026-07-20 明确授权建立并推送 G2 基线。

## 工作流程

1. 先读本文件及相关权威文档并检查 Git 状态。
2. 只修改当前阶段范围，保护用户已有变更。
3. 在 Godot headless/编辑器中实际解析和运行，不把文本检查当运行验证。
4. 计划与已实现严格分开；无法自动完成的步骤写入 `docs/GODOT_MANUAL_STEPS.md`。
5. 修改后运行对应测试、记录结果并更新 `PLANS.md`。
6. 每个新里程碑都必须先汇报验收结果；未经用户明确授权，不得建立或推送该里程碑基线。
7. 能由命令、文件检查、headless、编辑器运行或自动测试确认的事项由迁移任务自行完成；不得要求用户重复执行非必要的人工检查。只有真正无法自动化且需要用户判断的视觉/产品决策才请求用户参与。

## 文档权威顺序

1. `AGENTS.md`：工程与流程硬约束。
2. `docs/DEMO_SCOPE.md`：Demo 范围与明确不做项。
3. `docs/NARRATIVE_BIBLE.md`、`docs/NPC_BIBLE.md`、`docs/FIRST_BARRIER_ANOMALY.md`：叙事、人物与保密边界。
4. `docs/DEMO_SAVE_AND_CALENDAR.md`、`docs/MINE_COMBAT_SLICE.md`：存档/历法/矿道规则。
5. `docs/GODOT_ARCHITECTURE.md`、`docs/TECH_SPEC.md`、`docs/PLATFORM.md`、`docs/DATA_SCHEMA.md`：当前技术事实和未来接口。
6. 美术/UI/对白/存储/资源工作流文档。
7. `PLANS.md`：迁移执行顺序与验收记录。
