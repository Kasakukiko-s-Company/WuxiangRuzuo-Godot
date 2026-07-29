# 《雾乡如昨》完整游戏制作计划

## 状态口径

旧 Cocos 工程是未达到 Demo 标准的雏形，只能提供可选素材、技术经验和反例。G0～G2 记录已经完成的迁移审计与技术底座，不定义完整游戏规模；旧 G3～G13 已停止，不再按 Cocos 功能清单推进。

## 已建立基线：G0～G1

### G0 旧项目审计

状态：已完成并包含于首个 `main` 基线。

- 已只读检查旧 Git 状态；旧仓库存在用户未提交变更，未触碰。
- 已优先使用旧 `.codegraph` 理解 TypeScript 调用路径。
- 已盘点文档、代码、数据、TMX、场景、资源源文件、平台、存档与测试。
- 已形成 `docs/MIGRATION_AUDIT.md` 与 `docs/MIGRATION_MATRIX.md`。
- 未复制旧 `.codegraph`、Cocos 缓存、`.meta` 或未清权候选素材。

### G1 Godot 工程基础

状态：已验收并推送；基线提交 `02a442da46549c814e332b5dd36c50822d31dc5c`。

入口：`res://scenes/Main.tscn`。

验收标准：

- Godot 4.7.1 stable 能完成 headless 导入与脚本解析。
- Main 场景能启动，composition root 返回 G1 状态。
- 640×360、`canvas_items + keep` 与 Compatibility Renderer 设置生效。
- 数据只迁移稳定 ID/拓扑清单，未声称玩法已实现。
- Git 仓库独立初始化，`main` 已跟踪新的 `origin/main`。
- `.godot`、构建输出、editor_data 和临时文件不进入 Git。

自动验证（2026-07-20）：

- `--headless --editor --quit`：exit 0，无项目解析错误；self-contained editor_data 写入 D 盘。
- `tests/smoke/test_g1_smoke.gd`：7 项 PASS，输出 `G1_SMOKE_OK`。
- 默认 Main 场景 `--quit-after 2`：exit 0，输出 composition root ready。
- 6 个 JSON：全部通过 PowerShell `ConvertFrom-Json`。
- Git：G0～G1 根提交已推送；`.godot` 与构建输出忽略命中。
- 新项目无大文件；除默认 Godot 运行日志外，长期文件均在 D 盘。

## 当前验收点：G2

状态：实现与验收已完成；用户已于 2026-07-20 明确授权建立并推送 G2 基线。

入口：`res://scenes/Main.tscn`，状态文字显示 G2；自动测试位于 `tests/g2/`。

已实现：

- 七份 JSON 的版本、结构、枚举、范围、重复 ID、本地化和交叉引用原子校验，含 15 名 NPC 稳定身份与关系边界。
- 强类型 `GameCatalog` 及物品、作物、工具、地图、portal、语义资源查询。
- 不依赖 Node 的 `InventoryState`、八格选择和全有或全无增减事务。
- 不依赖 Node 的 `FarmState`、稀疏耕作格状态和开垦事务。
- 新 Godot `SaveSnapshot.schemaVersion=1` 与纯 `SaveCodec` 往返/损坏校验。
- `PlatformService`、`SaveService`、`InputService`、`AudioService`、`AnalyticsService` abstract contracts。
- composition root 实际读取目录并只在完整验证后发布给启动场景。

验收标准：

- Godot headless editor/import、全部 G2 测试、G1 smoke 和默认 Main 启动均为 exit 0。
- 旧 Cocos `saveVersion` 不由新 codec 解码。
- 代码和文档不声称 G3～G13 能力已完成。
- `.godot`、日志、构建、大文件和未知来源资源没有进入 Git 变更。

自动验证（2026-07-20）：Godot editor/import、G1 smoke、六个 G2 测试和默认 Main 启动全部 exit 0；G1+G2 共 99 项行为检查通过。完整记录见 `docs/G2_VERIFICATION.md`。

## P0 产品重基线

状态：产品方向与 P1 规格已获用户确认；P0–P1 基线已建立并推送，当前 `main` 与 `origin/main` 均指向提交 `4f2874bec250b2d401fac1b8ee676966417f4b50`（`Establish Godot P0-P1 baseline`）。

