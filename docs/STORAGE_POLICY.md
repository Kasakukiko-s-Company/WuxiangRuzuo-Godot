# D 盘存储策略

## 权威路径

- 项目/Git/运行时/源文件：`D:\lzq\AI游戏\WuxiangRuzuo-Godot`。
- Godot 发行与 self-contained 数据：`D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\editor_data`。
- 正式构建输出：`D:\lzq\AI游戏\WuxiangRuzuo-Godot-Builds`。
- 美术/音频源：项目内 `art-source/`、`audio-source/`。

`art-source`、`audio-source`、`builds` 均有 `.gdignore`。项目 `.godot` 缓存只能位于项目根且由 `.gitignore` 排除。不得把 C 盘文件作为项目资产唯一副本。

## G1 检查事实

Godot `_sc_`、D 盘 `editor_data` 和项目根均已确认。项目 `.godot` 位于 `D:\lzq\AI游戏\WuxiangRuzuo-Godot\.godot`，最终验证后为 9 个文件、约 0.005 MiB（含 D 盘 parse 日志），且被 Git 忽略。G1 不下载模板、不修改系统 TEMP/TMP、不修改系统环境变量。

G2 最终扫描后，项目 `.godot` 为 24 个文件、670057 bytes（约 0.64 MiB），仍位于项目 D 盘目录并被 Git 忽略。Godot 在 `C:\Users\26478\AppData\Roaming\Godot\app_userdata\雾乡如昨\logs` 自动留下 5 个运行日志、合计 2709 bytes；它们不包含项目资源或存档，也不是任何长期文件的唯一副本。G2 未修改系统环境变量或 TEMP/TMP。

Godot 4.7.1 self-contained 模式把编辑器设置/帮助缓存放在 D 盘，但 Windows 运行时 `user://` 仍使用 `%APPDATA%`。本轮 headless 运行在 `C:\Users\26478\AppData\Roaming\Godot\app_userdata\雾乡如昨\logs` 生成 2 个日志，共 0.56 KiB。它们不是项目资源、源文件、存档或唯一副本；长期项目事实仍全部在 D 盘。后续自动命令可用 `--log-file` 显式把诊断日志写入项目 `.godot`，P2 再对开发期/发行期 SaveService 路径分别验证，不通过系统环境变量强行重定向。

## 构建与缓存

首次需要 Windows 代表构建或最迟到 P9 时，再安装与 4.7.1 stable 完全匹配的模板并验证 D 盘位置。任何工具若强制在 C 盘写少量系统配置，必须记录位置/体积并在同批确认 D 盘权威副本；未经许可不调整系统环境变量。

## P2 开发期存档

- `AppCompositionRoot` 把开发期 H01 存档根固定为 `D:\lzq\AI游戏\WuxiangRuzuo-Godot\builds\save-dev`，启动前再验证解析后的绝对路径以 `D:\` 开头。
- current 文件为 `profile-N.json`，受保护恢复点为 `profile-N.protected.json`；同目录 `.tmp`/`.rollback`/`.bak` 只用于原子替换与崩溃回退。旧 `.bak` 会保留到新目标成功提交，避免替换窗口失去最后一个有效候选。可读但无效的旧载荷在 fallback 前写入同根 quarantine slot；隔离位冲突或写失败时只读恢复，绝不覆盖旧证据。
- `builds/` 已由 `.gdignore` 和 Git ignore 排除，因此 Godot 不导入存档，Git 也不提交玩家数据。
- 自动测试的临时存档同样位于项目 D 盘 `builds/test-save-adapter/`；测试结束删除其已知 slot，不改系统 TEMP/TMP 或环境变量。
- 这是开发期路径策略，不是发行期 Windows 用户数据位置承诺。P9 前须通过另一个 `SaveService` adapter 验证权限、多用户、卸载保留和 Steam 云冲突语义。

2026-07-29 保存切片终检时，`C:\Users\26478\AppData\Roaming\Godot\app_userdata\雾乡如昨` 共 10 个文件、约 357 KiB：5 个小型 Godot 日志和 5 个 GLES3 shader cache。日志体积会随验证运行轻微变化。该目录没有 `.json`、玩家存档、项目资源或唯一副本；权威开发存档、测试日志、截图与导入缓存均在 D 盘。没有为此修改系统环境变量。

## Git/LFS

`.godot`、构建、临时、editor_data 不入 Git。大型源文件和无损音频在正式回接前确定 LFS；G1 不复制约 298.57 MiB 旧候选，避免在策略未确认时建立二进制历史。
