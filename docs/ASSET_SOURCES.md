# 资源来源台账

本台账不仅记录旧资源迁移，也记录完整游戏后续所有新制、委托、采购和 AI 辅助资源。任何资源进入运行时 `assets/` 前都必须补齐来源、许可、修改、审核与版本信息。

## 候选资源获取与 AI 生成准入（2026-07-23）

用户允许从 itch.io 等平台寻找免费美术、配乐与其他资源，也允许用 OpenAI 图像生成或其他专用生成工具制作候选。这里的“免费”只表示获取价格，不自动代表可商用、可修改或可再分发；每个外部候选都必须逐项保存原始页面 URL、作者/发布者、资源版本、下载日期、原始文件名与尺寸、SHA-256、完整许可文本或许可页面快照、署名要求，以及商用/修改/再分发结论。许可不清、仅限个人使用、禁止修改或来源无法复核的资源不得进入运行时 `assets/`。

所有下载、解压、中间文件和生成结果只放在 D 盘的独立候选目录，默认 `shippingApproval=false`，不得覆盖正式资源。AI 图像须记录工具/模型、提示、输入参考、生成日期、尺寸和后处理；作为 32×32 地图资源时仍需原生像素重构、相似性与授权复核、Tiled 实铺和 Godot 验收。当前地图对话只生产地图与地图美术；音乐/音效若需使用本环境无法直接调用的工具，应另行给出用户可执行的生成与导出步骤，并在实际文件进入项目前补齐同等级来源台账。

## 外部设计参考，不是项目资源（2026-07-28）

本项目只分析了三条公开小红书笔记的抽象方法：商业游戏区域路线组织、居民位置/送礼攻略的可发现性问题，以及 AI 森林冒险资源总表的生产规划方式。原帖标题、链接、用途和禁止复制边界记录在 `DESIGN_REFERENCE_LESSONS.md`。

没有把帖子图片、商业游戏截图、地图、角色、物品、数值、文本、UI 或 AI 资源复制到仓库；没有取得这些内容的项目使用授权，也没有把它们登记为候选或运行时资产。以后若为核对参考而临时缓存页面或图片，只能使用 D 盘临时目录并在分析后清理，不能进入 `art-source/`、`assets/` 或发行构建。

## G1 运行时资源

无。`assets/art`、`assets/audio`、`assets/effects`、`assets/fonts` 只有目录占位。`data/runtime_resources.json` 的 `godotPath` 全部为 null。

## P1 程序化原型资源（2026-07-20）

P1 没有复制旧素材，也没有引入外部二进制资源。地形、道路、水边、建筑轮廓、玩家、交互标记、前景遮挡、雾带和调试网格由仓库内原创 GDScript 在运行时绘制；环境循环、脚步和交互提示音由 `p1_prototype_audio.gd` 确定性生成 16-bit mono WAV 数据并仅保存在内存。

来源/作者：本项目 P1 实现；第三方来源：无；外部模型/素材：无；许可风险：无外来许可；状态：仅用于体验验证，不是正式美术或正式音频。代码位置：`scripts/gameplay/prototypes/`、`scripts/gameplay/player/p1_player_controller.gd`。自动审核截图位于被 Git 忽略的 `.godot/qa/`，可由 `tools/capture_p1_visual.gd` 重建，不是项目资源的唯一副本。

## 可在后续适配的旧测试资源

旧 `mvp_farm_ground.png` 和 `mvp_farm_stone.png` 是 2026-07-14 由项目内 Node 标准库脚本确定性生成的 32×32 RGBA 原创几何瓦片；旧台账含 SHA-256。`mvp_farm.tmx` 是 Tiled 1.12.2 导出的原创最小测试图。这三项只可作为 P1 坐标/碰撞验证的候选 fixture，当前未复制，也不是正式地图美术；P1 可以直接制作更符合新体验命题的灰盒。

## H03 正式环境美术方向候选（2026-07-22）

`art-source/maps/h03-forest-hollow/formal-tiles/candidates/batch-001/` 保存三张 H03 正式 TileSet 方向母版：A 雾泉青灰、B 暖土旧垦、C 冷苔石渠。来源为 OpenAI built-in `image_gen`，输入仅包含本项目已有 H03 概念图和已确认灰盒图；没有使用第三方、网络、商业游戏或旧 Cocos 像素。提示、SHA-256、尺寸和授权边界见同目录上级的 `H03_TILE_DIRECTION_PROMPTS_BATCH_001.md` 与 `H03_FORMAL_TILE_ASSET_RECORD.json`。

