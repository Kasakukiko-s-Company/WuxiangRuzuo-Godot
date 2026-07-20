# G1 自动验证记录

日期：2026-07-20。工作目录：`D:\lzq\AI游戏\WuxiangRuzuo-Godot`。

## Godot

编辑器：`D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe`；控制台入口为同目录 `_console.exe`。

| 检查 | 命令摘要 | 结果 |
| --- | --- | --- |
| 版本 | `Godot...console.exe --version` | `4.7.1.stable.official.a13da4feb` |
| headless 导入/编辑器解析 | `--headless --path . --editor --quit` | exit 0；沙箱外重跑后无 ERROR |
| 冒烟测试 | `--headless --path . --script res://tests/smoke/test_g1_smoke.gd` | exit 0；7 PASS；`G1_SMOKE_OK` |
| 默认 Main 启动 | `--headless --path . --quit-after 2` | exit 0；输出 composition root ready |
| 显式 parse | `--check-only --script` 分别检查两个 app 脚本和 smoke 脚本 | 三项 exit 0，无解析错误 |

首次沙箱内导入因不允许写项目外 D 盘 editor_data 而显示权限错误；授权在沙箱外使用同一版本重跑后干净通过。该错误不是项目解析失败。

冒烟项：viewport 640×360、stretch mode `canvas_items`、aspect `keep`、renderer `gl_compatibility`、Main.tscn 可加载、composition root 状态节点存在并成功启动。

## 数据与文档

`crops.json`、`demo_world.json`、`items.json`、`localization.json`、`runtime_resources.json`、`tools.json` 全部通过 `ConvertFrom-Json`。要求的 19 个根/文档目标全部存在。误述扫描未发现“当前引擎是 Cocos”、四地图/三档/NPC/战斗已迁移或微信发布已完成等肯定句。

## 图形编辑器人工证据

用户于 2026-07-20 提供运行截图，确认 Godot 4.7.1 stable 成功打开项目并运行 `Main.tscn`。嵌入式游戏窗口显示 `1280×720`，标题、G1 状态和 composition root 文本均正常；输出明确显示 OpenGL Compatibility，错误与警告计数均为 0。editor_data 路径已由自动检查确认在 D 盘，并通过实际更新 `editor_settings-4.7.tres` 证明可写。G1 不再有需要用户执行的人工检查。

## Git（发布前验证状态）

- 新仓库在发布前为 `main`、0 commits；本文件记录的是首个基线提交建立前的验证状态。
- origin：`git@github.com:Kasakukiko-s-Company/WuxiangRuzuo-Godot.git`。
- 远端配置前 `git ls-remote` 返回空输出/exit 0；按空仓库处理。
- 用户于 2026-07-20 在图形运行验收后明确授权提交并推送 G0～G1 基线；最终 commit/hash/push 结果以本轮发布交接为准。
- `.godot/` 命中 `.gitignore`；`builds/*` 命中忽略，`builds/.gdignore` 保留入库。
- 旧 `FarmGame` 前后均为同一 `main...origin/main` 脏状态；未修改旧工程。

## 存储与大文件

项目、Git、`.godot`、代码、数据、文档均在 D 盘。项目 `.godot` 最终为 9 个文件、约 4.69 KiB（约 0.005 MiB）。self-contained `_sc_` 与 D 盘 `editor_data` 正常；editor settings 在验证时更新。Windows 默认 `user://` 在 C 盘生成 2 个 Godot 日志，共 0.56 KiB；不是项目资源/存档/唯一副本。

新项目排除 `.git`/`.godot` 后最大文件为 `MIGRATION_MATRIX.md`（约 10.8 KiB）。没有二进制、未知来源资源或需要立即启用 Git LFS 的文件。
