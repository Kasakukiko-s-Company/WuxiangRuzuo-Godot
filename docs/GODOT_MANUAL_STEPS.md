# Godot 手动步骤

本文件只记录无法由本轮自动化证明的步骤。未勾选的项目不得宣称完成。

## G1 待用户/编辑器人工确认

- [x] 用 Godot 4.7.1 stable 图形编辑器打开项目；用户截图确认 `Main.tscn`、场景树与 `res://` 目录正常加载。
- [x] 运行 `Main.tscn`；用户截图确认嵌入式游戏窗口为 `1280×720`、16:9，标题与 G1 状态文字居中可读。
- [x] 确认 Compatibility Renderer；运行输出明确显示 `OpenGL API ... Compatibility`，启动状态同时显示 `compatibility renderer`。
- [x] 检查编辑器数据/缓存位置；自动检查确认 `_sc_` 存在、`editor_data` 位于 `D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\editor_data`，且 Godot 已实际更新其中的 `editor_settings-4.7.tres`。无需用户重复目视确认。

截图中的输出计数为 0 errors、0 warnings；4 条普通消息不构成错误。中央编辑器仍停留在 3D 工作区只是界面选项，不改变项目的 2D/Control 技术基线。

说明：G1 可执行的编辑器人工/自动检查现已全部完成。Windows 的 Godot `user://` 不随 editor self-contained 自动迁移；本轮已只读核对 C 盘同名目录，仅有 2 个 Godot 日志、合计 0.56 KiB，不是项目资源或存档。G5 实现 SaveService 时由迁移任务自行验证开发机与发行用户的实际存档路径，不要求用户手工检查。

## G2

G2 的目录解码、领域事务、新存档 codec、平台契约和 composition root 均可由 Godot headless 自动验证；本阶段没有需要用户执行的人工步骤。启动页只展示事实状态，不构成 G3 场景玩法验收。

## 明确推迟

- 导出模板：G1 不需要；到 G11 首次 Windows 导出时，使用与 4.7.1 stable 完全一致的模板并确认保存在 D 盘 `editor_data/export_templates`。
- Windows 导出 preset 和 `D:\lzq\AI游戏\WuxiangRuzuo-Godot-Builds`：G11 配置。
- Tiled 小图导入/转换编辑器目视验证：G3。
- 四张正式地图与 TileSet 编辑：G6。
- Web/微信导出与插件评估：G12；在验证前不安装插件。
- Steamworks/native bridge：G13。