三张图均为 1254×1254 PNG 方向候选，不符合 32×32 图集对齐与 Tiled Terrain 技术要求，`shippingApproval` 为 false。必须经用户选择、人工 32px 重构、相似性检查、当时适用的 OpenAI 条款复核及 Tiled/Godot 场景验收后，才可能形成运行时资源。

## H03 混合资源母版候选（2026-07-22）

用户确认采用 A/B/C 混合方式后，`art-source/maps/h03-forest-hollow/formal-tiles/candidates/batch-002-hybrid/` 生成五个资源家族：地面/耕地/道路，水域/岸线/悬崖/桥，植被/荒废杂物/围栏，亲切易读型建筑/遗迹，以及低矮偏置型架空建筑备选。来源为 OpenAI built-in `image_gen`，仅引用本项目 Batch 001 候选；没有使用第三方、网络、商业游戏或旧 Cocos 像素。

共 8 个 PNG：3 个 RGB 母版、2 个色键建筑母版、3 个 RGBA 透明输出；尺寸为 1254×1254 或 1536×1024。色键源图和透明结果同时保留，以便追溯。精确路径、格式、字节数、SHA-256、提示和授权边界见 `H03_TILE_HYBRID_ASSET_RECORD.json`、`H03_TILE_HYBRID_PROMPTS_BATCH_002.md`。全部为内部选型/人工重构参考，`shippingApproval=false`，尚未接入 Tiled、Godot 或 `assets/`。

## H03 原生 32px 技术美术候选（2026-07-22）

`art-source/maps/h03-forest-hollow/formal-tiles/candidates/batch-003-native32/` 保存 H03 的原生 32px 技术美术切片。纠偏参考图由 OpenAI built-in `image_gen` 根据项目内 Batch 002 候选生成；最终地形、对象和建筑 PNG 则由项目内确定性 Pillow 脚本在原生网格重新绘制，没有裁切或复制参考图、第三方资源、旧 Cocos 像素。

运行候选包含 512×512 RGBA 地形图集、512×512 RGBA 对象图集和 1024×512 RGBA 建筑图集，以及 Tiled 1.12.2 TSX/TMX、六张 640×360 视口图和 Wang 全组合矩阵。水域碰撞由隐藏掩码而非视觉瓦片承载，桥面格已从水域碰撞排除。自动检查 137/137 通过。详细提示、尺寸、字节数、SHA-256 和授权边界见同目录 `H03_NATIVE32_PROMPT.md`、`H03_NATIVE32_ASSET_RECORD.json`、`H03_NATIVE32_VALIDATION.json`。状态仍为技术美术候选，`shippingApproval=false`，尚未进入 `assets/` 或 Godot。

用户确认 Batch 003 视觉方向后，`batch-003-native32/full-map/` 生成 128×96 春季荒废与建设后完整候选副本。它们只复用项目自有 H03 v2.1 布局语义和项目内原生 32px 图集，没有覆盖权威灰盒。两张完整 TMX 及九张预览由 D 盘 Tiled 实际渲染，98/98 项全图检查通过；来源、授权、尺寸和 SHA-256 见 `H03_FULL_SPRING_ASSET_RECORD.json`、`H03_FULL_SPRING_VALIDATION.json`。`shippingApproval=false`，未接入 Godot。

## H03 春季正式美术细化候选（2026-07-22）

用户确认 Batch 003 完整春季地图的宏观布局与原生 32px 技术方向后，`art-source/maps/h03-forest-hollow/formal-tiles/candidates/batch-004-spring-detail/` 生成独立的春季细化候选。运行图集包括 512×512 RGBA 地形、512×512 RGBA 对象和 1024×512 RGBA 建筑 PNG，以及三个 TSX、两张 128×96 TMX 和多尺度审阅图。它们由项目内确定性 Pillow 脚本在 32px 网格重新绘制，没有复制第三方、商业游戏、旧 Cocos 或 AI 参考图像素。

本批另有一张 1536×1024 RGB 方向参考板，来源为 OpenAI built-in `image_gen`，输入仅为项目自有 Batch 003 全图与住宅预览；只授权项目内部方向参考，未进入运行图集。提示、绝对路径、尺寸、字节数、SHA-256 和完整边界见 `H03_SPRING_DETAIL_PROMPT.md`、`H03_SPRING_DETAIL_ASSET_RECORD.json`、`H03_SPRING_DETAIL_VALIDATION.json`；地图语义逐项清单见 `H03_SPRING_DETAIL_MAP_MANIFEST.json`。D 盘 Tiled 实际栅格化和 150/150 项检查通过。用户已于 2026-07-22 确认该春季细化视觉可作为四季与异常候选的生产基准；`shippingApproval=false`，尚未进入 `assets/` 或 Godot。

