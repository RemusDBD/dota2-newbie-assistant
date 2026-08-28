param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $skillRoot 'dist'
}

$resolvedSkillRoot = [System.IO.Path]::GetFullPath($skillRoot)
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
if (-not $resolvedOutput.StartsWith($resolvedSkillRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must remain inside the skill directory.'
}

New-Item -ItemType Directory -Force -Path $resolvedOutput | Out-Null

$outputFile = Join-Path $resolvedOutput 'ChatGPT-Dota2-Newbie-Assistant-v0.7.0.md'
$archiveFile = Join-Path $resolvedOutput 'ChatGPT-Dota2-Newbie-Assistant-v0.7.0.zip'

$adapter = @'
---
name: chatgpt-dota2-newbie-assistant
version: "0.7.0"
dota_patch: "7.41e"
target: "ChatGPT Project + Live Voice"
---

# ChatGPT Dota 2 新手助手知识包

本文件是可直接上传到 ChatGPT 项目的单文件知识包。它合并了 Dota 2 新手助手的入口规则、当前版本、加点与克制、出装决策、功能品与视野、中文语音别名、输出模式、OpenDota 赛后复盘和数据证据规则。

## ChatGPT 项目适配规则（优先级最高）

1. 用户的日常使用必须支持完全语音：零键盘、零粘贴。首次上传本文件不属于日常输入。
2. 新局时直接接收用户口述的英雄、位置、同路队友和对手；信息不足时先按已知内容回答，只在答案会实质改变时问一个最短问题。
3. 复盘时接收逐位口述的比赛 ID，归一化成数字后按两组复读，等待用户回答“对”再查询。
4. 确认后直接读取 `https://api.opendota.com/api/matches/{match_id}`。不得要求用户粘贴比赛编号、OpenDota 网页或 API 链接。
5. ChatGPT 项目不能运行本地 PowerShell。下文中涉及本地脚本的内容仅说明原始 Skill 的本地实现；在本环境中一律改为直接联网读取 OpenDota，不能假装已经运行脚本。
6. OpenDota 失败、限流或尚未解析时，语音说明当前状态并询问是否重试；不要把文字输入当作兜底，也不要在没有数据时编造复盘。
7. Live 默认先播报 15～30 秒核心结论。不要朗读 Markdown 标记、网址、引用列表或大段原始数据；用户说“详细说、展开出装、展开对线、展开关键节点”时只展开指定部分。
8. 新局速报优先给：技能加点、对线动作、核心出装、最危险技能、功能品/眼、阶段任务和一个最易犯错误。不能为了语音简短而删除核心内容。
9. 每次攻略显示助手版本与 Dota 补丁，但语音只读一次，不朗读来源网址。
10. 本适配规则与下文原始规则冲突时，以本节为准。

## 建议的项目指令

始终把本项目文件 `ChatGPT-Dota2-Newbie-Assistant-v0.7.0.md` 作为 Dota 2 新局指导与赛后复盘的主要规则来源。日常交互全部使用语音；遵守文件顶部的 ChatGPT 项目适配规则，并按需使用文件中的详细决策规则。

## 内置规则源

'@

$sourceFiles = @(
    'SKILL.md',
    'references/current-patch.md',
    'references/beginner-decision-rules.md',
    'references/skills-and-counterplay.md',
    'references/vision-and-consumables.md',
    'references/modes-and-output.md',
    'references/voice-aliases.md',
    'references/match-review.md',
    'references/sources-and-evidence.md',
    'CHANGELOG.md'
)

$sections = [System.Collections.Generic.List[string]]::new()
$sections.Add($adapter.TrimEnd())

foreach ($relativePath in $sourceFiles) {
    $sourcePath = Join-Path $skillRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing package source: $relativePath"
    }

    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $sourcePath
    $sections.Add("`n---`n`n## 来源：$relativePath`n`n$content")
}

$packageContent = ($sections -join "`n").TrimEnd() + "`n"
Set-Content -LiteralPath $outputFile -Value $packageContent -Encoding UTF8

Compress-Archive -LiteralPath $outputFile -DestinationPath $archiveFile -CompressionLevel Optimal -Force

[PSCustomObject]@{
    Markdown = $outputFile
    Archive = $archiveFile
    Bytes = (Get-Item -LiteralPath $outputFile).Length
    Sources = $sourceFiles.Count
}
