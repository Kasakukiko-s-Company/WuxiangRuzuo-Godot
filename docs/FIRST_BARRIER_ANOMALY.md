# 第一处结界异常：界碑回折

内部事件 ID：`anomaly.first_barrier_fold`。玩家界面只使用“山路异象/北侧山路”等日常词，不显示“结界”“愿境”或内部 ID。

## 触发

必须同时满足：`world.boundaryRouteAvailable=true`、`mystery.firstBarrierObserved=false`、玩家在 `boundary_probe`、面向概念出口，并主动提交“继续沿旧山路往前”。进入地图、接近、日期、睡觉、好感、告白或 NPC 对话均不触发。

## 节拍

1. 正常山路与旧界碑；玩家自由控制。
2. 主动越界后短暂抑制世界输入，日常环境声抽离。
3. 玩家已越过界碑，却在前方再次看到同一轮廓；道路距离不再缩短。
4. 冷暗/薄雾等可关闭表现短暂进入。
5. 安全回折到 `boundary_return`，面向北；此时才提交 `mystery.firstBarrierObserved=true`。
6. 日常表现恢复，`boundary_clue` 出现完整布结的路标布，晏巡给出克制回应。
7. 设置 `demo.milestoneReached=true`，恢复控制；玩家可检查线索或返回生活。

持续状态：`world.boundaryRouteAvailable`、`mystery.firstBarrierObserved`、`mystery.boundaryRibbonInspected`、`demo.milestoneReached`。瞬态表现状态 `idle -> armed -> presenting -> recovered -> idle` 不写存档。

## 安全与回退

资源缺失、暂停/前后台、中断或低画质都不能锁住输入或改变叙事结果。关闭粒子、Shader、镜头移动和音频后，仍以重复界碑、玩家回位、字幕/旁白和路标布表达异常。首次只播一次，重复接近柔和推回并显示短反馈，不造成伤害。

## 保密边界

可暗示道路异常、晏巡见过类似情况、路标位置矛盾；不可证实屠村、愿望、愿境、重构来源、集体隐瞒或战争残响。不出现尸体、军队、怪物、神石、血字、贴脸惊吓或高频闪烁。

## 当前事实

G1 仅迁移事件语义，未创建 `boundary_pass`、状态机或视听资源。实现目标为 G6/G7/G10。