## H03 四季与轻/中度异常候选（2026-07-22）

`art-source/maps/h03-forest-hollow/formal-tiles/candidates/batch-005-seasons-anomaly/` 保存从用户已确认 Batch 004 派生的四季与异常候选：四季各有 512×512 RGBA 地形、512×512 RGBA 对象、1024×512 RGBA 建筑图集和对应 TSX；轻度/中度异常也各有同尺寸的三类专用图集与 TSX；另有春夏秋冬×荒废/建设后八张 128×96 TMX，以及春季建设后轻度/中度异常两张 TMX。春季运行像素保持 Batch 004；夏秋冬和异常运行图集均由项目内确定性 Pillow 管线在原生 32px 网格调色并追加像素簇，没有复制第三方、商业游戏、旧 Cocos 或 AI 参考图像素。

冬季使用连接掩码积雪变体在原 Ground 占用格内形成局部连续雪区；本轮降低积雪亮度、缩小雪区并增加裸地纹理，水体 514 格、桥面 84 格和水域碰撞 430 格不变，水面保持开放可钓。用户指出第一版异常对比不清晰后，第二版改用常态/轻度/中度独立图集状态，并沿溪流、北部泉眼和旧石渠使用有间断的定向雾、错误阴影与局部青色裂光替换层；出生点、出口、NPC、交互、剧情、遮挡、可耕/可建、碰撞及全部对象层保持。10 张 TMX 已由 D 盘 Tiled 实际栅格化，住宅、溪流、北部泉眼和全图的异常像素差异均设有可读性门槛，764/764 项检查通过。

本批有两张 OpenAI built-in `image_gen` 内部方向参考：1774×887 RGB 六分区四季/初版异常方向板，以及针对异常可读性修正的 1774×887 RGB 常态/轻度/中度三分区方向板。输入均为项目自有资源；两张参考都未进入运行图集，生成工具落在 C 盘的确切临时原件已在复制到 D 盘后删除。精确提示、绝对路径、格式、尺寸、字节数、SHA-256、地图清单和授权边界见 `H03_SEASONS_ANOMALY_PROMPT.md`、`H03_SEASONS_ANOMALY_ASSET_RECORD.json`、`H03_SEASONS_ANOMALY_MAP_MANIFEST.json`、`H03_SEASONS_ANOMALY_FILE_INDEX.md` 与 `H03_SEASONS_ANOMALY_VALIDATION.json`。当前状态为 `seasonal_anomaly_candidate_for_visual_review`，`shippingApproval=false`，尚未进入 `assets/` 或 Godot。

## H03 可组合季节/发展/异常状态候选（2026-07-22）

`art-source/maps/h03-forest-hollow/formal-tiles/candidates/batch-006-composable-states/` 修正 Batch 005 的状态耦合：季节、地产发展和异常现在是三个正交轴；目录只含一张权威 128×96 TMX，14 张状态组合 TMX 均标记为非权威审阅派生物。四季运行候选继续使用 Batch 005 的项目自有确定性原生 32px 像素；轻/中度异常不再复制整套季节图集，而是共用一张由项目内 Pillow 脚本绘制的 512×256 RGBA 增量图集，并通过 `AnomalyStateAnchor` 记录住宅窗、旧石渠、泉眼石块、溪岸和树影等 7 个稳定对象状态锚点。

异常运行像素没有复制 OpenAI 方向参考、第三方游戏、旧 Cocos 或网络资源。Batch 005 的 1774×887 OpenAI `image_gen` 异常方向板仅作为内部方向参考，像素未进入图集；中文审阅图只读取 Windows 自带 Microsoft YaHei 字体进行标签栅格化，字体文件未复制进项目，也不属于运行时资源。轻/中度对象裂光不占用 Water 层，水域碰撞、可钓逻辑、权威掩码、对象层和几何均保持。D 盘 Tiled 实际栅格化与 335/335 项自动检查通过。完整绝对路径、格式、尺寸、SHA-256、来源和授权见 `H03_COMPOSABLE_STATES_ASSET_RECORD.json`、`H03_COMPOSABLE_STATES_MAP_MANIFEST.json`、`H03_COMPOSABLE_STATES_FILE_INDEX.md` 与 `H03_COMPOSABLE_STATES_VALIDATION.json`。当前状态为 `composable_state_candidate_for_visual_review`，`shippingApproval=false`，尚未进入 `assets/` 或 Godot。

