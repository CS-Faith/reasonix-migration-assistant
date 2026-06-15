# Reasonix 配置迁移升级助手

将旧版 Reasonix 0.53 的对话记录、MCP 配置、记忆、Skill 完整迁移到新版 1.X。

---

## 能做什么

Reasonix 从 0.5X 升级到 1.X 时，数据结构发生了变化，旧版数据无法直接被新版识别。本工具自动完成以下迁移：

| 数据类型 | 迁移方式 |
|---------|------|
| MCP 配置 | JSON 格式 → TOML `[[plugins]]` 格式 |
| 对话记录 | 重命名 + 补全四件套（jsonl / meta / telemetry / ckpt） |
| 运行指标 | token 用量、缓存命中率、费用、依赖文件 |
| 记忆 | `memory/` → `projects/<slug>/memory/` |
| Skill | 新版 Reasonix 原生支持，无需额外处理 |

---

## 使用方法

本工具支持两种升级场景：

### 场景一：标准安装版升级（C 盘）

适用于 Reasonix 安装在 C 盘的标准用户。

1. 确保新版 Reasonix（1.X）已安装并至少启动过一次
2. 双击 `0.53配置迁移到1.X.bat`，选择 `[1]` 标准升级
3. 启动新版 Reasonix，点击「历史对话」查看迁移的会话

### 场景二：PortaKit 便携版升级（U 盘 / 同步盘）

适用于使用 [PortaKit](https://github.com/CS-Faith/reasonix-portakit) 将 Reasonix 放在 U 盘或同步盘上的用户。

1. 将 `0.53配置迁移到1.X.bat` 和 `Migrate-053to1X.ps1` 复制到便携版 Reasonix 根目录
2. 在便携版目录内双击 bat，选择 `[2]` 便携版升级
3. 用 PortaKit for 1.X 的 `启动Reasonix.bat` 启动新版，查看迁移的会话

### 预览模式

选择 `[3]` 预览迁移内容，不实际写入任何文件。建议第一次先预览，确认无误后再执行。

---

## 迁移效果

- ✅ 侧边栏不受影响，干净的迁移体验
- ✅ 历史对话列表显示全部迁移会话
- ✅ 每条会话保留原始对话标题
- ✅ 「打开会话」可继续未完成的对话
- ✅ 对话指标（token 用量、费用等）完整迁移
- ✅ 迁移前自动备份，出问题可以安全回滚
- ✅ 重复运行不会重复迁移已有文件，安全幂等

---

## 注意事项

- 迁移前会自动备份原始数据，请确保有足够磁盘空间
- MCP 配置仅在新版 `config.toml` 尚无 `[[plugins]]` 时自动写入，已有配置不会被覆盖
- 重复运行安全——已迁移的会话会被自动跳过
- Tab 标题可能显示 "Global"，这是新版 Reasonix 的已知限制，不影响正常使用

---

## 完整升级链条

如果你同时使用 PortaKit 实现便携，完整升级流程如下：

```
旧版 0.5X + PortaKit for 0.5X（便携）
         │
         ▼  运行本工具（场景二）
新版 1.X + PortaKit for 1.X（便携）
```

搭配 [PortaKit](https://github.com/CS-Faith/reasonix-portakit)，可以实现从 0.5X 便携版到 1.X 便携版的无缝衔接。

---

## 文件结构

```
├── 0.53配置迁移到1.X.bat     ← 入口，双击运行
├── Migrate-053to1X.ps1        ← 核心迁移脚本
├── README.md                  ← 本文件
├── 技术实现.md                 ← 技术细节文档
└── 研发纪实.md                 ← 踩坑记录
```

---

## 依赖

- Windows PowerShell 5.1+
- 无需管理员权限
- 无需网络连接

---

## 许可

MIT License

---

# Reasonix Configuration Migration Assistant

Migrate legacy Reasonix 0.53 data — conversations, MCP config, memories, and skills — to the latest 1.X version.

---

## What It Does

When upgrading Reasonix from 0.5X to 1.X, the data format changes and legacy data is not recognized by the new version. This tool automates the migration:

| Data Type | Migration Method |
|-----------|-----------------|
| MCP Config | JSON → TOML `[[plugins]]` format |
| Conversations | Rename + four-file bundle (jsonl / meta / telemetry / ckpt) |
| Metrics | Token usage, cache hit rate, cost, dependency files |
| Memories | `memory/` → `projects/<slug>/memory/` |
| Skills | Supported natively in 1.X — no extra processing needed |

---

## Usage

Two upgrade scenarios are supported:

### Scenario 1: Standard C-drive Upgrade

For users with Reasonix installed on the C: drive.

1. Ensure Reasonix 1.X is installed and has been launched at least once
2. Run `0.53配置迁移到1.X.bat` and choose `[1]` Standard Upgrade
3. Launch Reasonix 1.X and check the History panel

### Scenario 2: PortaKit Portable Upgrade (USB / Sync Disk)

For users running Reasonix from a portable drive via [PortaKit](https://github.com/CS-Faith/reasonix-portakit).

1. Copy `0.53配置迁移到1.X.bat` and `Migrate-053to1X.ps1` to the portable Reasonix root
2. Run the bat from the portable directory and choose `[2]` Portable Upgrade
3. Launch Reasonix using PortaKit for 1.X's `启动Reasonix.bat` and check History

### Preview Mode

Choose `[3]` to preview the migration without writing any files. Recommended for a first run.

---

## Result

- ✅ Sidebar stays clean — non-disruptive migration
- ✅ All migrated sessions appear in the History panel
- ✅ Original conversation titles preserved
- ✅ "Open Session" allows resuming unfinished conversations
- ✅ Conversation metrics (token usage, cost, etc.) fully migrated
- ✅ Auto-backup before migration for safe rollback
- ✅ Idempotent — safe to run multiple times

---

## Notes

- Pre-migration backup is automatic; ensure sufficient disk space
- MCP config is only written to `config.toml` if no `[[plugins]]` section exists yet
- Already-migrated sessions are automatically skipped on repeat runs
- Tab titles may show "Global" — a known 1.X limitation, does not affect normal use

---

## Full Upgrade Chain

If you also use PortaKit for portability, here's the complete upgrade flow:

```
Legacy 0.5X + PortaKit for 0.5X (portable)
         │
         ▼  Run this tool (Scenario 2)
New 1.X + PortaKit for 1.X (portable)
```

Combined with [PortaKit](https://github.com/CS-Faith/reasonix-portakit), you get a seamless upgrade from portable 0.5X to portable 1.X.

---

## File Structure

```
├── 0.53配置迁移到1.X.bat     ← Entry, double-click to run
├── Migrate-053to1X.ps1        ← Core migration script
├── README.md                  ← This file
├── 技术实现.md                 ← Technical details
└── 研发纪实.md                 ← Lessons learned
```

---

## Requirements

- Windows PowerShell 5.1+
- No admin privileges required
- No network connection required

---

## License

MIT License
