# P2 地图与美术资源运行接入

日期：2026-07-30

状态：`development_runtime_integrated`

## 本批目标

本批把此前两个独立资源生产轨真正用于正式 Godot 工程：

1. H01～H08 地图生产轨：当前 P2 继续使用已经从 H01 交接包转换到正式路径的 H01 开阔草甸，而不是程序化空白地图。
2. Batch 001～003 美术生产轨：A「青雾旧垦」用于当前标题代表画面、角色轮廓和生活底色；B「纸灯暖乡」用于暖灯强调、面板边框与交互层级。

这不是把概念拼贴板伪装成 TileSet。地图运行像素来自项目自制原生 32px 图集；概念板只在适合的用途转译，角色、UI 和气氛均在 Godot 技术约束内重新实现。

## 已实际接入

- `scenes/world/estate/h01_open_meadow.tscn` 继续以正式运行路径加载 H01 terrain、objects、architecture、season 和 anomaly 图集。
- `assets/art/title/a_cyan_mist_homestead_title_dev.jpg` 由 A 代表场景完整缩放为 640×360 开发期标题图，不从世界板或角色板裁切对象。
- `assets/ui/themes/wuxiang_paper_lantern_dev.tres` 把 A 的青苔/旧木底色与 B 的纸灯暖赭轮廓转为共享 Godot Theme。
- `AmbientMistOverlay` 为标题和 H01 提供轻量雾带、暖色微光与边缘层次；`low` 画质关闭雾带和微光，玩法信息不依赖效果。
- H01 HUD 缩小遮挡范围，并在资源箱、日结和暂停界面沿用共享主题。
- 当前玩家占位表现按 A 角色板重新组织为黑发发髻、青灰短衫、麻布袖、棕色围巾、腰带与腿部步态；没有从方向板裁切像素，碰撞与移动规则未改变。

## 可重复生产

执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\build_dev_visual_reference.ps1 `
  -ProjectRoot 'D:\lzq\AI游戏\WuxiangRuzuo-Godot'
```

脚本只读取 D 盘 Batch 001 A 代表场景，并把 640×360 JPEG 写入正式工程。来源、字节数和 SHA-256 见 `docs/ASSET_SOURCES.md`。

脚本从自身所在仓库派生唯一工程根，拒绝其他项目根、非 D 盘路径与重解析点；源 SHA-256 不匹配时不开始转换，输出先写入 D 盘唯一临时候选并在 SHA-256 匹配后才替换正式文件。

## 明确保留的边界

- H02～H08 没有在 P2 一次性加入正式运行 payload；它们继续由地图交接包控制，并随相应玩家旅程切片逐图转换。
- 不修改 `SaveSnapshot` schema v2、地图 ID、portal authority、剧情 canonical ID 或 H08 trigger 规则。
- 不把 Batch 001～003 世界板、角色板或代表场景宣称为最终 SpriteSheet、TileSet、立绘差分或发行截图。
- 本批为 `runtimeIntegrated=true`、`developmentUseApproved=true`，仍是 `commercialReleaseAuthorized=false`、`shippingApproval=false`。
- 标题图派生文件小于 0.1 MiB；本批没有引入 Git LFS 需求。

## 自动验收

`tests/p2/test_p2_visual_integration.gd` 验证：

- 标题图确实由 Main 加载且为 640×360；
- Main 与 H01 HUD 使用共享 A/B Theme；
- 标题与 H01 均拥有可切换到低画质的环境层；
- 玩家表现记录 A 方向开发 profile；
- 正式 H01 Ground TileSet 实际引用 terrain、objects 和 architecture 三类已生成地图图集。

Godot 4.7.1 的 headless 场景与专项测试可以无窗口执行。Windows headless 使用 Dummy RenderingServer，不能从根 Viewport 读取 bitmap；遵照用户要求，本批不为截图启动可见 Godot 窗口。真人首次画面与手感验收仍由用户在方便时进行。

本批最终验证：Godot G1/G2/地图/P1/P2 全量 48/48 测试通过，Python 音频门禁与节奏分析器 18/18 通过，headless editor import/parse 和默认 Main 启动均为 exit 0；验证后没有残留 Godot 进程。
