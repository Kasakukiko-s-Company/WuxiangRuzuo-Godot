# Godot 手动步骤

本文件只记录无法由本轮自动化证明的步骤。未勾选的项目不得宣称完成。

## G1 待用户/编辑器人工确认

- [x] 用 Godot 4.7.1 stable 图形编辑器打开项目；用户截图确认 `Main.tscn`、场景树与 `res://` 目录正常加载。
- [x] 运行 `Main.tscn`；用户截图确认嵌入式游戏窗口为 `1280×720`、16:9，标题与 G1 状态文字居中可读。
- [x] 确认 Compatibility Renderer；运行输出明确显示 `OpenGL API ... Compatibility`，启动状态同时显示 `compatibility renderer`。
- [x] 检查编辑器数据/缓存位置；自动检查确认 `_sc_` 存在、`editor_data` 位于 `D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\editor_data`，且 Godot 已实际更新其中的 `editor_settings-4.7.tres`。无需用户重复目视确认。

截图中的输出计数为 0 errors、0 warnings；4 条普通消息不构成错误。中央编辑器仍停留在 3D 工作区只是界面选项，不改变项目的 2D/Control 技术基线。

说明：G1 可执行的编辑器人工/自动检查现已全部完成。Windows 的 Godot `user://` 不随 editor self-contained 自动迁移；2026-07-20 P1 验收再次只读核对 `C:\Users\26478\AppData\Roaming\Godot`，当前为 0 个文件，不存在项目资源或存档的 C 盘唯一副本。P2 实现真实 SaveService 时由工程任务自行验证开发机与发行用户的实际存档路径，不要求用户手工检查。

## G2

G2 的目录解码、领域事务、新存档 codec、平台契约和 composition root 均可由 Godot headless 自动验证；本阶段没有需要用户执行的人工步骤。启动页只展示事实状态，不构成 P1 体验原型验收。

## P1

P1 没有需要用户重复执行的人工步骤。工程任务已用 Compatibility Renderer 实际启动原型并自动捕获高画质、低画质和调试视图，再逐张检查 640×360 逻辑构图、2× 输出、UI 重叠、前景遮挡和质量回退；截图位于被 Git 忽略的 `.godot/qa/`，可重复生成。

本机自动检查覆盖键盘物理键事件与手柄轴/按钮事件到同一 InputMap 动作的映射，但未连接实体手柄做品牌/驱动矩阵测试。该硬件兼容矩阵属于 P8 输入与兼容性 QA，不要求用户在 P1 手工代测，也不构成当前语义输入 seam 的完成声明之外的发布承诺。

## P2 地产地图工程先导

H01 正式接入没有需要用户重复执行的人工步骤。工程任务已通过 application composition root 装配 `p2_estate_pilot.tscn`，用 Godot 4.7.1 Compatibility Renderer 实际启动并自动捕获 D 盘 `builds/verification/h01_estate_pilot.png`，检查地图、角色、HUD、出生点和 2× 输出；headless 测试另行覆盖场景加载、移动、真实阻挡格撞墙、Camera2D 边界、锚点、格语义、状态切换和主入口。

未连接实体手柄、未进行长时间性能采样、未进行不同 GPU/驱动矩阵和玩家审美验收；这些是后续 QA/产品判断，不要求用户在本轮代替自动测试。H01 当前资源仍是技术候选，自动截图通过只证明接入可读与可运行，不构成发行美术批准。

## P2 生活闭环切片

本轮没有需要用户代做的人工步骤。工程任务已自动驱动 H01 场景完成北草甸资源领取、耕地、播种、浇水、家门二次确认休息、三次连续跨日、成熟和收获，并用 Compatibility Renderer 自动捕获检查资源点、休息确认与农作三张 1280×720 截图。真实物理 E/F/N 输入链路也已自动验证，N 不再推进 P2 日历。

代表性 SFX、H01 日间音乐候选和成功动作 Tween/自绘反馈已由工程任务自动生成、导入、运行和截图验证；当前没有要求用户代做的听音或编辑器步骤。`subjectiveListeningApproval=false` 表示最终听感选择、响度/循环精修和发行混音被诚实后置，不是运行接入失败。

schema v2、D 盘原子 current/protected 写入、损坏回退、三 profile 隔离、最近档、带确认删除、重进 H01 恢复，以及北草甸卖出/回购交换都由自动测试与实际运行完成，不需要用户人工检查。工程任务还用 Compatibility Renderer 自动捕获并检查了 640×360 档位页、删除确认、交换选择、会话暂停、返回标题确认和返回前保存失败状态，确认完整布局、保存/只读/可重试失败语义和“取消”默认焦点；所有截图都位于 D 盘 Git 忽略目录 `builds/verification/`。尚未完成的室内床铺与完整过夜演出、实体手柄矩阵、发行路径、最终 UI/逐帧作物与工具动画、完整音频覆盖和长流程玩家节奏判断，不会伪装成手动验收；它们属于后续 P2/P5/P9 工作。

## 明确推迟

- 导出模板：P9 正式 Windows 发行前使用与 4.7.1 stable 完全一致的模板并确认保存在 D 盘 `editor_data/export_templates`；若早期平台原型确有需要，可按同样规则提前安装。
- Windows 导出 preset 和 `D:\lzq\AI游戏\WuxiangRuzuo-Godot-Builds`：最迟 P9 配置。
- Tiled/TileMapLayer 转换和编辑器视觉验证：H01 已完成正式工程先导；其余地图沿同一 seam 逐图接入。
- 正式世界路由、跨图返回点和最终地图内容覆盖：后续阶段按获确认内容结构持续生产，不限定四张。
- Web/微信导出与插件评估：独立可行性闸门；在验证前不安装来源不明插件。
- Steamworks/native bridge：P9 发行准备。