已形成 `FULL_GAME_VISION.md`、`PRODUCT_BRIEF.md`、`FULL_GAME_ROADMAP.md`、`CONTENT_AND_ASSET_STRATEGY.md`、`CONTENT_BUDGET.md`、`P0_DECISION_LOG.md` 与 `P1_EXPERIENCE_PROTOTYPE.md`。正式游戏目标、内容生产轨和“战斗必须存在”已经取代旧 Cocos 雏形范围。

## 已完成基线：P1 体验原型

状态：实现、自动回归和 Compatibility Renderer 画面检查已完成，并已随 P0–P1 基线提交和推送。P2 地产地图工程先导已经开始；P1 继续作为前序回归入口。

可玩入口：默认 `res://scenes/Main.tscn` 的“进入 P1 体验原型”按钮，或直接运行 `res://scenes/prototypes/p1_experience_probe.tscn`。

已实现：

- 40×28、32px 基础格的全新 `prototype_mist_edge` 灰盒，不复用旧四图。
- 强类型移动意图、四方向面向、对角归一化、96 px/s 移动、`CharacterBody2D` 碰撞与贴墙滑动。
- Camera2D 边界、平滑跟随和 reduce-motion 回退。
- world/cell/facing-cell 坐标 seam，以及 F3 调试叠层。
- 键盘/手柄共用的语义输入 adapter；移动、交互、画质、暂停、重置与调试动作均有默认绑定。
- 8 个可检查对象，一次性/可重复反馈，交互锁定与自动恢复。
- 可整体替换的程序化地形、玩家、前景遮挡、高低画质和原创生成式原型音频；未导入来源不明资源。
- Main 场景明确入口和可重复的非 headless 视觉捕获工具。

自动验证（2026-07-20）：

- Godot 4.7.1 stable editor/import、默认 Main 与 P1 直接启动均为 exit 0，最终日志无解析错误或对象泄漏警告。
- G1+G2 原有 99 项行为检查和 P1 35 项行为检查全部通过，共 134 项。
- Compatibility Renderer 实际使用 Intel Iris Xe / OpenGL 3.3 渲染；自动生成高、低画质与调试视图，均为 640×360 逻辑视口的 2× 物理输出（1280×720）。
- 高/低画质像素输出不同；低画质仍保留路径、角色、碰撞边界和交互提示。完整记录见 `docs/P1_VERIFICATION.md`。

地图资源候选（2026-07-22 起，不改变 P1 验收状态）：

