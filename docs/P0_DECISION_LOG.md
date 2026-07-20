# P0 产品决策记录

## 状态定义

- `confirmed`：用户或不可逆技术事实已确认，可作为当前计划输入。
- `working-hypothesis`：允许继续设计/原型，但必须根据证据调整。
- `prototype-required`：不能靠文档决定，必须用可玩或内容样章验证。
- `retired`：旧方案停止作为 backlog，不代表永远禁止重新提出。

## 已确认

| 决策 | 状态 | 依据/影响 |
| --- | --- | --- |
| Godot 项目目标是完整游戏，不是 Cocos 复刻或技术 Demo | confirmed | 用户明确纠偏 |
| 旧 Cocos 只是雏形和候选资料 | confirmed | 不再继承其范围、数量和里程碑 |
| 必要时主动扩充剧情、关卡、美术、音乐与音效 | confirmed | 资源生产进入正式路线 |
| 正式游戏一定包含战斗 | confirmed | P4 必须实现战斗垂直切片；旧矿道/敌人/武器不自动继承 |
| Godot 4 stable + 强类型 GDScript + 2D | confirmed | 当前技术基线与已验证工程 |
| Windows/Steam 为首要发行方向 | confirmed | P2～P9 以 PC 完整游戏和发行候选为主线 |
| Web/微信实际开发后置到 Windows/Steam 发行候选之后 | confirmed | 当前只维持平台 seam、Compatibility Renderer 和画质回退；P9 后依次执行标准 Web、微信渠道可行性和发布决策 |
| 当前不下载 Web 模板、不安装微信插件、不承诺微信发行 | confirmed | 避免未验证渠道打断 PC 主线；后置验证可以得出支持、专项移植或暂不发布三种结果 |
| 长期项目/资源/构建/缓存以 D 盘为权威位置 | confirmed | 存储硬约束 |
| G2 数据/领域/平台 seam 可作为技术底座 | confirmed | 已有 99 项回归检查；不代表内容获确认 |

## 工作假设

| 决策 | 状态 | 当前假设 |
| --- | --- | --- |
| 产品类型 | working-hypothesis | 生活模拟为主，人物关系与主动悬疑为重要支柱 |
| 目标时长 | working-hypothesis | 主线 18～25 小时，主要可选内容 35～50 小时 |
| 首发语言 | working-hypothesis | 简体中文源语言；英文是否同步待 P5 前决定 |
| 世界结构 | working-hypothesis | 一个生活枢纽 + 多个生活/探索区域 + 室内，不限定场景文件数 |
| 视觉方向 | working-hypothesis | 640×360、32px 基础瓦片、HD 像素增强与静态立绘；P1 可推翻像素密度/角色画布假设 |
| 时间压力 | working-hypothesis | 日常允许短目标和安全保存，不以强迫每日打卡驱动 |
| 内容规模 | working-hypothesis | 采用 `CONTENT_BUDGET.md` 的区间，P2～P4 后重估 |

## 必须原型验证

| 问题 | 状态 | 解锁决策 |
| --- | --- | --- |
| 自由移动、镜头、碰撞和 32px 空间尺度是否舒适 | prototype-required | P1 地图/角色/相机规格 |
| 生活生产循环是否有长期选择而非机械重复 | prototype-required | P2 农业、经济、制作和时间制深度 |
| 居民日程与关系事件的单位制作成本 | prototype-required | P3 正式阵容与文本/立绘预算 |
| 悬疑如何与日常共存且不强迫玩家 | prototype-required | P4 主线门控与内容结构 |
| 战斗采用何种操控、成长、敌人、难度、频率和失败成本 | prototype-required | P4 战斗垂直切片与正式内容预算 |
| 代表场景/角色/音乐的实际制作成本 | prototype-required | P5 全量资源预算和质量标杆 |
| Web/微信的包体、性能、输入、存档和维护成本 | prototype-required | P9 后通过 W0/W1 后置验证决定是否作为发行目标及其内容回退 |

## 已停止的旧方案

| 旧方案 | 状态 | 原因 |
| --- | --- | --- |
| 按 Cocos 文件或 TypeScript 模块逐项翻译 | retired | 技术迁移不等于产品设计 |
| 固定四张正式地图 | retired | 只保留为 G2 fixture/旧灰盒种子 |
| 固定 15 名正式 NPC | retired | 角色阵容必须从故事和内容预算重新选定 |
| 旧 G3～G13 作为正式 backlog | retired | 已由 P0～P9 完整游戏路线替代 |
| 只回接旧美术，不主动生产新资源 | retired | 无法支撑完整游戏内容与质量 |
| 固定旧异常/矿道/练习杖/单一敌人为必做切片 | retired | 战斗确定存在，但具体场景与规则在 P4 重新设计 |

## 决策节奏

工程可逆细节由实现和自动验证直接处理。方向、正史、高成本内容或平台承诺集中在阶段出口统一确认，避免用零碎问题反复打断用户。所有工作假设必须在相关阶段验收中保留“继续、修改、取消”三种结果。
