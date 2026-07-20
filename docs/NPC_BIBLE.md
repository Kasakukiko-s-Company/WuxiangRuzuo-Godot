# 《雾乡如昨》NPC 设定基线

> 内部分类和知情层级不得进入玩家可见角色目录。

## 全员规则

Demo 固定 15 名 NPC；所有人都有一份可升可降的新生好感记录。旧日熟悉由 `priorBondId` 表示，不直接换算当前好感。亲近表现、告白、`dating`、求婚与婚姻是不同状态；同一存档可有多条 `dating`，但 `spouseCharacterId` 最多一个。

主角男性/女性形态与 NPC 性别均不改变资格。未满 18 岁告白必须明确拒绝，主角不能浪漫/性暗示回应；成年后也要由全新告白事件按好感判定。罗岑山、陈蕴永远只发展非恋爱关系。幸存者/重构分类不影响资格。当前不模拟 NPC-NPC 恋爱。

## 稳定名单

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

## 内容层级

- core 4 人：开场/主线职责、日常对白和至少一个关键片段。
- support 5 人：重逢对白、少量轮换和一个职业/关系/异常反应片段。
- ambient 6 人：明确身份、稳定位置和 2～3 组短对白/环境反应。

层级只限制内容预算，不关闭好感能力，也不承诺完整个人线或立绘套装。

## Demo 关系预览

- `demo_relationship_shen_farm_reacquaintance`：第一日农务后与沈禾交谈，记录 `shared_memory`/`new_choice`/`playful` 倾向；不锁恋爱、不影响边界。
- `demo_relationship_ning_north_road`：第二日山路前后与宁昭交谈，展示旧日亲近与信任压力；无论选择都不阻塞边界。

## 当前资源状态

A-8 为已确认视觉方向；P-01～P-05 是已确认的五个完整男性主角候选（P-01 默认）；SH-01 为沈禾已确认造型/比例。现有 AI 图仍非运行时资源且未完成商业清权/人工重构。SH-02～SH-05 未绑定 NPC；沈禾表情候选未选择。G1 未复制这些文件。
