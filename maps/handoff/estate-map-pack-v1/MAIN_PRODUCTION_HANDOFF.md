# 《雾乡如昨》H01–H08 玩家地产主制作交接

本交接包把八种玩家可选地产的 Tiled 权威源、Godot 隔离场景、状态契约、出生点/出口、验证和授权索引归一为单一入口。它授权主制作对话读取和规划接入，不代表已写入正式工程。

- Pack ID：`206154e890aeee3e182ac022a76abee9`
- 统一验证：64/64
- 基础瓦片：32×32 px
- 逻辑画面：640×360；目标输出缩放由正式工程接入阶段验证
- `runtimeIntegrated=false`、`shippingApproval=false`
- 全部源文件、候选、日志、缓存与交接产物均限定在 D 盘

## 地图清单

| ID | 地图 | 尺寸（格） | 状态组合 | Godot 检查 | 运行场景 | 文件/授权索引 |
|---|---|---:|---:|---:|---|---|
| H01 | 开阔草甸 | 128×96 | 48 | 243/243 | [候选场景](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h01-runtime-staging-v2/runtime/h01_state_ready.tscn) | [完整索引](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h01-runtime-staging-v2/H01_RUNTIME_STAGING_FILE_INDEX.json) |
| H02 | 辫河洲地 | 144×104 | 384 | 816/816 | [候选场景](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h02-runtime-staging-v2/runtime/h02_state_ready.tscn) | [完整索引](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h02-runtime-staging-v2/H02_RUNTIME_STAGING_FILE_INDEX.json) |
| H03 | 林间洼地 | 128×96 | 24 | 354/354 | [候选场景](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h03-runtime-staging-v2/runtime/h03_state_ready.tscn) | [完整索引](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h03-runtime-staging-v2/H03_RUNTIME_STAGING_FILE_INDEX.json) |
| H04 | 山地梯田 | 128×112 | 192 | 31/31 | [候选场景](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h04-runtime-staging-v1/runtime/h04_state_ready.tscn) | [完整索引](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h04-runtime-staging-v1/H04_RUNTIME_STAGING_FILE_INDEX.json) |
| H05 | 芦苇湿地 | 144×104 | 384 | 39/39 | [候选场景](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h05-runtime-staging-v1/runtime/h05_state_ready.tscn) | [完整索引](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h05-runtime-staging-v1/H05_RUNTIME_STAGING_FILE_INDEX.json) |
| H06 | 石质高地 | 128×96 | 192 | 540/540 | [候选场景](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h06-runtime-staging-v1/runtime/h06_state_ready.tscn) | [完整索引](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h06-runtime-staging-v1/H06_RUNTIME_STAGING_FILE_INDEX.json) |
| H07 | 湖畔半岛 | 144×96 | 192 | 540/540 | [候选场景](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h07-runtime-staging-v1/runtime/h07_state_ready.tscn) | [完整索引](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h07-runtime-staging-v1/H07_RUNTIME_STAGING_FILE_INDEX.json) |
| H08 | 旧果园遗址 | 128×96 | 192 | 574/574 | [候选场景](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h08-runtime-staging-v1/runtime/h08_state_ready.tscn) | [完整索引](D:/lzq/AI游戏/WuxiangRuzuo-Godot/maps/candidates/h08-runtime-staging-v1/H08_RUNTIME_STAGING_FILE_INDEX.json) |

## 主制作读取顺序

1. 先读取本目录 `ESTATE_MAP_PACK_HANDOFF.json`，选择稳定 `map_id`。
2. 从对应地图的 `object_contract` 读取安全出生点、入口、NPC、交互和剧情锚点。
3. 从 `state_axes` 和候选 `state_catalog` 建立运行时状态适配；不要硬编码 Godot source ID。
4. 以 `authoritative_tmx` 作为 Tiled 编辑源，以候选 `.tscn` 作为转换结果和验证证据。
5. 正式接入前重新确认产品阶段、正式资源路径、玩家/镜头/耕作/建造/季节/存档服务。

## 尚未接入

- 八张地图仍在候选目录，未进入正式 `assets/`、正式场景或地图目录。
- H03 的 `built` 状态需由正式接入层映射到四阶段发展模型，或另行扩展候选。
- 复垦、扩建、成熟阶段仍允许包含明确标记的技术占位，不能视为最终建筑美术。
- H02 的季节切换必须放在睡眠、换季结算、地图载入或淡入淡出边界。
- 玩家、Camera2D、耕作、建造、钓鱼、NPC、剧情、跨图、季节服务与存档均未连接。
- 未修改正式 `project.godot`、正式场景、核心代码或存档 Schema；未提交、未推送。

每张地图的全部文件绝对路径、格式、尺寸、字节数、SHA-256、来源与授权，以该地图 `file_index` 和 `asset_record` 为准。
统一结构检查、深度完整性检查和交叉审计分别见 `ESTATE_MAP_PACK_VALIDATION.json`、`ESTATE_MAP_PACK_DEEP_VALIDATION.json` 与 `ESTATE_MAP_PACK_AUDIT.json`。
H01–H08 全部受控候选文件的归一化绝对路径、格式、空间尺寸或文本行数、字节数、SHA-256、来源与授权见 `ESTATE_MAP_PACK_CONTROLLED_FILES.json`。