## H03 冬季柔化与权威季节层候选（2026-07-22）

`art-source/maps/h03-forest-hollow/formal-tiles/candidates/batch-007-winter-polish/` 从项目自有 Batch 006 派生。非冬季图集和异常增量 PNG 保持原像素；冬季地形、对象与建筑只由项目内确定性 Pillow 管线重新组织原生 32px 雪色、连接掩码和裸地簇，没有复制第三方游戏、旧 Cocos、网络素材或 AI 参考像素。冬季积雪从三块高亮大椭圆调整为多个较小的组合雪簇，降低亮度并去除规则斜向网纹。

权威 TMX 新增 `Season_Winter_Ground` 隐藏完整替换层；冬季状态不再依赖非权威派生 TMX 保存 Ground 变体。17 张审阅 TMX 覆盖原四季/发展/异常代表组合，并完整补齐冬季荒废/建设后×常态/轻度/中度矩阵。D 盘 Tiled 实际栅格化与 284/284 项结构、像素差异、语义保持、来源和磁盘边界检查通过。完整绝对路径、格式、尺寸、SHA-256、来源和授权见 `H03_WINTER_POLISH_ASSET_RECORD.json`、`H03_WINTER_POLISH_MAP_MANIFEST.json`、`H03_WINTER_POLISH_FILE_INDEX.md` 与 `H03_WINTER_POLISH_VALIDATION.json`。用户于 2026-07-23 确认本批可冻结为其余地产的生产与验证标杆，状态为 `h03_estate_pipeline_benchmark_approved`；批准边界另见 `H03_PIPELINE_BENCHMARK_APPROVAL.json`。`shippingApproval=false`，尚未进入 `assets/` 或 Godot。

## H02 辫河洲地技术布局候选（2026-07-23）

`art-source/maps/h02-braided-river/candidates/batch-001-layout/` 是 H03 标杆复用后的首张地产压力测试。地图为 144×104、32px，即 4608×3328 px；目录含一张权威 TMX、五张可重复生成的春季审阅 TMX、四套本地 TSX/PNG、原尺寸与 640×360 视口预览、中文标注图、manifest、文件索引、设计/交付记录和自动校验。桥、后期 crossing 与剧情高水位均使用明确的碰撞/可钓水域处置契约。8 个 FishingAccessQA 点均为常态/高水位下可达、无碰撞且四邻存在可钓水域的验证点，验证后丢弃。Tiled 1.12.2 在 D 盘实际栅格化，436/436 项尺寸、图层、对象、掩码、开局通行、桥状态、高水位、钓鱼 QA、来源和磁盘边界检查通过；独立最终复审为 MUST=0、SHOULD=0。

H02 的 AI 概念图仅用于内部构图和地域特征参考，像素没有进入图集。布局审阅阶段临时复制项目自有 H03 Batch 007 原生 32px 候选作为共享视觉语言；H02 新增的横/竖浅滩、芦苇、河道标杆、漂木、水尺、码头板和水闸标记由本批确定性 Pillow 脚本绘制，没有复制第三方、商业游戏、旧 Cocos、网络或 AI 参考像素。精确绝对路径、格式、尺寸、字节数、SHA-256 与授权边界见 `H02_LAYOUT_ASSET_RECORD.json` 和 `H02_LAYOUT_FILE_INDEX.md`。当前状态为 `independent_review_passed_pending_user_layout_approval`；四季专属资源、异常资源和 Godot 接入均未开始，`shippingApproval=false`。

## H01 开阔草甸技术布局候选（2026-07-23）

`art-source/maps/h01-open-meadow/candidates/batch-001-layout/` 保存 128×96、32px（4096×3072 px）的开阔草甸技术布局：一张权威 TMX、两张春季荒废/建设后审阅 TMX、四套本地 TSX/PNG、全图与 640×360 视口预览、中文标注图、manifest、Godot 交接契约、来源记录和文件索引。所有无水域、道路、固定物或系统安全冲突的空地进入可耕候选；开局杂物以连续概率分布。水域保持单连通与连续可钓，成熟期 crossing 同时移除碰撞、可钓资格和生态归属；南侧条件出口的碰撞和石障视觉绑定同一 stable lock。D 盘 Tiled 实际栅格化和 278/278 项检查通过；独立最终复审为 MUST=0、SHOULD=0。

