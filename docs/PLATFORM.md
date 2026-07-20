# 平台架构

## 身份维度

- 运行环境：`windows-native`、`web`。
- 发行渠道：`standalone`、`steam`、`wechat`。

Steam 是 Windows 的渠道；微信可能建立在 Web/平台专用能力之上，但必须由 G12 验证，不预设 Godot 原生支持。

## 服务边界

`PlatformService` 负责环境/渠道/安全区/生命周期；`SaveService` 处理不透明 payload；`InputService` 输出语义动作；`AudioService` 接收语义音频 ID；`AnalyticsService` 接收受控事件。核心玩法不得访问 `window`、`localStorage`、`wx`、Steamworks 或文件路径。

## 输入语义

目标至少包含 move、primary_action、secondary_action、interact、quickbar_1～8、previous/next、pause。桌面键盘/手柄与触控产生同一语义，不把物理键写入领域规则。

## 存档 adapter

Windows 使用原子文件 adapter；Web/微信受存储配额和生命周期约束；Steam 云存档是本地快照之上的渠道能力，不改变 schema。release composition 不得静默落到内存存档。

## 当前事实

G1 的 `AppCompositionRoot` 只证明装配入口存在，尚无任何真实平台服务。Web/微信/Steam 均未验证，详见 `GODOT_PLATFORM_FEASIBILITY.md`。
