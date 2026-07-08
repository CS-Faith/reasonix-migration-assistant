# Reasonix 配置迁移升级助手

> 升级 Reasonix 0.53 → 1.X 不是「重新安装」，是**搬家**。Migration Assistant 把旧版的对话、MCP、记忆、Skill——一次性搬到新版，无需手动重建。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Reasonix](https://img.shields.io/badge/Reasonix-Ecosystem-58a6ff)](https://github.com/CS-Faith/reasonix-ecosystem)

---

## 一句话定位

| 升级前 | 升级后 |
|--------|--------|
| Reasonix 0.53 + 数百条对话 + MCP + Skill + 记忆 | Reasonix 1.X + **全部数据完整迁移** |

---

## 安全机制

- **自动备份**：迁移前自动将旧配置备份到同一目录下的 `.backup/` 文件夹
- **不覆盖**：不会删除或覆盖任何旧版文件
- **可逆**：需要时可以从 `.backup/` 恢复

---

## 能迁移什么？

| 数据类型 | 0.53 格式 | 1.X 格式 | 迁移方式 |
|---------|----------|---------|---------|
| MCP 配置 | JSON | TOML `[[plugins]]` | 自动转换 |
| 对话记录 | jsonl / meta / telemetry / ckpt | 新版四件套 | 重命名 + 补全 |
| 运行指标 | token 用量、缓存命中率、费用 | 新版 metrics | 字段映射 |
| 记忆 | `memory/` 目录 | `projects/<slug>/memory/` | 按 slug 重组 |
| Skill | 全套文件夹 | 新版原生支持 | 直接拷贝 |

---

## 两步升级

1. 安装 Reasonix 1.X，启动一次
2. 双击 `0.53配置迁移到1.X.bat` → 选择模式 → 完成

```bash
# 预览模式（不实际迁移）
0.53配置迁移到1.X.bat --preview
```

---

## 支持两种场景

### 场景一：标准安装版升级（C 盘）
适用于 Reasonix 安装在 C 盘的标准用户。

### 场景二：PortaKit 便携版升级（U 盘 / 同步盘）
适用于使用 [PortaKit](https://github.com/CS-Faith/reasonix-portakit) 将 Reasonix 放在便携设备上的用户。将 bat 和 ps1 复制到便携版根目录运行。

---

## FAQ

**Q: 迁移会覆盖我的新版 1.X 配置吗？**
A: 不会。Migration Assistant 只读取旧版数据并合并到新版结构中。

**Q: 迁移失败了怎么办？**
A: 所有操作前已自动备份到 `.backup/` 目录。可以从备份恢复。

**Q: 迁移后旧版数据会被删除吗？**
A: 不会。所有旧版文件保持原样，您可以手动确认安全后再清理。

---

## Next Step

迁移完了，想让 Reasonix 跟随 U 盘走？ → [**Portakit**](https://github.com/CS-Faith/reasonix-portakit) 让新版 Reasonix 也变得便携

想在新版里使用历史会话讨论？ → [**Conversation Council**](https://github.com/CS-Faith/conversation-council)

---

## License
MIT © 2026 [CS-Faith](https://cs-faith.github.io)