H01 概念图只作为中后期容量与开阔草甸方向参考，像素没有进入图集。当前共享项目自有 H03 Batch 007 的原生 32px 视觉语言，布局与 H01 新增内容由本批确定性 Python/Tiled 管线生成，没有复制第三方、商业游戏、旧 Cocos、网络或 AI 参考像素。37 个文件的绝对路径、格式、尺寸、字节数、SHA-256 与授权边界见 `H01_LAYOUT_ASSET_RECORD.json` 和 `H01_LAYOUT_FILE_INDEX.md`。H01 专属风草、野花、水岸、四季与异常美术仍待正式批次；未接入 Godot，`shippingApproval=false`。

## H03 Godot 4.7.1 隔离运行候选（2026-07-23）

`maps/candidates/h03-runtime-staging-v1/` 从获批 H03 Batch 007 权威 TMX 派生春季×荒废×常态的隔离 Godot 候选，包含 `.tscn`、`.tres`、语义 JSON、候选专用 `project.godot`、导入后的 PNG 元数据和验证记录。地图为 128×96、32px，即 4096×3072 px；11 个可见视觉层、6 个隐藏语义层、15 个对象组与 84 个对象完成逐格/逐对象核对。Godot 4.7.1 的 import/build/verify/scene-load 全部 exit 0，208/208 项检查与独立复审通过；构建 ID 为 `834607fb9bda4dcf89d2eb327cad5939`。

本候选像素来自项目自制的确定性 native-32px Batch 007，没有复制第三方、商业游戏、旧 Cocos、网络资源或 AI 方向参考像素。32 个交付文件的绝对路径、格式、尺寸、字节数、SHA-256 和授权边界见 `H03_RUNTIME_STAGING_ASSET_RECORD.json` 与 `H03_RUNTIME_STAGING_FILE_INDEX.json`。它没有进入正式 `assets/`，也未连接正式玩家、摄像机、耕作、建造、钓鱼、NPC、剧情、portal、存档或状态切换系统；`runtimeIntegrated=false`、`shippingApproval=false`。

## H03 Godot 4.7.1 全状态隔离运行候选 v2（2026-07-23）

`maps/candidates/h03-runtime-staging-v2/` 从获批 H03 Batch 007 权威 TMX 派生 128×96、32px（4096×3072 px）的全状态隔离候选。它以一张 PackedScene `.tscn`、四套季节视觉 TileSet `.tres` 和一套逻辑 TileSet `.tres` 承载春夏秋冬×荒废/建设后×常态/轻度/中度异常共 24 种组合；18 个视觉 TileMapLayer、6 个运行逻辑掩码、7 个仅编辑器/元数据语义层，以及 15 个源对象组的 84 个对象完成处置，其中 5 个 FishingAccessQA 点在验证后丢弃，留下 79 个稳定运行对象。最终 fresh run `37e6cd5bb3ee43a79fc0f74794e0118b` 的转换预检为 28/28、Godot 4.7.1 动态验证为 354/354、24/24 状态通过，import/build/异常差异/verify/scene-load 五条命令均 exit 0。Physics2D 查询验证了荒废杂物碰撞的移除与恢复、永久碰撞保持；100 次状态切换 p95 为 9.241 ms、最大 12.909 ms，节点、对象和资源数无增长。受控运行 payload 为 10.307613 MiB。

运行像素包括 13 个项目自制确定性 native-32px Batch 007 来源 PNG、13 个对应 TSX，以及一张本管线生成的 192×32 RGBA 逻辑 PNG；季节地形/对象图集为 512×512、建筑图集为 1024×512，异常增量图集为 512×256。没有嵌入第三方、商业游戏、旧 Cocos、网络或 AI 方向参考像素。候选共 73 个文件，其中 72 个受文件索引控制；37 项来源绑定的字节数和 SHA-256 全部复核通过，完整绝对路径、格式、尺寸、授权和哈希见 `H03_RUNTIME_STAGING_ASSET_RECORD.json` 与 `H03_RUNTIME_STAGING_FILE_INDEX.json`。授权仅限项目内部候选生产与管线复用，`runtimeIntegrated=false`、`shippingApproval=false`。它尚未连接正式玩家、摄像机、耕作、建造、钓鱼、NPC、剧情、portal、世界地图、存档或运行时服务，portal 目标仍为 `pending_*`；“建设后”目前只是清场与技术建成态。headless 验证提供运行时图层、格数和 TileSet 指纹差异，没有生成 bitmap 视觉截图，也未测量真实 640×360/1920×1080 渲染帧时。

## H01 Godot 4.7.1 隔离运行候选（2026-07-23）

