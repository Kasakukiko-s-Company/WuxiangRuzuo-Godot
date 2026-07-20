# Demo 旧矿道与战斗垂直切片

## 范围

`old_mine` 是 32×24 的固定单层手工地图，只与 `hometown_main` 双向连接。完成 `daily.farmingIntroCompleted` 后开放，不要求关系/异常，不进入也不阻塞 Demo。入口、安全点、矿区、战斗区和出口分别为 `mine_entry`、`mine_safe_return`、`mine_ore_patch`、`mine_combat_room`、`mine_exit`。

## 采矿

锄镐稳定物品/工具目标 `tool_pickaxe`；只作用于面对方向相邻格。唯一矿脉类型 `ore_vein_common`，固定有效命中次数后尝试把一种原创矿石原子加入背包；背包满时矿脉不消失。同一稳定矿脉 ID 同日只产出一次。

## 战斗

学院练习杖只在选中时执行语义攻击；仅一种基础敌人和一个固定遭遇。玩家最大生命 5，接触伤害有受控无敌窗口。生命归零安全撤离到 `mine_safe_return`、恢复生命、不跨天、不丢物，保留同日已完成对象。

## 存档

持久状态只保存 health、mineRun.worldDay、brokenNodeIds、defeatedEncounterIds。不保存矿脉剩余命中、敌人瞬时生命/位置、投射物、冷却、无敌计时、击退或表现。睡觉后清空当日矿道状态并满血。

## 明确不做

随机/多层矿洞、第二种敌人、精英/Boss、战争残响、装备/护甲/技能树、锻造/商店/经济、远程复杂 AI 和完整怪物生态。战斗区不能堵住唯一出口。

## 当前事实

截至 G2 只保留已校验地图/存档语义，没有旧矿道场景、资源或战斗代码。G6 建地图，G8 实现规则与垂直切片。
