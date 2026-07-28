# P2 生活循环音频 Batch v1

本目录保存《雾乡如昨》P2 生活循环的 ElevenLabs 生成任务、授权边界、composition plan、候选音频和逐请求元数据。Godot 通过父目录 `.gdignore` 不扫描这些源文件。

边界：

- 只生成 7 个生活循环单次音效（每项 a/b/c 三个候选）和 1 个 H01 春季日间音乐候选。
- 音效使用 `eleven_text_to_sound_v2`；音乐先用零额度消耗的 `/v1/music/plan` 生成 `music_v2` composition plan，再生成一次候选。
- 提示不使用艺术家姓名、商业游戏名称、受版权保护歌词或现有旋律。
- SFX 原始候选为 48 kHz、16-bit、stereo PCM；审阅 WAV 只增加容器头，不改变 payload。每次请求记录本地/供应商请求 ID、模型、参数、输出 SHA-256、字节数与订阅额度前后值；API key 不写文件、不写日志。
- `candidates/` 不是发行资源。只有通过格式、Godot 导入、场景运行、来源与批次范围检查的选中项才可复制到 `assets/audio/`。
- `shippingApproval=false` 表示它们只获准用于当前工程垂直切片和后续内部迭代，不等于最终发行混音已验收。

生产脚本：

```powershell
python tools/audio_production/elevenlabs_pipeline.py --dry-run
python tools/audio_production/elevenlabs_pipeline.py --issue-grant
python tools/audio_production/elevenlabs_pipeline.py --plan --execute --confirm P2-AUDIO-PLAN-1
python tools/audio_production/elevenlabs_pipeline.py --generate-sfx --execute --confirm P2-AUDIO-SFX-21
python tools/audio_production/elevenlabs_pipeline.py --generate-music --execute --confirm P2-AUDIO-MUSIC-1
python tools/audio_production/elevenlabs_pipeline.py --verify
```

所有输出路径都被脚本限制在本仓库 D 盘目录。付费/外部请求要求版本化执行 grant、`--execute` 和精确确认 token；脚本不自动重试。命令默认幂等：已有输出不会被覆盖。

本批早期 `P2_AUDIO_EXECUTION_GRANT.json` 指针在修正 stereo 派生元数据和增强验证脚本时被覆盖，不能单独作为所有既有调用的原始 grant 快照。实际调用事实由逐请求 ledger、供应商 trace/song ID、输出哈希和 `P2_AUDIO_EXECUTION_AUDIT.json` 交叉证明；后续脚本会为每次新 grant 保留 `grants/` 版本快照，并把 grant SHA 写入新调用记录。