`maps/candidates/h01-runtime-staging-v1/` 从 H01 Batch 001 权威 TMX 派生春季×荒废×常态的隔离 Godot 候选，包含 Godot PackedScene `.tscn`、TileSet `.tres`、语义 JSON、候选专用 `project.godot`、四套 PNG/TSX 的本地副本、验证脚本与日志。地图为 128×96、32px，即 4096×3072 px；13 个视觉 TileMapLayer、9 个隐藏语义 TileMapLayer、15 个运行对象组与 62 个运行对象完成逐格/逐对象核对。最终 fresh run `2b54645d90404e0696b3ad785e216534` 的转换预检为 144/144，Godot 4.7.1 import/build/verify/scene-load 全部 exit 0，运行验证为 239/239。

H01 的像素来自项目自制确定性 native-32px Batch 001 候选，并临时共享项目自有 H03 地产视觉语言；概念图、第三方游戏、旧 Cocos、网络或 AI 方向参考像素均未嵌入。TMX、layout validation、asset record、map manifest、Godot handoff、共享 disposition contract、H01 profile、8 个 PNG/TSX 与两级转换器共 17 项来源/运行绑定全部通过。31 个受控文件加文件索引本身的绝对路径、格式、尺寸、字节数和 SHA-256 见 `H01_RUNTIME_STAGING_FILE_INDEX.json`，来源与授权见 `H01_RUNTIME_STAGING_ASSET_RECORD.json`；`.godot` 仅为可重建导入缓存，不计入交付索引。授权仅限项目内部 runtime-staging 候选；`runtimeIntegrated=false`、`shippingApproval=false`。

## H01 Godot 4.7.1 全状态隔离运行候选 v2（2026-07-23）

`maps/candidates/h01-runtime-staging-v2/` 将 H01 Batch 001 扩展为 128×96、32px（4096×3072 px）的全状态隔离候选。一张 PackedScene `.tscn` 动态承载春夏秋冬×荒废/复垦/扩建/成熟×常态/轻度/中度异常共 48 种组合；35 个源 TileLayer 中 31 个进入运行时、4 个仅作元数据，16 个源对象组的 66 个对象中 62 个进入运行时、4 个 FishingAccessQA 点验证后丢弃。最终 fresh run `940c740ec29148378aa5cd9c5654e480` 的转换预检为 17/17、Godot 4.7.1 动态验证为 243/243、48/48 状态通过，import/build/anomaly-delta/verify/direct-load 五条命令均 exit 0。真实 Physics2D 查询确认 crossing 与荒废杂物均按 `1→0→1` 移除和恢复；100 次状态切换 p95 为 5.252 ms、最大 5.821 ms，节点、资源和对象无增长。全状态审阅图为 2048×1236 PNG，异常锚点近景对照为 1440×1182 PNG；独立终审为 MUST 0、SHOULD 0。

春季 terrain/objects/logic 来自项目自制 H01 Batch 001，夏秋冬 terrain/objects 是其确定性项目内派生；architecture 与 anomaly atlas 共享项目自有 H03 资源。概念图、第三方游戏、旧 Cocos、网络或 AI 方向参考像素均未嵌入。28 项运行瓦片资产（14 PNG＋14 TSX）的来源、授权、格式、尺寸和 SHA-256 见 `H01_RUNTIME_STAGING_ASSET_RECORD.json`；78 个受控文件的绝对路径、格式、尺寸、字节数和 SHA-256 见 `H01_RUNTIME_STAGING_FILE_INDEX.json`，加索引本身共 79 个交付文件。授权仅限项目内部候选生产，`runtimeIntegrated=false`、`shippingApproval=false`。复垦、扩建和成熟状态仍含技术占位，不是正式建筑美术；候选尚未连接正式玩家、摄像机、季节服务、耕作、建造、钓鱼、NPC、剧情、跨图控制或存档。

## H02 Godot 4.7.1 隔离运行候选（2026-07-23）

`maps/candidates/h02-runtime-staging-v1/` 从 H02 Batch 001 权威 TMX 派生春季×荒废×常态水位×东/北桥关闭状态的隔离 Godot 候选，包含 Godot PackedScene `.tscn`、TileSet `.tres`、语义 JSON、候选专用 `project.godot`、四套 PNG/TSX 的本地副本、验证脚本与日志。地图为 144×104、32px，即 4608×3328 px；40 个运行 TileMapLayer、1 个 metadata-only 高水位汇总层、17 个源对象组、49 个运行语义节点与 9 个 StaticBody2D 完成核对。最终 fresh run `712cd15fe33d41dd9dbb4e82159cf657` 的转换预检为 46/46，Godot 4.7.1 import/build/verify/scene-load 全部 exit 0，运行验证为 357/357。

