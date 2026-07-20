# 平台架构

## 身份维度

- 运行环境：`windows-native`、`web`。
- 发行渠道：`standalone`、`steam`、`wechat`。

Steam 是 Windows 的渠道；微信可能建立在 Web/平台专用能力之上，但必须通过独立可行性闸门验证，不预设 Godot 原生支持。

平台顺序已经确认：P2～P9 完成 Windows/Steam 主线后，再执行 W0 标准 Web、W1 微信可行性和 W2 发布决策。当前只保留接口边界，不下载 Web 模板、不安装微信插件、不实现渠道 adapter。

## 服务边界

`PlatformService` 负责环境/渠道/安全区/生命周期；`SaveService` 处理不透明 payload；`InputService` 输出语义动作；`AudioService` 接收语义音频 ID；`AnalyticsService` 接收受控事件。核心玩法不得访问 `window`、`localStorage`、`wx`、Steamworks 或文件路径。

## 输入语义

目标至少包含 move、primary_action、secondary_action、interact、quickbar_1～8、previous/next、pause。桌面键盘/手柄与触控产生同一语义，不把物理键写入领域规则。

## 存档 adapter

Windows 使用原子文件 adapter；Web/微信受存储配额和生命周期约束；Steam 云存档是本地快照之上的渠道能力，不改变 schema。release composition 不得静默落到内存存档。

## 当前事实

G2 已建立五类 abstract service contracts、输入/安全区/存档结果值对象，以及合法环境/渠道组合校验。`AppCompositionRoot` 当前只选择 `windows-native + standalone` 描述符，尚未装配真实存档、输入、音频或分析 adapter。Web/微信/Steam 均未验证；Web/微信明确后置到 P9 之后，详见 `GODOT_PLATFORM_FEASIBILITY.md`。
