# Reasonix 配置迁移升级助手 (Migration Assistant)

将旧版 Reasonix 0.53 的对话记录、MCP 配置、记忆、Skill 完整迁移到新版 1.X。

Migrate legacy Reasonix 0.53 data (conversations, MCP config, memories, skills) to the latest 1.X version.

---

## 快速开始 / Quick Start

### 场景 [1]：标准升级（C 盘安装版） / Standard Upgrade (C-drive)

1. 确保新版 Reasonix 已安装并至少启动过一次 / Ensure the new Reasonix is installed and launched at least once
2. 双击 `0.53配置迁移到1.X.bat` → 选择 `【1】` / Double-click the bat file → choose `[1]`
3. 启动新版 Reasonix，点击【历史对话】查看迁移的会话 / Launch the new Reasonix, check History

### 场景 [2]：便携版升级（U 盘/同步盘） / Portable Upgrade

1. 将 `0.53配置迁移到1.X.bat` 和 `Migrate-053to1X.ps1` 复制到便携版 Reasonix 根目录 / Copy both files to the portable Reasonix root
2. 在便携版目录内双击 bat → 选择 `【2】` / Run the bat from the portable directory → choose `[2]`
3. 启动新版 Reasonix，点击【历史对话】查看迁移的会话 / Launch the new Reasonix, check History

### 预览模式 / Preview

选择 `【3】` 预览迁移内容，不实际写入任何文件。 / Choose `[3]` to preview without writing.

---

## 迁移内容 / What Gets Migrated

| 数据类型 | 说明 |
|---------|------|
| MCP 配置 / MCP Config | JSON → TOML `[[plugins]]` 格式 |
| 对话记录 / Conversations | 重命名 + 四件套（jsonl/meta/telemetry/ckpt） |
| 运行指标 / Metrics | token 用量、缓存命中率、费用、依赖文件 |
| 记忆 / Memories | memory/ → projects/<slug>/memory/ |
| Skill | 新版 Reasonix 原生支持 / Supported natively |

## 效果 / Result

- ✅ 侧边栏不受影响 / Sidebar stays clean
- ✅ 历史对话列表显示全部迁移会话 / All sessions in History panel
- ✅ 每条会话保留原始对话标题 / Original titles preserved
- ✅ "打开会话"可继续未完成的对话 / Resume conversations
- ✅ 对话指标已迁移 / Metrics migrated

## 注意事项 / Notes

- 迁移前自动备份 / Auto-backup before migration
- MCP 配置仅在新版 `config.toml` 尚无 `[[plugins]]` 时自动添加
- 重复运行不会重复迁移已有会话 / Idempotent—skips existing files
- tab 标题显示 "Global" 是新版的已知限制 / Tab title "Global" is a known limitation

## 文件结构 / Files

```
Reasonix 配置迁移升级助手/
├── 0.53配置迁移到1.X.bat   ← 双击运行 / Launch
├── Migrate-053to1X.ps1      ← 核心脚本 / Core script
├── README.md                ← 本文件 / This file
├── 技术实现.md               ← 技术细节 / Technical details
└── 研发纪实.md               ← 踩坑记录 / Lessons learned
```

## 依赖 / Requirements

- Windows PowerShell 5.1+
- 无需管理员权限 / No admin required
- 无需网络连接 / No network required
