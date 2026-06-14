<#
.SYNOPSIS
    Reasonix 配置迁移升级助手 (Migration Assistant)
    将旧版 0.53 的对话记录、MCP配置、记忆文档等数据完整迁移到新版 1.X
#>
param([string]$SourcePath, [switch]$Portable, [switch]$DryRun)

$ErrorActionPreference = "Continue"

# === Determine source ===
if ($SourcePath) {
    $srcRoot = $SourcePath
    Write-Host "手动指定源: $srcRoot"
} else {
    # === Auto-detect source ===
    $username = [Environment]::UserName
    $srcRoot = $null
    
    if ($Portable) {
        # Portable mode: use parent directory of this script
        $scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
        $srcRoot = Join-Path $scriptDir '.reasonix'
        if (-not (Test-Path (Join-Path $srcRoot 'config.json'))) {
            Write-Host "错误：当前目录下未找到 .reasonix 数据"
            Write-Host "请把本工具（bat + ps1）复制到便携版 Reasonix 根目录后再运行"
            exit 1
        }
        Write-Host "已检测到便携版: $srcRoot"
    } else {
# Build C drive candidates: try env USERNAME, then scan for any user dir with .reasonix
$cCandidates = @()
$envPath = "C:\Users\$username\.reasonix"
if (Test-Path $envPath) { $cCandidates += @{Path=$envPath; Label="C盘 ($username)"} }
# Also scan for other users
try {
    $userDirs = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notin @('Public','Default','All Users','Default User') -and
        (Test-Path (Join-Path $_.FullName '.reasonix\config.json'))
    }
    foreach ($ud in $userDirs) {
        $p = Join-Path $ud.FullName '.reasonix'
        if ($p -ne $envPath) { $cCandidates += @{Path=$p; Label="C盘 ($($ud.Name))"} }
    }
} catch {}
$candidates = $cCandidates
if ($env:RX_ROOT) {
    $candidates += @{Path="$env:RX_ROOT\.reasonix"; Label="便携版 (RX_ROOT)"}
}
foreach ($c in $candidates) {
    $p = $c.Path
    $cfgPath = Join-Path $p "config.json"
    if (-not $p -or -not (Test-Path $cfgPath)) { continue }
    try {
        $testCfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
        # Check for 0.53 sessions (desktop-xxx.jsonl naming)
        $sessDir = Join-Path $p "sessions"
        $has053 = (Test-Path $sessDir) -and ((Get-ChildItem $sessDir -Filter 'desktop-*.jsonl' -File -ErrorAction SilentlyContinue).Count -gt 0)
        if (-not $has053) {
            Write-Host "跳过（无0.53会话）: $p"
            continue
        }
    } catch {}
    $srcRoot = $p
    Write-Host "已检测到源: $($c.Label) -> $srcRoot"
    break
}
    if (-not $srcRoot) {
        Write-Host "错误：未找到 0.53 的 .reasonix 目录"
        Write-Host "已检查: $(($candidates | ForEach-Object { $_.Path }) -join ', ')"
        exit 1
    }
    } # end standard auto-detect
}

# === Target ===
$tgtRoot = "$env:APPDATA\reasonix"
$globalWs = Join-Path $tgtRoot "global-workspace"
$slug = ($globalWs -replace ':\\', '--' -replace '\\', '-' -replace '/', '-')
$tgtSessions = Join-Path $tgtRoot "projects\$slug\sessions"
$tgtMemory   = Join-Path $tgtRoot "projects\$slug\memory"
$tgtCfgPath  = Join-Path $tgtRoot "config.toml"

$enc = [System.Text.UTF8Encoding]::new($false)
Write-Host "=== Reasonix 0.53 -> 1.5 数据迁移 ==="
Write-Host "源路径: $srcRoot"
Write-Host "目标路径: $tgtRoot"
Write-Host ""

if (-not (Test-Path $tgtRoot)) {
    Write-Host "错误：未找到 1.5 数据目录 $tgtRoot，请先启动一次 1.5。"
    exit 1
}

# === Backup ===
if (-not $DryRun) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = "$tgtRoot.backup-$ts"
    Write-Host "备份: $backupDir"
    robocopy $tgtRoot $backupDir /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS /XD "EBWebView" 2>&1 | Out-Null
    Write-Host ""
}

