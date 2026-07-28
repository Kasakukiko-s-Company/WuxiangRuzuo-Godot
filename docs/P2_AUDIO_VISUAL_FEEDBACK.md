# P2 代表性动画与音频反馈

## 结果

2026-07-28 已为 H01 生活循环接入第一组可运行、可替换的代表性视听反馈：

- 7 个稳定 SFX ID：采集、耕地、播种、浇水、收获、休息确认、跨日完成。
- 1 个 H01 春季日间 music ID。
- 6 类 Godot 原生交互动画：工具/种植/浇水/收获/采集/休息。
- `AudioService` 由 composition root 注入；玩法只发稳定 ID，不读取文件路径或调用供应商 API。
- “减少动态效果”开启时，Tween 被替换为极短静态反馈；玩法信息不依赖动画。

本批证明 P2 场景能播放正式格式的候选音频并表现动作反馈，但它不是最终发行混音、美术动画或完整声音覆盖。`subjectiveListeningApproval=false`、`commercialReleaseAuthorized=false`、`shippingApproval=false`。

## 参考文件的实际采用范围

用户提供的对话导出全文经只读审计后确认：

- 可复用的是 ElevenLabs 的 dry-run、一次性授权、零自动重试、候选隔离、composition plan、请求台账、SHA-256、技术 QA 与延迟用量核销方法。
- 文件中没有实际可用的动画生成 API。另一个项目的角色、卡牌、音乐、音效、提示词和候选文件全部未复制。
- P2 动画因此使用 Godot `Tween` + `Node2D._draw()` 原生实现；若以后制作逐帧角色动画，另走角色资源生产轨。

## 音频生产

生产契约：`audio-source/p2-life-loop-v1/`。

1. `--dry-run` 验证 7 cue × 3 variant、1 首音乐、D 盘路径、额度上限与零自动重试，不写文件、不调用 API。
2. `--issue-grant` 绑定 jobs、authorization 与脚本 SHA-256，授权 24 小时内的精确 job 集。早期脚本只保存单一 grant 指针，修正 stereo 派生和增强验证时覆盖了历史指针；`P2_AUDIO_EXECUTION_AUDIT.json` 已明确披露并以当次哈希、逐请求 ledger、供应商 trace/song ID、输出哈希和用量快照交叉重建，当前 grant 不冒充历史原件。脚本现已改为版本化保存后续 grant，并把 grant SHA 写入未来调用；任一 `ATTEMPTED` 的 capability/audio ID 永久禁止再次生成，operation 总调用数也受授权上限约束。当前批次三个 operation 的剩余可执行数均为 0。
3. `/v1/music/plan` 使用 `music_v2` 生成 60 秒四段 composition plan；前后用量均为 10392，实际 0 credit。
4. `/v1/sound-generation` 使用 `eleven_text_to_sound_v2` 和 `pcm_48000` 生成 21 个候选；原始输出为 48 kHz、16-bit、stereo PCM，审阅 WAV 只加容器头。
5. `/v1/music/detailed` 使用已审查 plan 生成唯一 60 秒 `mp3_48000_192` 候选并返回 song ID。
6. 延迟核销后的实际批次用量为 1116 credits：SFX 291、music 825；超额计费关闭，远低于 3000 credit 批次上限。
7. 22/22 候选通过存在、哈希、PCM/WAV、MP3 签名和无 `.part` 检查。

当前官方接口依据：

- Sound Effects：<https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert>
- Music plan：<https://elevenlabs.io/docs/api-reference/music/create-composition-plan>
- Detailed music：<https://elevenlabs.io/docs/api-reference/music/compose-detailed>
- Subscription：<https://elevenlabs.io/docs/api-reference/user/subscription/get>
- API pricing：<https://elevenlabs.io/pricing/api>

API key 只从进程环境变量读取，未写入仓库、命令参数或日志。原始候选和审阅文件均位于 D 盘 `.gdignore` 目录；运行时只复制 7 个选中 WAV 与 1 个 MP3 到 `assets/audio/p2/`。

## 运行时架构

`data/audio_catalog.json` 是版本化运行目录。`GodotAudioService`：

- 加载并校验稳定 ID、kind、Godot 路径、音量和循环标记。
- 持有 1 个音乐播放器和 4 个可轮换 SFX 播放器。
- 在 headless 测试中解析和记录调用但不启动设备播放。
- 复制 stream 后设置循环，不改写导入资源。
- 支持 mute，并由场景退出时停止音乐。

`P2InteractionFeedback` 不拥有领域状态，只消费成功动作的 ID 与目标格世界位置。失败事务不会播放成功音效或成功动画。

## 选中候选

P2 运行时选择以无剪切、峰值/RMS/DC、动作时长和 variant 语义为依据：

- till `c`
- plant `c`（a/b 存在满幅样本，未选）
- water `a`
- harvest `c`
- gather `c`
- rest confirm `c`
- rest complete `c`
- music：唯一经授权 `music_v2` 候选

完整路径与理由见 `P2_AUDIO_RUNTIME_SELECTION.json`。本次没有把“技术可用”写成“主观听感或发行混音已批准”。

## 自动验证

- 音频生产脚本 Python parse：exit 0。
- `test_elevenlabs_pipeline_guards.py`：重复 audio ID、供应商状态未知、operation 上限和未用额度四项门禁测试通过。
- 候选验证：22/22 passed；无 `.part`。
- `test_godot_audio_service.gd`：目录原子加载、8 cue、播放器池、music/SFX ID 与 mute 全部通过。
- `test_p2_interaction_feedback.gd`：标准动画、低动态静态提示和未知 ID 拒绝通过。
- `test_h01_farming_loop.gd`：7 个动作音效、H01 音乐和交互动画均经真实场景链路触发。
- Godot 全量回归：27/27 passed。
- Compatibility Renderer：Godot 4.7.1、OpenGL 3.3、Intel Iris Xe；捕获资源点、休息确认和农作动作画面，运行期间没有音频导入或播放错误。

## 仍未完成

- 主观听感选择、响度归一、循环接缝精修、音乐状态切换和长时间混音。
- 角色逐帧工具动作、作物正式动画、正式特效与全玩法声音覆盖。
- 设置界面的音乐/SFX 独立音量、设备切换和平台音频生命周期。
- P4 战斗音乐、战斗 SFX 与异常状态音景。

这些项目进入后续代表区域和 P5 正式生产管线；不阻止当前候选用于 P2 内部可玩验证。
