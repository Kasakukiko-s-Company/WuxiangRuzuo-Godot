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

## 明确推迟

- 导出模板：P9 正式 Windows 发行前使用与 4.7.1 stable 完全一致的模板并确认保存在 D 盘 `editor_data/export_templates`；若早期平台原型确有需要，可按同样规则提前安装。
- Windows 导出 preset 和 `D:\lzq\AI游戏\WuxiangRuzuo-Godot-Builds`：最迟 P9 配置。
- Tiled/TileMapLayer 转换和编辑器视觉验证：P1 代表灰盒。
- 正式世界地图与 TileSet 编辑：P5 起按获确认内容结构持续生产，不限定四张。
- Web/微信导出与插件评估：独立可行性闸门；在验证前不安装来源不明插件。
- Steamworks/native bridge：P9 发行准备。
