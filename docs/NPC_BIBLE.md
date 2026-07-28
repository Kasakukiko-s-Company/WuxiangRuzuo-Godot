# 《雾乡如昨》旧 NPC 候选池（历史参考）

> 这 15 人是旧原型候选，不是完整游戏固定阵容或内容预算。正式角色需按完整故事、世界功能、关系深度、制作成本和多样性重新选定；内部分类和知情层级不得进入玩家可见角色目录。

## 正式居民系统输入边界

正式居民设计采用 `DESIGN_REFERENCE_LESSONS.md` 的“居民日程与居民知识分离”原则：

- 下表的默认锚点只可作为候选身份和安全回退，不能当作全天日程。
- 正式日程需要按时间、日期、天气、季节、关系事件、剧情与世界状态设计，并为不可达或事件冲突提供回退。
- 居民真实日程/偏好与玩家已知信息分别建模；居民手册只展示玩家已经合理获知的内容。
- 礼物偏好优先采用物品标签、居民规则和少量例外，不复制外部游戏的居民、物品表或数值。
- 关系成长必须包含对白、守约、共同事件、冲突与选择，不能退化为重复赠礼计分。

这些是后续 P3 的设计输入，不表示居民日程、居民手册或正式关系系统已经实现。

## 全员规则

旧 Demo 曾列出 15 名 NPC，并为每人设想一份可升可降的新生好感记录。旧日熟悉由 `priorBondId` 表示、不直接换算当前好感，以及关系状态分离等规则可作为正式关系系统候选，但需要在 P0/P3 重新验证。

主角男性/女性形态与 NPC 性别均不改变资格。未满 18 岁告白必须明确拒绝，主角不能浪漫/性暗示回应；成年后也要由全新告白事件按好感判定。罗岑山、陈蕴永远只发展非恋爱关系。幸存者/重构分类不影响资格。当前不模拟 NPC-NPC 恋爱。

## 旧候选名单

| 稳定 ID | 姓名 | 年龄 | 玩家可见身份 | 默认锚点 | 层级 | 亲密边界 | 内部分类/知情 |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `npc_luo_censhan` | 罗岑山 | 68 | 村长 | `main_npc_village_hall` | core | 仅非恋爱 | 幸存者/K4 |
| `npc_ning_zhao` | 宁昭 | 22 | 跑腿人、旧驿路向导 | `main_npc_home_road` | core | 成年 standard | 幸存者/K2 |
| `npc_yan_xun` | 晏巡 | 34 | 巡山人 | `main_npc_north_gate` | core | 成年 standard | 幸存者/K3 |
| `npc_du_heng` | 杜蘅 | 32 | 村医与草药师 | `main_npc_clinic` | support | 成年 standard | 幸存者/K4 |
| `npc_qiao_yu` | 乔榆 | 45 | 木匠 | `main_npc_workshop` | support | 成年 standard | 幸存者/K3 |
| `npc_shen_he` | 沈禾 | 23 | 种子/药圃照料人 | `main_npc_farm_edge` | core | 成年 standard | 重构/K1 |
| `npc_wen_shu` | 文澍 | 30 | 教师与档案整理人 | `main_npc_archive` | support | 成年 standard | 重构/K1 |
| `npc_mu_yuan` | 穆原 | 39 | 工具匠 | `main_npc_tool_yard` | ambient | 成年 standard | 重构/K0 |
| `npc_qiao_ling` | 乔苓 | 17 | 木工学徒、乔榆女儿 | `main_npc_workshop_apprentice` | support | 未成年必拒 | 重构/K0 |
| `npc_tang_mi` | 唐米 | 36 | 公共灶房照料人 | `main_npc_communal_kitchen` | ambient | 成年 standard | 重构/K0 |
| `npc_he_zhou` | 何舟 | 28 | 水渠/河道看护人 | `main_npc_river` | support | 成年 standard | 重构/K1 |
| `npc_li_qing` | 黎青 | 25 | 牧养人与采集者 | `main_npc_pasture` | ambient | 成年 standard | 重构/K0 |
| `npc_chi_que` | 池雀 | 19 | 传信人与故事收集者 | `main_npc_square` | ambient | 成年 standard | 重构/K1 |
| `npc_a_tao` | 阿桃 | 10 | 喜欢画画的孩子 | `main_npc_old_courtyard` | ambient | 未成年必拒 | 重构/K1 |
| `npc_chen_yun` | 陈蕴 | 71 | 旧歌/口述历史保管人 | `main_npc_old_courtyard_elder` | ambient | 仅非恋爱 | 重构/K1 |

乔榆与乔苓固定为“幸存父亲—重构女儿”；他保护的是拥有独立意识的当前女儿。乔苓在 `worldDay=121` 满 18 岁后，下一次告白才改用好感判定，不自动继承儿童期为恋爱内容。

## 旧内容层级

- core 4 人：开场/主线职责、日常对白和至少一个关键片段。
- support 5 人：重逢对白、少量轮换和一个职业/关系/异常反应片段。
- ambient 6 人：明确身份、稳定位置和 2～3 组短对白/环境反应。

这些层级只记录旧 Demo 预算假设，不约束正式角色数量、个人线深度或立绘套装。

## Demo 关系预览

- `demo_relationship_shen_farm_reacquaintance`：第一日农务后与沈禾交谈，记录 `shared_memory`/`new_choice`/`playful` 倾向；不锁恋爱、不影响边界。
- `demo_relationship_ning_north_road`：第二日山路前后与宁昭交谈，展示旧日亲近与信任压力；无论选择都不阻塞边界。

## 当前资源状态

A-8 为已确认视觉方向；P-01～P-05 是已确认的五个完整男性主角候选（P-01 默认）；SH-01 为沈禾已确认造型/比例。现有 AI 图仍非运行时资源且未完成商业清权/人工重构。SH-02～SH-05 未绑定 NPC；沈禾表情候选未选择。G1 未复制这些文件。