H02 的像素来自项目自制确定性 native-32px Batch 001 候选；概念图、第三方游戏、旧 Cocos、网络或 AI 方向参考像素均未嵌入。TMX、layout validation、asset record、map manifest、Godot handoff、共享 disposition contract、H02 profile、8 个 PNG/TSX 与两级转换器共 17 项来源/运行绑定全部通过。31 个受控文件加文件索引本身的绝对路径、格式、尺寸、字节数和 SHA-256 见 `H02_RUNTIME_STAGING_FILE_INDEX.json`，来源与授权见 `H02_RUNTIME_STAGING_ASSET_RECORD.json`；`.godot` 仅为可重建导入缓存，不计入交付索引。临时 `.tooling`、`.godot-user` 和四个 Godot 用户根目录在构建后自动清除。授权仅限项目内部 runtime-staging 候选；`runtimeIntegrated=false`、`shippingApproval=false`。

## H02 Godot 4.7.1 六轴全状态隔离运行候选 v2（2026-07-23）

`maps/candidates/h02-runtime-staging-v2/` 将 H02 Batch 001 扩展为 144×104、32px（4608×3328 px）的六轴全状态隔离候选。一张 PackedScene `.tscn` 动态承载春夏秋冬×荒废/复垦/扩建/成熟×常态/轻度/中度异常×常态/高水位×东桥关闭/开启×北桥关闭/开启共 384 种组合；41 个源 TileLayer 中 40 个进入运行时、1 个仅作元数据，17 个源对象组最终形成 49 个运行语义对象，8 个 FishingAccessQA 点验证后丢弃。最终 fresh run `8b8c4c6dfaba466ebcbf214aefaedd34` 的转换预检为 66/66、Godot 4.7.1 动态验证为 816/816，384 正序、384 逆序与 100 次确定性状态序列全部通过；import/build/verify/direct-load 四条命令均 exit 0。真实 Physics2D 查询确认荒废杂物按 `1→0→1` 切换，水位和双桥同步更新水域碰撞、可钓权威与通行；运行格计数为 52203 个源包含格＋1076 个季节/异常生成格＝53279。全状态 p95 为 14.464 ms，水位 p95 为 14.909 ms，东桥、北桥、发展与异常等即时轴 p95 均低于 5 ms；季节切换 p95 为 70.366 ms，因此正式接入时必须限定在睡眠、换季、地图载入或淡入淡出等过渡边界。1368×2212 PNG 审阅图覆盖六轴、异常三联、水位与双桥局部对照；独立终审为 MUST 0、SHOULD 0。

运行像素以项目自制 H02 Batch 001 为基础，季节色彩参考和共享异常资源来自项目自有 H03 Batch 007，其余 H02 新增像素由确定性项目内管线派生；概念图、第三方游戏、旧 Cocos、网络或 AI 方向参考像素均未嵌入。28 项生成/复制运行资产及 49 项来源绑定的格式、尺寸、授权和 SHA-256 见 `H02_RUNTIME_STAGING_ASSET_RECORD.json`；72 个受控文件的绝对路径、格式、尺寸、字节数和 SHA-256 见 `H02_RUNTIME_STAGING_FILE_INDEX.json`，加索引本身共 73 个交付文件。受控运行 payload 为 8.420443 MiB。授权仅限项目内部候选生产，`runtimeIntegrated=false`、`shippingApproval=false`。复垦、扩建和成熟状态仍是技术占位；候选尚未连接正式玩家、摄像机、季节服务、耕作、建造、钓鱼、NPC、剧情、跨图控制或存档。

## H04～H08 全状态地产候选与统一交接（2026-07-24）

H04 山地梯田、H05 芦苇湿地、H06 石质高地、H07 湖畔半岛和 H08 旧果园遗址均已形成独立 Tiled 权威源与 Godot 4.7.1 隔离运行候选。权威源分别位于 `art-source/maps/h04-hillside-terraces/`、`h05-reed-wetland/`、`h06-stone-upland/`、`h07-lake-peninsula/` 与 `h08-old-orchard-ruins/`；运行候选分别位于 `maps/candidates/h04-runtime-staging-v1/` 至 `h08-runtime-staging-v1/`。基础瓦片均为 32×32；地图尺寸依次为 128×112、144×104、128×96、144×96、128×96。

