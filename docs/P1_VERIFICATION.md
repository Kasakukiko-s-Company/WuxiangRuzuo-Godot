# P1 体验原型验收记录

日期：2026-07-20
状态：工作区实现与验收完成；未提交、未推送、未进入 P2。

## 验收对象

- 默认入口：`res://scenes/Main.tscn` → “进入 P1 体验原型”。
- 直接入口：`res://scenes/prototypes/p1_experience_probe.tscn`。
- 原型 ID：`prototype_mist_edge`；未登记为正式地图。
- 引擎：Godot `4.7.1.stable.official.a13da4feb`。
- 渲染：Compatibility / OpenGL 3.3，设备 Intel Iris Xe Graphics。

## 自动检查结果

| 检查组 | 行为检查数 | 结果 |
| --- | ---: | --- |
| G1 smoke | 7 | `G1_SMOKE_OK` |
| 六组 G2 回归 | 92 | 全部对应 `G2_*_OK` |
| P1 movement intent | 3 | `P1_MOVEMENT_INTENT_OK` |
| P1 tile mapper | 3 | `P1_TILE_MAPPER_OK` |
| P1 player controller | 3 | `P1_PLAYER_CONTROLLER_OK` |
| P1 input adapter | 6 | `P1_INPUT_SERVICE_OK` |
| P1 scene integration | 18 | `P1_SCENE_OK` |
| P1 Main entry | 2 | `P1_MAIN_ENTRY_OK` |
| 合计 | 134 | 全部通过 |

Godot editor/import、默认 Main 启动和 P1 直接启动均为 exit 0。最终检查无 GDScript parse error、场景加载错误、孤立错误或 ObjectDB 泄漏警告。P1 音频在 headless 环境只生成样本而不启动不可听见的播放，真实显示环境正常启动环境循环；节点退出时显式停止并释放流。

## 实际渲染验证

执行：

```powershell
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --path . --script res://tools/capture_p1_visual.gd
```

Compatibility Renderer 自动生成：

- `.godot/qa/p1_high.png`
- `.godot/qa/p1_low.png`
- `.godot/qa/p1_debug.png`

三张图均为 1280×720，严格对应 640×360 逻辑视口的 2× 输出。已逐张检查：角色、道路、交互标记和提示可读；顶部说明与调试面板不重叠；高画质有地面差异、雾带和环境细节；低画质关闭附加表现后仍保留玩法信息；调试图正确显示 32px 网格、map、位置、cell、target、facing、锁定、画质与减弱镜头状态。高/低画质像素数据不相同。

截图位于 `.godot` 缓存内并被 Git 忽略，不是长期项目资源；验证工具可以在 D 盘项目中确定性重建它们。

## 已验证行为

- 四方向面向、对角归一化、输入锁定零移动。
- 物理边界碰撞与贴墙滑动。
- Camera2D 世界边界、平滑跟随与 reduce-motion 回退。
- 32px world/cell/cell-center/facing-cell 转换。
- 键盘与手柄事件映射为同一语义动作；玩家控制器只依赖 `InputService`。
- 8 个面对格检查对象；一次性、重复、重置恢复和输入解锁路径。
- 高/低画质统一 seam、独立前景遮挡和调试叠层。
- 原创内存生成环境循环、脚步与交互反馈；无外来二进制资源。

## P1 不代表

- 不代表正式地图、美术、角色设计、音乐或剧情已经定稿。
- 不代表农耕、跨日、正式存档、NPC、关系、战斗或正式 HUD 已实现。
- 不代表实体手柄品牌/驱动矩阵、Web/微信或 Steam 发布链路已经验证。
- 战斗仍是完整游戏必做内容，按路线在 P4 交付垂直切片；P1 未提前实现战斗。

## 存储与版本控制

全部长期变更位于 `D:\lzq\AI游戏\WuxiangRuzuo-Godot`。Godot 导入缓存与 QA 截图位于项目内 `.godot/`，验收时约 0.91 MiB；self-contained editor_data 位于 `D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\editor_data`，约 11.30 MiB。`C:\Users\26478\AppData\Roaming\Godot` 当前为 0 个文件，不存在 C 盘唯一副本。新 Godot 工程已在项目内独立生成机器本地 `.codegraph/` 索引（没有复制旧项目索引），根 `.gitignore` 会排除整个索引。没有新增外部下载、未知来源资产或大型二进制文件。P0～P1 当前仍是未提交工作区变更，未推送 GitHub。
