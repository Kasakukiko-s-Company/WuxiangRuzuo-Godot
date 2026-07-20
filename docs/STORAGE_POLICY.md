# D 盘存储策略

## 权威路径

- 项目/Git/运行时/源文件：`D:\lzq\AI游戏\WuxiangRuzuo-Godot`。
- Godot 发行与 self-contained 数据：`D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\editor_data`。
- 正式构建输出：`D:\lzq\AI游戏\WuxiangRuzuo-Godot-Builds`。
- 美术/音频源：项目内 `art-source/`、`audio-source/`。

`art-source`、`audio-source`、`builds` 均有 `.gdignore`。项目 `.godot` 缓存只能位于项目根且由 `.gitignore` 排除。不得把 C 盘文件作为项目资产唯一副本。

## G1 检查事实

Godot `_sc_`、D 盘 `editor_data` 和项目根均已确认。项目 `.godot` 位于 `D:\lzq\AI游戏\WuxiangRuzuo-Godot\.godot`，最终验证后为 9 个文件、约 0.005 MiB（含 D 盘 parse 日志），且被 Git 忽略。G1 不下载模板、不修改系统 TEMP/TMP、不修改系统环境变量。

Godot 4.7.1 self-contained 模式把编辑器设置/帮助缓存放在 D 盘，但 Windows 运行时 `user://` 仍使用 `%APPDATA%`。本轮 headless 运行在 `C:\Users\26478\AppData\Roaming\Godot\app_userdata\雾乡如昨\logs` 生成 2 个日志，共 0.56 KiB。它们不是项目资源、源文件、存档或唯一副本；长期项目事实仍全部在 D 盘。后续自动命令可用 `--log-file` 显式把诊断日志写入项目 `.godot`，G5 再对开发期/发行期 SaveService 路径分别验证，不通过系统环境变量强行重定向。

## 构建与缓存

首次导出到 G11 再安装与 4.7.1 stable 完全匹配的模板并验证 D 盘位置。任何工具若强制在 C 盘写少量系统配置，必须记录位置/体积并在同批确认 D 盘权威副本；未经许可不调整系统环境变量。

## Git/LFS

`.godot`、构建、临时、editor_data 不入 Git。大型源文件和无损音频在正式回接前确定 LFS；G1 不复制约 298.57 MiB 旧候选，避免在策略未确认时建立二进制历史。