- H03 林间洼地的宏观布局获用户通过，完成第二版 128×96、32px Tiled 技术灰盒候选。
- 第二版 2.1 使用瓦片级权威掩码记录水域碰撞、可耕地、自由建造、大型设施预留地和禁建区；全部无冲突空地可耕，可耕与建造权限允许重叠；修复道路/悬崖/房屋/桥面冲突，并为三个出口建立成对返回点。
- 开局不再提供无杂物的独立耕地；住宅附近使用连续噪声和柔和衰减降低清理成本，外围逐步增加密度与重型资源权重，不显示硬分区。
- 钓鱼采用“任意合法位置抛投，终点命中可钓水域”的连续水域规则；岸边点只承担可达性 QA，不限制玩法。
- Tiled 1.12.2 实际渲染开局荒废和建设后预览；128 项结构、掩码语义与跨层冲突检查全部通过。
- 用户于 2026-07-22 确认 H03 第二版 2.1 技术布局，可作为后续地产地图管线的技术标杆；正式美术、Godot 接入和其他地产批量生产仍需另行开始。
- H03 正式环境美术 Batch 001 的 A/B/C 三方向已由用户确认采用混合方式。Batch 002 已按“A 氛围与材质、B 过渡与资源量、C 层石克制与异常潜力”生成五个资源家族，并额外保留亲切易读与低矮偏置两条建筑支线；共 8 个 PNG，均位于 D 盘 `formal-tiles/candidates/batch-002-hybrid/`，提示、尺寸、授权和 SHA-256 已登记。它们仍是 `hybrid_source_sheet_candidate`，不能直接裁切或进入 `assets/`；下一步是 32×32 人工重构和 Tiled Terrain 实铺。
- H03 Batch 003 原生 32px 视觉方向已于 2026-07-22 获用户确认。随后生成独立的 128×96 春季荒废/建设后全图候选：保留26个瓦片层、14个对象层、六类权威掩码及全部出生点/出口语义，宽路/宽水面连接孔洞已修正；Tiled 实际渲染和98项全图检查通过。候选位于 `batch-003-native32/full-map/`，未覆盖权威灰盒、未进入 `assets/` 或 Godot。
- 用户于 2026-07-22 进一步确认 Batch 003 完整春季地图的宏观布局与原生 32px 技术方向。独立 Batch 004 春季细化候选已重绘地表、道路、水岸、悬崖、树木、杂物、围栏、住宅和旧设施，并以 12 个春季地表变体和对角角块减少大图重复与方角；两张 128×96 TMX 仍保留 26 个瓦片层、14 个对象层和逐层相同占用，D 盘 Tiled 实际渲染、机器可读地图清单与 150/150 项回归通过。用户已确认该春季细化视觉作为四季与异常候选的生产基准；状态为 `spring_detail_visual_approved_for_seasonal_expansion`，`shippingApproval=false`。
- 独立 Batch 005 已从获批的 Batch 004 春季像素与 H03 技术语义派生四季及轻/中度异常候选：四季各三张原生 32px 图集与 TSX，另有轻度/中度异常各三张专用图集与 TSX；地图为春夏秋冬×荒废/建设后八张 TMX，以及春季建设后轻度/中度异常两张 TMX。用户指出第一版异常对比不清晰后，异常可读性修订为第二版：不再依赖均匀全屏滤色，改用可区分的常态/轻度/中度图集状态，并沿溪流、北部泉眼与旧石渠布置有间断的定向雾、错误阴影和局部青色裂光；三种状态仍共享几何、权威掩码与对象层。冬季积雪同步降低亮度、缩小范围并增加裸地纹理，水面保持开放可钓。10 张 128×96 TMX 均经 D 盘 Tiled 实际渲染，764/764 项图集、图层、对象、掩码、冬季水域、异常差异门槛、预览和 D/C 盘边界检查通过。状态仍为 `seasonal_anomaly_candidate_for_visual_review`，等待用户视觉确认，`shippingApproval=false`。
- 对 Batch 005 的进一步审计确认其异常视觉虽然可见，但把异常资源和春季/建设后状态耦合，且仅以地图属性记录对象状态，不适合作为正式生产管线。独立 Batch 006 已改为季节、地产发展、异常三个正交状态轴：只保留一张 128×96 权威 TMX，14 张组合 TMX 全部是可重复生成的审阅派生物；四季仍使用各自三类原生 32px 图集，轻/中度异常共用一张 512×256 RGBA 增量图集和 7 个稳定对象状态锚点。轻度采用可察觉但保留日常读感的冷暗偏移与稀疏征兆；中度进一步加强局部裂光、附着于投影物的错误阴影和雾迹，不再出现整屏规则条纹。青色对象征兆与 514 个水格严格不重叠，因此不会被误读为特殊钓鱼点；出生点、出口、对象层、权威掩码和几何保持不变。D 盘 Tiled 实际栅格化及 335/335 项结构、跨季节/荒废状态、异常差异、来源和磁盘边界检查通过；Batch 006 状态为 `composable_state_candidate_for_visual_review`，取代 Batch 005 作为当前异常组合候选，`shippingApproval=false`。
- 独立 Batch 007 已修正 Batch 006 冬季积雪的大圆斑、高亮和重复斜纹：积雪格由 2626 减至 1510，拆成 6 个可辨识区域、8 个互相组合的雪簇造型，使用非周期成簇裸地孔洞和较低亮度青灰雪色；荒废/建设后画面的高亮像素覆盖约从 9.6%/10.0% 降至 4.6%/4.7%。同时在唯一权威 TMX 内新增隐藏 `Season_Winter_Ground` 完整替换层，使冬季真实 Ground 状态不再只存在于非权威审阅图。17 张派生 TMX 已补齐冬季荒废/建设后×常态/轻度/中度六种组合；水体 514 格、水域碰撞 430 格、桥面、钓鱼规则、对象层和权威掩码保持。D 盘 Tiled 实际栅格化与 284/284 项检查通过。用户于 2026-07-23 确认其冬季、异常和组合管线，状态冻结为 `h03_estate_pipeline_benchmark_approved`，可开始复用于其余七种地产；`shippingApproval=false`。
- 已将 H03 标杆冻结为 `art-source/maps/estate-pipeline-v1/` 的可配置生产契约：地图尺寸、季节/发展/异常/建造轴、必需图层与对象层、连续钓鱼、全空地可耕、开局出口可达、来源登记和 Tiled 验收均有机器可读 profile，不把 H03 的 128×96 或单溪流拓扑硬编码到其余地产。
- H02 辫河洲地 Batch 001 已完成独立 144×104 技术布局候选：常态水域 4302 格、可耕 8069 格、自由建造 5870 格、设施预留 621 格、开局杂物 1566 格，高水位 delta 757 格。永久旧桥/浅滩承担基础通勤，东侧与北侧后期桥独立解锁；桥状态同时改变碰撞与可钓权威。8 个 FishingAccessQA 点已改为常态/高水位都可达、站位不碰撞且四邻存在可钓水域的验证点，验证后丢弃，不成为固定钓鱼点。1 张权威 TMX、5 张可重建审阅 TMX 经 D 盘 Tiled 实际栅格化，436/436 项检查与独立复审通过，MUST/SHOULD 均为 0；四季/异常专属美术与正式 Godot 接入未开始，`shippingApproval=false`。
- H01 开阔草甸 Batch 001 已完成独立 128×96 技术布局候选：水域 889 格、可耕 10068 格、自由建造 8818 格、设施预留 921 格、开局杂物 1746 格。水域单连通且连续可钓；后期道路在荒废期以断续旧路提示，成熟期 crossing 同步移除碰撞、可钓资格和生态归属；南侧条件出口由同一 stable lock 控制碰撞与五格石障视觉。1 张权威 TMX、2 张可重建审阅 TMX 经 D 盘 Tiled 实际栅格化，278/278 项检查通过；H01 专属草甸、四季与异常美术以及 Godot 接入仍待后续，`shippingApproval=false`。
- H03 已额外形成隔离的 Godot 4.7.1 runtime-staging 候选：`maps/candidates/h03-runtime-staging-v1/` 将获批 Batch 007 的春季×荒废×常态组合转换为可直接加载的 `.tscn`、`.tres` 与语义 JSON。隔离工程完成 import/build/verify/scene-load，208/208 项检查与独立复审通过；它不是正式工程集成，尚未连接玩家、摄像机、耕作、建造、钓鱼、NPC、剧情、portal、存档或运行时状态切换。
- H03 已继续形成全状态 `maps/candidates/h03-runtime-staging-v2/`：以一张 Godot 场景、四套季节视觉 TileSet 和一套逻辑 TileSet 承载春夏秋冬×荒废/建设后×常态/轻度/中度异常共 24 种组合，不复制 24 张场景。最终 fresh run `37e6cd5bb3ee43a79fc0f74794e0118b` 的转换预检为 28/28、Godot 4.7.1 动态验证为 354/354、24/24 状态通过，import/build/异常差异/verify/scene-load 五条命令均 exit 0；实际 Physics2D 查询验证荒废杂物碰撞会随建设状态移除并可恢复，永久碰撞保持，水域连续可钓规则、冬季开放水域、出口条件和 79 个稳定运行对象均保留。100 次状态切换 p95 为 9.241 ms、最大 12.909 ms，节点、对象和资源计数无增长；受控 payload 为 10.307613 MiB。
- H01 已形成独立 `maps/candidates/h01-runtime-staging-v1/`：把春季×荒废×常态权威 TMX 转为可直接加载的 `.tscn`、`.tres` 与语义 JSON，保留 14 类 H01 logic、13 个视觉层、9 个隐藏语义层及全部 crossing、生态和条件出口契约。最终 fresh run 为 `2b54645d90404e0696b3ad785e216534`，转换预检 144/144、Godot 4.7.1 验证 239/239、四条命令 exit 0；TMX、审批/验证/授权/交接记录、共享 disposition contract、profile、8 个 TSX/PNG 与两级转换器共 17 项绑定全部通过。
- H01 已复用标杆管线形成 `maps/candidates/h01-runtime-staging-v2/`：一张动态场景承载春夏秋冬×荒废/复垦/扩建/成熟×常态/轻度/中度异常共 48 种组合。最终 fresh run `940c740ec29148378aa5cd9c5654e480` 的转换预检为 17/17、Godot 4.7.1 验证为 243/243、48/48 状态通过，五条命令均 exit 0；真实 Physics2D 查询验证 crossing 和荒废杂物均按 `1→0→1` 移除并恢复，4 个 FishingAccessQA 点通过后丢弃，连续抛竿水域规则保留。100 次状态切换 p95 为 5.252 ms、最大 5.821 ms，无节点、资源或对象增长；两张 bitmap 审阅图分别为 2048×1236 和 1440×1182。独立终审为 MUST 0、SHOULD 0。
- H02 已形成独立 `maps/candidates/h02-runtime-staging-v1/`：把春季×荒废×常态水位×双桥关闭状态转为可直接加载的 `.tscn`、`.tres` 与语义 JSON，保留 12 类 H02 logic、40 个运行 TileMapLayer、1 个 metadata-only 高水位汇总层及桥梁/高水位状态契约。最终 fresh run 为 `712cd15fe33d41dd9dbb4e82159cf657`，转换预检 46/46、Godot 4.7.1 验证 357/357、四条命令 exit 0；17 项来源/运行绑定全部通过。临时 `.tooling`、`.godot-user` 与 Godot 用户根空目录在每次构建后自动删除。
- H02 已复用标杆管线形成 `maps/candidates/h02-runtime-staging-v2/`：一张动态场景承载春夏秋冬×荒废/复垦/扩建/成熟×常态/轻度/中度异常×常态/高水位×东桥关闭/开启×北桥关闭/开启共 384 种组合。最终 fresh run `8b8c4c6dfaba466ebcbf214aefaedd34` 的转换预检为 66/66、Godot 4.7.1 验证为 816/816，384 正序、384 逆序和 100 次确定性状态序列全部通过；真实 Physics2D 查询验证荒废杂物按 `1→0→1` 切换，水位与双桥同步更新水域碰撞、可钓权威和通行状态。运行格计数明确为 52203 个源包含格＋1076 个季节/异常生成格＝53279；全状态 p95 14.464 ms，水位 p95 14.909 ms，其余即时轴 p95 不高于 4.792 ms，季节切换 p95 70.366 ms，故必须在睡眠、换季、地图载入或淡入淡出等过渡边界执行。1368×2212 bitmap 审阅图覆盖六轴与局部对照；独立终审为 MUST 0、SHOULD 0。
- H01/H02/H03 v2 runtime-staging 的父目录已加入 `.gdignore`，正式根工程不会扫描嵌套候选项目；三者均仅在 D 盘生产，日志无 C 盘路径，仍为 `runtimeIntegrated=false`、`shippingApproval=false`，没有修改正式 `project.godot`、现有正式场景、核心代码或存档 Schema。H01/H02 的复垦、扩建和成熟状态仍是技术占位，不是正式建筑美术；H03 v2 的“建设后”同样只是清场与技术建成态。H01/H02 已生成 bitmap 审阅图；H03 仍只有 headless 图层、格数和 TileSet 指纹证据。三者均未测量正式 640×360 逻辑画面在各目标输出分辨率下的真实渲染帧时。
- 用户允许从 itch.io 等平台寻找免费候选资源，也允许 AI 生成；准入仍以商用、修改、再分发与署名条款为准，逐项记录 URL、作者、版本、下载日期、许可、尺寸和 SHA-256。所有下载、解压、中间文件与生成结果只放 D 盘候选目录，默认 `shippingApproval=false`，不得覆盖正式资源。
- 地图源候选位于 `art-source/maps/`，隔离 Godot 候选位于 `maps/candidates/`；它们在地产包交接完成时仍未进入正式工程。随后 P2 只从 H01 候选派生小型正式运行 payload，其余候选继续隔离；`project.godot` 与存档 Schema 未修改。
- H04～H08 已一次性完成为 Godot 4.7.1 隔离动态候选：H04 山地梯田 128×112、192 状态（69/69＋31/31）；H05 芦苇湿地 144×104、384 状态（78/78＋39/39）；H06 石质高地 128×96、192 状态（65/65＋540/540）；H07 湖畔半岛 144×96、192 状态（66/66＋540/540）；H08 旧果园遗址 128×96、192 状态（85/85＋574/574）。五图均完成正序、逆序、确定性随机、Physics2D、portal/trigger、逐轴性能、连续钓鱼、冬季开放水面、索引、来源授权和 D 盘边界验证。
- 交叉审计先发现并修复 H06/H07 portal/trigger 运行查询与空尺寸索引，以及 H08 条件出口/记忆触发完整几何、逐轴性能样本、硬杂物碰撞和异常可读性问题；H04/H05 同步补齐条件 portal/trigger 全几何和运行查询。最终三组独立终审均为 MUST 0、SHOULD 0。
- H01～H08 已归一为 `maps/handoff/estate-map-pack-v1/` 主制作交接包，Pack ID `206154e890aeee3e182ac022a76abee9`；结构检查 64/64、深度检查 118/118，统一登记 582 个受控文件的绝对路径、格式、空间尺寸或文本行数、字节数、SHA-256、来源和授权。该包可由主制作对话立即读取和制定接入方案，但仍不授权正式接入、开始 P2、提交或推送。

