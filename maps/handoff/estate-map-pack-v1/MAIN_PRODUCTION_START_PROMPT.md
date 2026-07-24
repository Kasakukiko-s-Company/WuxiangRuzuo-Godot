# 给《雾乡如昨》主制作对话的地图交接指令

请把下列 H01–H08 玩家地产包作为当前唯一的地产候选输入，不要重新生成或覆盖这些候选：

- 人类可读交接：`D:\lzq\AI游戏\WuxiangRuzuo-Godot\maps\handoff\estate-map-pack-v1\MAIN_PRODUCTION_HANDOFF.md`
- 机器可读入口：`D:\lzq\AI游戏\WuxiangRuzuo-Godot\maps\handoff\estate-map-pack-v1\ESTATE_MAP_PACK_HANDOFF.json`
- 深度完整性验证：`D:\lzq\AI游戏\WuxiangRuzuo-Godot\maps\handoff\estate-map-pack-v1\ESTATE_MAP_PACK_DEEP_VALIDATION.json`
- 独立交叉审计：`D:\lzq\AI游戏\WuxiangRuzuo-Godot\maps\handoff\estate-map-pack-v1\ESTATE_MAP_PACK_AUDIT.json`
- 全受控文件清单：`D:\lzq\AI游戏\WuxiangRuzuo-Godot\maps\handoff\estate-map-pack-v1\ESTATE_MAP_PACK_CONTROLLED_FILES.json`

Pack ID：`206154e890aeee3e182ac022a76abee9`。
优先按机器可读入口中的稳定 `map_id`、候选场景、状态轴、出生点、portal、语义权威和来源授权继续设计或接入准备。
不得硬编码 Godot source ID，不得把技术占位误认为最终美术。

本交接只授权读取候选和制定接入方案；它不自动授权开始 P2、修改正式 project.godot/正式场景/核心代码/存档 Schema，也不授权提交或推送。如用户另行明确授权正式接入，再按当前里程碑流程执行。