# ============================================================
# 1. MCP Migration
# ============================================================
Write-Host "--- [1/4] MCP 迁移 ---"
$srcCfg = Join-Path $srcRoot "config.json"
if (Test-Path $srcCfg) {
    try { $cfg = Get-Content $srcCfg -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $cfg = $null }
    if ($cfg -and $cfg.mcp) {
        $plugins = @()
        if ($cfg.mcp -is [array]) {
            foreach ($entry in $cfg.mcp) {
                if ($entry -match '^([^=]+)=(.*)$') {
                    $n = $Matches[1]; $c = $Matches[2].Trim()
                    $parts = $c -split ' ', 2
                    $plugins += @{ name = $n; command = $parts[0]; args = if ($parts.Count -gt 1) { $parts[1] -split ' ' } else { @() } }
                }
            }
        } elseif ($cfg.mcp -is [PSCustomObject]) {
            foreach ($n in $cfg.mcp.PSObject.Properties.Name) {
                $e = $cfg.mcp.$n
                $plugins += @{ name = $n; command = $e.command; args = if ($e.args) { @($e.args) } else { @() } }
            }
        }
        if ($DryRun) {
            Write-Host "  将添加 $($plugins.Count) 个 MCP 插件"
        } else {
            if (Test-Path $tgtCfgPath) {
                $toml = Get-Content $tgtCfgPath -Raw -Encoding UTF8
                $hasPlugins = ($toml -split "`n" | Where-Object { $_ -match '^\s*\[\[plugins\]\]' }).Count -gt 0
                if (-not $hasPlugins) {
                    $sb = [System.Text.StringBuilder]::new()
                    [void]$sb.AppendLine()
                    [void]$sb.AppendLine("# === Migrated from Reasonix 0.53 ===")
                    foreach ($p in $plugins) {
                        [void]$sb.AppendLine("[[plugins]]")
                        [void]$sb.AppendLine("name = `"$($p.name)`"")
                        if ($p.command -match '^[A-Za-z]:\\') {
                            [void]$sb.AppendLine("command = '$($p.command -replace '\\','/')'")
                        } else {
                            [void]$sb.AppendLine("command = `"$($p.command)`"")
                        }
                        if ($p.args.Count -gt 0) {
                            $qa = ($p.args | ForEach-Object { if ($_ -match '^[A-Za-z]:\\') { "'$($_ -replace '\\','/')'" } else { "`"$_`"" } }) -join ", "
                            [void]$sb.AppendLine("args = [$qa]")
                        }
                        [void]$sb.AppendLine()
                    }
                    $newToml = $toml.TrimEnd() + $sb.ToString()
                    [System.IO.File]::WriteAllText($tgtCfgPath, $newToml, $enc)
                    Write-Host "  已添加 $($plugins.Count) 个插件"
                } else {
                    Write-Host "  MCP 已配置，跳过"
                }
            }
        }
    }
}

# ============================================================
# 2. Session Migration
# ============================================================
Write-Host "--- [2/4] 会话迁移 ---"
$srcSessions = Join-Path $srcRoot "sessions"
if (Test-Path $srcSessions) {
    if (-not $DryRun -and -not (Test-Path $tgtSessions)) { New-Item -ItemType Directory $tgtSessions -Force | Out-Null }
    $jsonlFiles = Get-ChildItem $srcSessions -Filter "*.jsonl" -File | Where-Object { $_.Name -notmatch "_冲突文件_" }
    $migrated = 0
    foreach ($jf in $jsonlFiles) {
        if ($jf.BaseName -match '^(desktop|acp|subagent-sub)-(\d{12})-(\d+)$') {
            $dt = $Matches[2]
            $newBase = $dt.Substring(0,8) + "-" + $dt.Substring(8,4) + "00.000000000-deepseek-v4-flash"
        } else {
            $ts = $jf.LastWriteTimeUtc.ToString('yyyyMMdd-HHmmss')
            $newBase = "${ts}.000000000-deepseek-v4-flash"
        }
        $tgtJsonl = Join-Path $tgtSessions "$newBase.jsonl"
        $tgtMeta  = Join-Path $tgtSessions "$newBase.jsonl.meta"
        $tgtTelem = Join-Path $tgtSessions "$newBase.jsonl.telemetry.json"
        $tgtCkpt  = Join-Path $tgtSessions "$newBase.ckpt"
        if (Test-Path $tgtJsonl) { continue }
        if ($DryRun) { $migrated++; continue }
        
        Copy-Item $jf.FullName $tgtJsonl -Force
        
        # Read old meta
        $oldMeta = $null; $summary = "从0.53导入"
        $oldMetaFile = Join-Path $srcSessions "$($jf.BaseName).meta.json"
        if (Test-Path $oldMetaFile) {
            try {
                $raw = Get-Content $oldMetaFile -Raw -Encoding UTF8
                if ($raw[0] -eq 0xFEFF) { $raw = $raw.Substring(1) }
                $oldMeta = $raw | ConvertFrom-Json
                if ($oldMeta.summary) { $summary = $oldMeta.summary }
            } catch {}
        }
        
        # BranchMeta (snake_case, per BranchMeta struct)
        $createdAt = $jf.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')
        $meta = @{
            id = $newBase; created_at = $createdAt; updated_at = $createdAt
            scope = "global"; workspace_root = $globalWs
            topic_id = ""; topic_title = $summary
        } | ConvertTo-Json -Depth 3
        [System.IO.File]::WriteAllText($tgtMeta, $meta, $enc)
        
        # Extract readFiles from jsonl
        $readFiles = @(); $turnNum = 0
        $jsonlLines = Get-Content $jf.FullName -Encoding UTF8
        for ($li = 0; $li -lt $jsonlLines.Count; $li++) {
            try { $lm = $jsonlLines[$li] | ConvertFrom-Json } catch { continue }
            if ($lm.role -eq 'user') { $turnNum++ }
            if ($lm.role -eq 'assistant' -and $lm.tool_calls) {
                foreach ($tc in $lm.tool_calls) {
                    $tfn = if ($tc.function) { $tc.function.name } else { $tc.name }
                    if ($tfn -ne 'read_file') { continue }
                    try {
                        $argStr = if ($tc.function) { $tc.function.arguments } else { $tc.arguments }
                        $targs = $argStr | ConvertFrom-Json
                        $rec = @{ path = $targs.path; turn = $turnNum; time = 0 }
                        if ($targs.offset) { $rec.offset = [int]$targs.offset }
                        if ($targs.limit)  { $rec.limit  = [int]$targs.limit }
                        $readFiles += $rec
                    } catch {}
                }
            }
        }
        
        # Telemetry
        $pt = if ($oldMeta.lastPromptTokens) { [int]$oldMeta.lastPromptTokens } else { 0 }
        $ct = if ($oldMeta.totalCompletionTokens) { [int]$oldMeta.totalCompletionTokens } else { 0 }
        $ch = if ($oldMeta.cacheHitTokens) { [int]$oldMeta.cacheHitTokens } else { 0 }
        $cm = if ($oldMeta.cacheMissTokens) { [int]$oldMeta.cacheMissTokens } else { 0 }
        $cost = if ($oldMeta.totalCostUsd) { [double]$oldMeta.totalCostUsd } else { 0.0 }
        @{
            version = 2; readFiles = $readFiles
            usage = @{
                promptTokens = $pt; completionTokens = $ct; totalTokens = $pt+$ct
                reasoningTokens = 0; cacheHitTokens = $ch; cacheMissTokens = $cm
                requestCount = 1; elapsedMs = 1; sessionCost = $cost
                sessionCurrency = "CNY"; sessionCostUsd = $cost
            }
        } | ConvertTo-Json -Depth 4 | ForEach-Object { [System.IO.File]::WriteAllText($tgtTelem, $_, $enc) }
        
        # Ckpt
        New-Item -ItemType Directory $tgtCkpt -Force | Out-Null
        $turn = 0
        for ($i = 0; $i -lt $jsonlLines.Count; $i++) {
            try { $msg = $jsonlLines[$i] | ConvertFrom-Json } catch { continue }
            if ($msg.role -ne "user") { continue }
            $prompt = if ($msg.content.Length -gt 500) { $msg.content.Substring(0, 500) } else { $msg.content }
            $ckpt = @{ turn = $turn; time = $createdAt; prompt = $prompt; msgIndex = $i; files = $null } | ConvertTo-Json -Compress
            [System.IO.File]::WriteAllText((Join-Path $tgtCkpt "turn-$turn.json"), $ckpt, $enc)
            $turn++
        }
        $migrated++
    }
    Write-Host "  会话: $migrated 个已迁移"
}

# ============================================================
# 3. Memory Migration
# ============================================================
Write-Host "--- [3/4] 记忆迁移 ---"
$srcMem = Join-Path $srcRoot "memory"
if (Test-Path $srcMem) {
    if (-not $DryRun -and -not (Test-Path $tgtMemory)) { New-Item -ItemType Directory $tgtMemory -Force | Out-Null }
    $memCount = 0
    $srcGlobal = Join-Path $srcMem "global"
    if (Test-Path $srcGlobal) {
        if ($DryRun) { $memCount += (Get-ChildItem $srcGlobal -Filter "*.md" -File -ErrorAction SilentlyContinue).Count }
        else { Copy-Item "$srcGlobal\*.md" $tgtMemory -Force -ErrorAction SilentlyContinue; $memCount = (Get-ChildItem $srcGlobal -Filter "*.md" -File).Count }
    }
    $oldHashDirs = Get-ChildItem $srcMem -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "global" }
    foreach ($oh in $oldHashDirs) {
        if ($DryRun) { $memCount += (Get-ChildItem $oh.FullName -Filter "*.md" -File -ErrorAction SilentlyContinue).Count }
        else { Copy-Item "$($oh.FullName)\*.md" $tgtMemory -Force -ErrorAction SilentlyContinue }
    }
    if (-not $DryRun) {
        $mdFiles = Get-ChildItem $tgtMemory -Filter "*.md" -File | Where-Object { $_.Name -ne "MEMORY.md" } | Sort-Object Name
        if ($mdFiles.Count -gt 0) {
            $lines = @("# Memory", "")
            foreach ($f in $mdFiles) {
                $n = $f.BaseName; $d = ""
                try { $raw = Get-Content $f.FullName -Raw -Encoding UTF8; if ($raw -match 'description:\s*(.+?)(\r?\n|$)') { $d = $Matches[1].Trim() } } catch {}
                if (-not $d) { $d = $n }
                $lines += "- [$d]($($f.Name))"
            }
            [System.IO.File]::WriteAllText((Join-Path $tgtMemory "MEMORY.md"), ($lines -join "`n"), $enc)
        }
    }
    Write-Host "  记忆: $memCount 个文件"
}

# ============================================================
# 4. History-only discovery (don't pollute sidebar)
# ============================================================
Write-Host "--- [4/4] 准备历史发现 ---"
if (-not $DryRun) {
    $enc = [System.Text.UTF8Encoding]::new($false)
    $n = 0
    Get-ChildItem $tgtSessions -Filter '*.jsonl.meta' -File | ForEach-Object {
        $txt = Get-Content $_.FullName -Raw -Encoding UTF8
        if ($txt[0] -eq 0xFEFF) { $txt = $txt.Substring(1) }
        try {
            $m = $txt | ConvertFrom-Json
            $bn = $_.Name -replace '\.jsonl\.meta$', ''
            $tid = 'topic_' + ($bn -replace '\.', '-')
            if ($m.PSObject.Properties.Name -contains 'topic_id') { $m.PSObject.Properties.Remove('topic_id') }
            $m | Add-Member -NotePropertyName 'topic_id' -NotePropertyValue $tid
            $title = $m.topic_title
            if (-not $title -or $title -eq '从0.53导入') { $title = $bn }
            if ($m.PSObject.Properties.Name -contains 'topic_title') { $m.PSObject.Properties.Remove('topic_title') }
            $m | Add-Member -NotePropertyName 'topic_title' -NotePropertyValue $title
            if ($m.PSObject.Properties.Name -contains 'workspace_root') { $m.PSObject.Properties.Remove('workspace_root') }
            $m | Add-Member -NotePropertyName 'workspace_root' -NotePropertyValue ''
            $j = $m | ConvertTo-Json -Depth 3
            [System.IO.File]::WriteAllText($_.FullName, $j, $enc)
            $n++
        } catch {}
    }
    Write-Host "  $n 个会话已分配独立话题ID和标题"
    
    # Clear topic-titles files (prevents orderedTopicIDs from polluting sidebar)
    $ttDir = Join-Path $env:APPDATA "reasonix\global"
    if (-not (Test-Path $ttDir)) { New-Item -ItemType Directory $ttDir -Force | Out-Null }
    $titlesFile = Join-Path $ttDir 'desktop-topic-titles.json'
    [System.IO.File]::WriteAllText($titlesFile, '{}', $enc)
    [System.IO.File]::WriteAllText((Join-Path $ttDir 'desktop-topic-title-sources.json'), '{}', $enc)
    
    # Clean root dir + put migration markers
    $rootDir = Join-Path $env:APPDATA "reasonix\sessions"
    Get-ChildItem $rootDir -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    '' | Set-Content (Join-Path $rootDir '.legacy-imported.v2-routed') -Encoding UTF8
    '' | Set-Content (Join-Path $rootDir '.legacy-imported') -Encoding UTF8
    
    # Delete state files
    Remove-Item (Join-Path $env:APPDATA "reasonix\desktop-projects.json") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $env:APPDATA "reasonix\desktop-tabs.json") -Force -ErrorAction SilentlyContinue
    Write-Host "  状态文件已重置"
}

Write-Host ""
if ($DryRun) { Write-Host "=== 预览完成（未写入任何文件） ===" }
else { Write-Host "=== 完成。启动 1.5，历史对话中可查看迁移的会话。 ===" }