五图运行像素、Tiled 图层、审阅图、语义 JSON、Godot 候选场景和验证记录均由项目内确定性生产管线新制或从本项目已登记的 H02/H03 原生 32px 视觉语言派生。没有复制第三方游戏、旧 Cocos、网络下载或 AI 方向参考像素；本批没有新增 itch.io 或其他第三方运行资源。H04/H05 使用的 H02 项目自有 donor 项均保存哈希链；H06/H07/H08 的详细派生关系、尺寸、SHA-256 与授权分别记录在各候选根的 `*_RUNTIME_STAGING_ASSET_RECORD.json` 和 `*_RUNTIME_STAGING_FILE_INDEX.json`。授权仅限项目内部候选生产与接入规划，`runtimeIntegrated=false`、`shippingApproval=false`。

统一交接目录 `maps/handoff/estate-map-pack-v1/` 的 `ESTATE_MAP_PACK_CONTROLLED_FILES.json` 归一记录 H01～H08 共 582 个受控文件的绝对路径、格式、空间尺寸或非空间文本行数、字节数、SHA-256、来源与授权；`ESTATE_MAP_PACK_AUDIT.json` 记录三组独立交叉审计和修复闭环，最终 MUST 0、SHOULD 0；`ESTATE_MAP_PACK_DEEP_VALIDATION.json` 为 118/118。交接包没有把候选复制进正式 `assets/`，也没有授予发行许可。

## 阻塞资源

旧视觉候选约 298.57 MiB，来源/确认记录完整但现有 AI 图未完成商业清权、人工重构和运行时验收。任何文件都不允许直接导入 Godot `assets`。没有最终发行已确认的音乐、音效或字体；P2 已有一组内部运行候选，边界见下节。

## P2 ElevenLabs 代表性音频候选（2026-07-28）

`audio-source/p2-life-loop-v1/` 保存项目专用 jobs、一次性授权、执行 grant、music_v2 composition plan、21 个 SFX 原始候选、21 个仅加容器头的审阅 WAV、1 个音乐候选、供应商详细响应、逐请求 ledger、SHA-256、技术 QA、运行选择与延迟用量核销。没有复制用户参考文件中另一个游戏的 cue、提示词或音频。

- 供应商：ElevenLabs；生成时账户：Creator active；超额计费关闭。
- SFX：`eleven_text_to_sound_v2`、`pcm_48000`、48 kHz、16-bit、stereo；7 cue × a/b/c。
- 音乐：`music_v2`；先调用零 credit plan，再由 `/v1/music/detailed` 生成唯一 60 秒 `mp3_48000_192` 候选。
- 实际延迟核销：全批 1116 credits，其中 SFX 291、music 825。
- 运行时：7 个选中 WAV 与 1 个 MP3 复制到 `assets/audio/p2/`，总计 3,122,849 bytes，最大文件 1,440,621 bytes；不需要 Git LFS。
- 来源证据：API request/trace/song ID、提示、参数、模型、时间、输出哈希和官方接口 URL 均已登记；API key 未写入仓库。
- 授权状态：付费计划生成内容具备供应商所述商业使用基础，但本项目仍保守标记 `commercialReleaseAuthorized=false`、`shippingApproval=false`，等待最终听感、相似性、条款与发行混音复核。

完整生产与接入事实见 `docs/P2_AUDIO_VISUAL_FEEDBACK.md`。

## H01 正式工程先导运行资源（2026-07-24）

H01 正式工程先导从唯一输入 `maps/handoff/estate-map-pack-v1/` 指向的 `h01-runtime-staging-v2` 候选派生。正式运行位置为 `assets/art/maps/estate/h01/`、`maps/runtime/estate/h01/` 和 `scenes/world/estate/h01_open_meadow.tscn`；包含 14 张 PNG、5 个 TileSet `.tres` 和 1 个正式场景。运行 payload 合计 1,427,275 bytes，最大单文件 742,127 bytes，不需要在本基线启用 Git LFS。

14 张正式 PNG 与候选同名文件逐一 SHA-256 相同。春季 terrain/objects/logic 来自项目自制 H01 Batch 001；夏秋冬 terrain/objects 为项目内确定性派生；architecture 与 anomaly atlas 沿用已登记的项目自有 H03 资源。没有新增第三方游戏、旧 Cocos、网络下载或来源不明像素。正式 `.tres`/`.tscn` 只改写资源路径、脚本绑定和候选组名，不覆盖候选文件。

本次 `runtimeIntegrated=true` 只表示 H01 已进入正式工程并通过运行测试；它不改变原候选、复垦/扩建/成熟技术占位和整体美术的 `shippingApproval=false`。本轮也没有把其余 H02～H08 像素复制进正式 `assets/`。
