# P2 本地节奏证据

## 当前状态

截至 2026-07-29：

- `instrumentationReady=true`：H01 已具备本地、版本化、可回归的成功动作节奏采集能力。
- `humanEvidenceCollected=false`：尚未把任何自动测试结果冒充真人首次游玩样本。
- `designDecisionReviewed=false`：北草甸免费资源、村社券 30/20 和当前成长节奏仍是 P2 可替换假设。
- `SaveSnapshot.schemaVersion=2` 保持不变；证据 schema 与存档 schema 完全独立。

因此，本批关闭的是“无法采集真实节奏”的工程缺口，不是 P2 玩家验证出口。

## 运行边界

普通编辑器运行、日常调试、headless 测试和自动截图都默认不装配证据 adapter，也不会被推断为真人。只有明确知情的内部试玩使用 Godot 自定义参数 `--p2-pacing-human`，或专项自动化显式使用 `--p2-pacing-automation`/注入 `runKind=automation` 时，`AppCompositionRoot` 才启用采集；两个参数冲突时关闭采集但继续游戏。

命令行启动真人内部采样时，将自定义参数放在 Godot 参数分隔符之后：

```powershell
& 'D:\lzq\godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --path . -- --p2-pacing-human
```

每次已显式启用的 H01 会话使用一个随机 session ID，并逐行 flush 到：

`D:\lzq\AI游戏\WuxiangRuzuo-Godot\builds\playtest-evidence\p2-pacing\`

目录受 `.gitignore` 和 `.gdignore` 保护，不进入 Godot 运行资源、普通提交或远端。adapter 只接受绝对 D 盘路径；目录不可用、事件越界、属性不合规或写入失败时会停止证据写入，但不回滚合法玩法或 schema v2 保存事务。

## 事件与完整性

证据 schema 为 `evidenceSchemaVersion=1`，一行一个 JSON object：

- `p2.pacing.session_started`
- `p2.pacing.objective_changed`
- `p2.pacing.action_committed`
- `p2.pacing.session_ended`

首批白名单动作覆盖每日种子/雾叶选择、耕地、播种、浇水、休息、收获、出售和购买。物资箱结果显式携带稳定 source/offer ID；证据层不根据 UI 文案或背包差值猜测玩家选择。

只有从新空档开始，并在同一会话严格依次观察到“任一每日资源选择 → 耕地 → 播种 → 浇水 → 休息 → 收获 → 出售”时，结束事件才标记 `outcome=complete_loop`；乱序或缺失为 `incomplete`，恢复档统一标记 `outcome=excluded_resumed`，不得混入首次循环完成率。异常终止导致没有 `session_ended` 的文件也不得计为完成样本。自动化与真人记录必须始终分开汇总。

每条记录同时携带 `startingStateKind`、`buildRevision=p2.pacing.instrumentation.v1` 和 `contentRevision=p2.h01.balance.v1`；任何影响采集语义或经济/成长节奏的变更都必须同步提升相应修订号，禁止跨修订直接合并统计。

当前记录可派生：

- 会话总时长和完整循环完成率；
- 各成功动作的首次到达时间；
- 资源选择和出售/购买路径；
- 世界日、当前目标、耕地/作物数量；
- 种子、雾叶和村社券的受控粗粒度数量。

本批尚未采集菜单打开、取消、失败原因、暂停时长或连续输入轨迹；这些摩擦事件需要后续独立的 typed observation seam，不能滥用会触发自动保存的 durable signal。

## 隐私与授权

本地记录不联网、不安装遥测 SDK、不上传到 Steam、微信或第三方服务。禁止字段包括：

- profile ID、姓名、账号、IP、设备唯一 ID；
- 绝对路径、存档 payload、自由文本；
- 玩家坐标或逐帧输入轨迹；
- 任意嵌套 Dictionary/Array。

属性必须完整匹配事件对应的 typed registry：字符串字段只接受逐字段注册的 run kind、场景、地图、目标、动作、状态、结果和修订 ID；计数与时间字段只接受规定范围的整数。不允许键中塞入未注册文本、路径或错误类型；这类输入同样会在写入前停用 adapter。一个会话最多 2048 个事件，单行最多 16384 个字符。文件当前不自动删除；需要清理时只删除上述 Git 忽略目录中的具体证据文件，不得把它们作为项目资源唯一副本或提交到远端。

## 只读汇总与决策门槛

`tools/playtest/analyze_p2_pacing.py` 对已经安全结束的 JSONL 做独立、fail-closed 汇总。它使用有界流式读取，逐文件检查 UTF-8/JSON、重复键、顶层和属性白名单、连续 sequence、Godot signed-int64 与单调时间、精确注册的 build/content revision、事件拓扑、稳定 session 属性、动作前后状态变化、结束 outcome 和克隆 payload；时长、首动作和指纹都以会话内相对时间计算，绝对 wall-clock/elapsed 整体平移不能污染指标或复制样本。输入必须是证据目录内的 D 盘普通文件，symlink、目录外目标或其他盘目标都会 fail closed。任何完整性问题都会令整份报告 `reportUsable=false`。报告只使用 `source-0001` 形式的中性来源编号和稳定注册值，不回显文件名、session ID、绝对路径、profile、存档 payload 或自由文本。

```powershell
& 'D:\python\python.exe' tools\playtest\analyze_p2_pacing.py
```

默认只读 `builds/playtest-evidence/p2-pacing/` 并把 JSON 报告写到标准输出；如显式使用 `--output`，输入和输出都必须解析到 D 盘，输出必须是 `.json`，不能覆盖 `.jsonl` 源证据。automation、resumed 和 `human_internal` fresh 自声明样本分开计数；不同 build/content revision 各自成组，绝不合并补足样本量。最低门槛固定为同一兼容 revision 组 5 份结构完整且不重复的 `complete_loop`，API 和 CLI 都不能降低。达到门槛只会给出 `candidateSetReadyForHumanAttestation=true` 和 `human_attestation_required`：JSON 自报的 `human_internal` 不能证明实际操作者，因此分析器始终保持 `humanEvidenceCollected=false`、`directionalReviewReady=false`、`designDecisionReviewed=false`、`p2CompletionClaimAllowed=false`。真人确认、产品复盘和 P2 出口仍需明确判断。

回归测试：`tests/p2/test_p2_pacing_evidence_report.py` 覆盖空目录、五份结构合格候选、自动化/恢复档隔离、未知 revision、浮点时间、超出 Godot int64 的大整数、相对时间指标、明显不可能的状态链、零时长自声明真人、绝对时间平移克隆、嵌套对象/数组攻击、超长整数 JSON、隐私脱敏、固定最低门槛、D 盘路径、symlink/目录外来源、16384/16385 字符与 2048/2049 事件精确边界、非法 UTF-8，以及两份 GDScript producer 的事件/属性/动作/结果/revision/硬限制注册表一致性。

## 真人验证出口

后续真实试玩应优先使用新空档，从资源选择开始完成一轮生活循环并安全返回标题。首轮建议至少取得 5～8 个明确知情的内部首次试玩样本，再做方向性复盘；样本量不足时不得宣称统计显著或最终平衡。

复盘前仍保持：

- 当前每日免费资源和交换数值不是正式经济定案；
- 自动化记录只证明采集链路和确定性，不是玩家体验；
- P2 仍未完成，不能自动进入 P3。