## 当前执行点：P2 核心生活循环垂直切片

状态：H01 正式工程先导已在提交 `2c251fb0371466a4f80662c368328fee021a4121` 建立并推送独立基线。其上的农作闭环、代表性视听反馈、每日资源选择和本地保存恢复切片已实现；P2 仍未完成。

- `data/estate_maps.json` 已把 H01～H08 的稳定身份、尺寸、安全出生点和状态轴投影为强类型 `EstateMapCatalog`；只有 H01 具有正式运行场景路径。
- `EstateMapRuntime` 统一 map ID、世界边界、状态、锚点和格语义查询；H01 正式场景不依赖候选 staging 路径或泄漏的 H03 组名。
- 主场景已增加 H01 工程先导入口；composition root 按目录路径装配正式地图并注入 InputService，玩家、真实撞墙、Camera2D、状态预览和目标格查询在 128×96 正式地图上实际运行。
- Godot 4.7.1 Compatibility Renderer 已在 Intel Iris Xe / OpenGL 3.3 上捕获并检查 1280×720 画面；截图只保存在 D 盘被 Git 忽略的 `builds/verification/`。
- H01 先导接入时没有修改存档；当前保存批次已把 Godot `SaveSnapshot`/`SaveCodec` 演进为 schema v2 并加入显式 v1 provenance。portal 仍只是地图契约，不宣称跨图切换完成。
- 正式 H01 运行 payload 约 1.36 MiB，最大文件小于 1 MiB；本次不需要 Git LFS。其余七图和完整 300+ MiB 候选树不进入本基线。
- Godot 4.7.1 headless import/parse 通过；G1、G2、P1、P2 共 18 个测试文件全部 exit 0。地产 portal 可用性、空目录拒绝、平台 adapter 注入、目录驱动装配、专属状态轴扩展和真实碰撞均有回归覆盖。
- 完整入口、架构、资源边界和测试见 `docs/P2_ESTATE_MAP_PILOT.md`。
- 在纯领域层新增组合事务状态和操作专用的播种、浇水、跨天成长、成熟收获服务；失败时保持农田与背包原子不变，跨日必须按连续世界日结算。
- H01 入口现可实际完成“耕地 → 播种 → 浇水 → 连续过夜成长 → 收获入包”；八格快捷栏、键盘/手柄语义输入和程序化地块/作物占位显示已经接线。
- 初始背包只提供锄头和浇水壶；种子必须在 H01 北草甸稳定资源点通过交互获得。每日领取由纯领域事务约束，重复领取和背包满均保持原状态。
- `home_door` 已成为正式日终交互点：第一次交互请求确认，第二次才由 `DailyRestCycle` 结算当天；移动/重置/其他交互取消确认，旧 N 动作不再推进 P2 日历。
- `P2PersistentState` 现聚合世界日、玩家变换、农田/作物、背包/快捷栏、地产状态和每日领取记录；HUD 显示真实 profile/恢复/故障状态，不再错误声称“不写存档”。
- 2026-07-28 Godot 4.7.1 headless import/parse、默认 Main 和 25 个测试文件全部 exit 0；真实 E/F/N 输入链路通过。Compatibility Renderer 在 Intel Iris Xe / OpenGL 3.3 上生成并检查资源点、休息确认和农作三张 1280×720 截图。
- 文件存档/恢复和代表性动画/声音缺口已经关闭；仍缺能实际兑现的有意义玩家选择、成本/收益平衡和玩家节奏验证，因此不能作为 P2 出口。完整边界和验收记录见 `docs/P2_FARMING_LOOP.md`。
- 2026-07-28 已把外部案例中的功能区域/环路、居民可发现性、居民日程与居民知识分离、资源家族和 AI 方向参考板准入经验保存到 `docs/DESIGN_REFERENCE_LESSONS.md`，并同步领域词汇、P3/P5 路线、NPC 候选边界、资源生产、来源台账和法律护栏。只吸收抽象方法，没有复制外部图片、地图、角色、物品、数值或文本；没有修改当前 P2 功能或存档 Schema。
- 2026-07-28 完整审计用户提供的另一项目视听生产对话，只迁移 ElevenLabs 安全生产方法；没有复制其中角色、卡牌、cue、提示词或候选文件。建立 D 盘 `audio-source/p2-life-loop-v1/` 批次，使用 `eleven_text_to_sound_v2` 生成 7 cue×3 的 48 kHz stereo PCM 候选，使用 `music_v2` plan + detailed endpoint 生成 1 首 60 秒 H01 日间候选；22/22 自动门禁通过，实际延迟核销 1116 credits，超额计费关闭。
- P2 运行时现通过 `GodotAudioService` 和版本化 `data/audio_catalog.json` 播放 7 个稳定 SFX ID 与 1 个 H01 music ID；`P2InteractionFeedback` 为成功的耕地、播种、浇水、收获、采集和休息提供 Tween/自绘反馈并支持减少动态效果。Godot 4.7.1 Compatibility 在 Intel Iris Xe 上实际运行并捕获反馈画面；候选仍为 `subjectiveListeningApproval=false`、`commercialReleaseAuthorized=false`、`shippingApproval=false`，不冒充最终发行混音。
- 2026-07-29 H01 北草甸改为每日互斥资源选择组：第一次 E/A 打开、Q/Tab/肩键切换、第二次 E/A 确认“种子×3”或“雾叶×1”；组内来源共享领取键，同日不能重复取得另一项，背包失败不消耗资格，次日恢复。选择提示、状态投影、真实输入和 Compatibility Renderer 截图均有自动证据；27 个 Godot 测试文件、headless import/parse 与默认 Main 启动全部 exit 0。
- 2026-07-29 已实现 schema v2、强类型 H01 application session、D 盘开发期原子文件 adapter、current 自动保存、成功休息 protected 恢复点、current/protected 的物理 previous 候选、损坏证据隔离/只读回退和 profile-1～3 键空间隔离。pre-promote 中断会优先验证较新 rollback，current primary 无效时会在其余有效候选中选择最新世界日/保存时间，避免旧 bak 压过较新 protected。该初始保存批次提交时 Main 尚固定 profile-1；发行期 Windows/Steam/Web adapter 和旧 Cocos 导入仍未实现。专项测试覆盖 v1/v2、三档隔离、原子替换、中断状态、恢复回退、退出位置和端到端 composition root；33 个 Godot 测试文件全部 exit 0，headless editor/import、默认 Main 和 4 个 ElevenLabs pipeline Python guards 同样通过。记录见 `docs/P2_SAVE_RESTORE.md`。
- 2026-07-29 已新增数据驱动的 H01 轻量交换：雾叶×1 可在北草甸物资箱换村社券×30，村社券×20 可回购雾叶草种子×1。`TradeOfferCatalog`/`TradeBook` 与场景 Node 分离，容量失败不留下部分扣除，错误端点和未知 offer 被拒绝；H01 入口只在游戏、地产和交换目录全部有效时可用。`village_scrip` 是普通背包 material 和 P2 地方凭证假设，不是正式通用货币；通过现有 schema v2 inventory slots 保存恢复，没有修改存档 Schema。新增稳定 `sfx.trade.exchange` 暂时复用已登记音源，完整边界见 `docs/P2_LIGHTWEIGHT_ECONOMY.md`。
- 2026-07-29 H01 北草甸已改为统一四项物资箱行动牌组：当日未领取时同时显示种子、雾叶、出售和购买，领取后只保留交换；不可变 dry-run 决定 enabled/blocked 与第一项可执行行动，满背包但持有雾叶时可先出售腾出容量，交换不消耗每日资格。`AppEntryStatus`/`AppCatalogSource` 同时把 bootstrap 改为入口级隔离，交易目录故障只阻断 H01，P1 仍可启动。新增纯流程、真实输入、完整农作、持久化与确定性经济节奏回归；即时雾叶基线为 1 粒回购种子+10 券，三种子经三次浇水跨日后为 4 粒回购种子+10 券。Godot 4.7.1 全量 37/37、Python 守卫 4/4、headless import 和默认 Main 均通过。存档仍为 schema v2，地图/美术候选未接入；自动结果不替代玩家平衡验证，P2 仍未完成。
- 2026-07-29 Main 已接入三档技术管理页：只读巡检区分空档、可继续、恢复、损坏、不支持 schema、内容不兼容和读取失败；成功启动后以独立 `profile-directory` metadata v1 记录最近档，损坏的最近档保持选中并禁止启动。确认删除按 quarantine → protected → current 清理并逐键验证，取消零写入，部分失败不会谎报空档；H01 只绑定所选 profile。`SaveSnapshot` 仍为 schema v2。Godot 4.7.1 全量 40/40、Python guard 4/4、默认 Main、真实 D 盘 adapter 和 Compatibility Renderer 640×360 档位/删除画面均已验证；当前页不是最终标题美术，P2 仍未完成。
- 轻量交换批次自动回归为 35/35 个 Godot 测试文件和 4/4 个 ElevenLabs pipeline guard 全通过；Godot 4.7.1 headless editor/import 与默认 Main 也为 exit 0。新的交易界面 Compatibility 截图工具已准备，但本轮桌面图形进程被自动权限审查拒绝，未伪造为已完成视觉证据；既有 H01 Intel Iris Xe / OpenGL 3.3 截图仍作为前序渲染基线。
- 当前 P2 已有首条可兑现的卖出/回购交换和确定性自动节奏基线，但仍缺玩家验证与据此进行的成本/收益校准；村社券和北草甸数值只是可替换的 P2 假设，不冒充完整经济决策。本地保存与代表性动画/声音缺口关闭，也不等于 P2 已完成。记录见 `docs/P2_AUDIO_VISUAL_FEEDBACK.md`、`docs/P2_RESOURCE_CHOICE.md`、`docs/P2_SAVE_RESTORE.md`、`docs/P2_LIGHTWEIGHT_ECONOMY.md`。

## 后续制作阶段

正式阶段见 `docs/FULL_GAME_ROADMAP.md`。概要为 P1 体验原型、P2 核心生活循环垂直切片、P3 城镇与关系垂直切片、P4 探索与叙事垂直切片、P5 内容生产管线和质量标杆、P6 全流程 Alpha、P7 内容完成、P8 Beta、P9 Windows/Steam 发行候选。Web/微信实际开发已确认后置到 P9 之后，依次执行 W0 标准 Web、W1 微信可行性和 W2 发布决策；当前不下载模板、不安装微信插件、不承诺发布。

## 停止条件

当前正在 P2 核心生活循环垂直切片。用户已授权普通实现、独立复核和功能分支基线提交/推送继续进行；只在八地产最终产品归属、不可逆存档兼容、仓库历史覆盖或大规模 Git LFS 等重大决定上暂停确认。不得把 H01 农作闭环宣称为 P2 已完成，也不得自动把 H02～H08 全部接入正式运行时。
