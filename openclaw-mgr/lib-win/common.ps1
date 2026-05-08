# =============================================================================
# lib-win/common.ps1 — Windows/PowerShell 공용 유틸리티
# -----------------------------------------------------------------------------
# 목적   : openclaw.ps1 / cmd-win/*.ps1 가 공유하는 헬퍼 함수
# 사용   : . "$PSScriptRoot\..\lib-win\common.ps1"   (dot-source)
# 톤     : lib/common.sh 의 info/ok/warn/err/die/title 와 동일 출력
# 호환   : PowerShell 5.1 (Windows 10/11 기본) 및 PowerShell 7+
# Copyright 2026 Park Sungmo — MIT License
# =============================================================================

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# wsl.exe 등 일부 Windows native 명령이 UTF-16LE 로 출력하면 PS 콘솔에서 mojibake.
# 콘솔 출력 인코딩을 UTF-8 (no BOM) 로 통일. 콘솔 핸들이 없으면 무시.
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
} catch {
    Write-Debug "Skip OutputEncoding setup: $($_.Exception.Message)"
}

# ── 사용자 상태 디렉터리 (lib/common.sh 와 동일 위치 — WSL 과 공유 가능) ──────
# Windows: $HOME = C:\Users\<name>  → ~/.openclaw-mgr 가 같은 위치
$Script:OpenclawMgrHome = if ($env:OPENCLAW_MGR_HOME) {
    $env:OPENCLAW_MGR_HOME
} else {
    Join-Path $HOME '.openclaw-mgr'
}
$Script:StateFile = Join-Path $Script:OpenclawMgrHome 'state'
$Script:LogDir    = Join-Path $Script:OpenclawMgrHome 'logs'

if (-not (Test-Path $Script:LogDir)) {
    New-Item -ItemType Directory -Force -Path $Script:LogDir | Out-Null
}
if (-not (Test-Path $Script:StateFile)) {
    New-Item -ItemType File -Force -Path $Script:StateFile | Out-Null
}

# ── 색상 (호스트가 ANSI 지원할 때만, NO_COLOR 환경변수 존중) ──────────────────
# PowerShell 5.1 호환: `e (PS7+) 대신 [char]27, SupportsVirtualTerminal 안전 접근.
$Script:Esc = [char]27
$Script:UseColor = $false
try {
    if ($Host -and $Host.UI -and $Host.UI.PSObject.Properties['SupportsVirtualTerminal']) {
        $Script:UseColor = [bool]$Host.UI.SupportsVirtualTerminal -and (-not $env:NO_COLOR)
    } else {
        # PS 5.1 / older ConHost 폴백 — Windows 10 1607+ 면 ANSI escape 동작
        $build = [int][Environment]::OSVersion.Version.Build
        $Script:UseColor = ($build -ge 14393) -and (-not $env:NO_COLOR)
    }
} catch {
    $Script:UseColor = $false
}
function _c([string]$Code) {
    if ($Script:UseColor) { "$($Script:Esc)[${Code}m" } else { '' }
}

$Script:CReset  = (_c '0')
$Script:CBold   = (_c '1')
$Script:CDim    = (_c '2')
$Script:CRed    = (_c '31')
$Script:CGreen  = (_c '32')
$Script:CYellow = (_c '33')
$Script:CBlue   = (_c '34')
$Script:CCyan   = (_c '36')

# ── 로깅 (모두 stderr — stdout 은 데이터/파이프용으로 깨끗하게) ────────────────
function Write-Info  { param([string]$Msg) [Console]::Error.WriteLine("$($Script:CBlue)•$($Script:CReset) $Msg") }
function Write-Ok    { param([string]$Msg) [Console]::Error.WriteLine("$($Script:CGreen)✓$($Script:CReset) $Msg") }
function Write-Warn2 { param([string]$Msg) [Console]::Error.WriteLine("$($Script:CYellow)⚠$($Script:CReset) $Msg") }
function Write-Err2  { param([string]$Msg) [Console]::Error.WriteLine("$($Script:CRed)✗$($Script:CReset) $Msg") }
function Invoke-Die  { param([string]$Msg) Write-Err2 $Msg; exit 1 }
function Write-Hr    { [Console]::Error.WriteLine("$($Script:CDim)────────────────────────────────────────$($Script:CReset)") }
function Write-Title { param([string]$Msg) [Console]::Error.WriteLine(""); [Console]::Error.WriteLine("$($Script:CBold)$($Script:CCyan)» $Msg$($Script:CReset)") }

# bash 톤과 동일한 짧은 별칭 (info/ok/warn/err/die/title)
Set-Alias -Name info  -Value Write-Info  -Scope Global
Set-Alias -Name ok    -Value Write-Ok    -Scope Global
Set-Alias -Name warn  -Value Write-Warn2 -Scope Global
Set-Alias -Name err   -Value Write-Err2  -Scope Global
Set-Alias -Name die   -Value Invoke-Die  -Scope Global
Set-Alias -Name hr    -Value Write-Hr    -Scope Global
Set-Alias -Name title -Value Write-Title -Scope Global

# ── 명령 존재 확인 (bash 의 `have`) ──────────────────────────────────────────
function Test-Have {
    param([Parameter(Mandatory)][string]$Name)
    [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ── 확인 프롬프트 (bash 의 `confirm`) ────────────────────────────────────────
# Confirm-Yn "메시지" -Default 'y'  →  Yes 면 $true
function Confirm-Yn {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('y','n')][string]$Default = 'n'
    )
    $hint = if ($Default -eq 'y') { '[Y/n]' } else { '[y/N]' }
    if ($env:NONINTERACTIVE -eq '1' -or -not [Environment]::UserInteractive) {
        return ($Default -eq 'y')
    }
    [Console]::Error.Write("$($Script:CYellow)? $Message $hint$($Script:CReset) ")
    $reply = (Read-Host).Trim()
    if (-not $reply) { $reply = $Default }
    return ($reply -match '^(y|Y|yes|YES)$')
}

# ── 멱등 단계 관리 (lib/common.sh 의 state_has / state_mark / run_step) ──────
function Test-StateHas {
    param([Parameter(Mandatory)][string]$Key)
    Select-String -Path $Script:StateFile -Pattern "^$([regex]::Escape($Key))=done$" -SimpleMatch:$false -Quiet
}
function Set-StateMark {
    param([Parameter(Mandatory)][string]$Key)
    if (-not (Test-StateHas $Key)) {
        Add-Content -Path $Script:StateFile -Value "$Key=done" -Encoding utf8
    }
}
function Invoke-Step {
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][scriptblock]$Action
    )
    if (Test-StateHas $Key) {
        Write-Info "[skip] $Description  (이미 완료: $Key)"
        return $true
    }
    Write-Title $Description
    try {
        & $Action
        Set-StateMark $Key
        Write-Ok "완료: $Key"
        return $true
    } catch {
        Write-Err2 "단계 실패: $Key — $($_.Exception.Message)"
        return $false
    }
}

# ── OS 검증 (Windows 전용 .ps1) ──────────────────────────────────────────────
function Assert-Windows {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Invoke-Die "PowerShell 5.1 이상이 필요합니다. (감지: $($PSVersionTable.PSVersion))"
    }
    $isWin = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }
    if (-not $isWin) {
        Invoke-Die "이 스크립트는 Windows 전용입니다. macOS 는 ./openclaw 를 쓰세요."
    }
}

# ── UTF-8 no-BOM + LF 파일 쓰기 (compose.network.yml 같은 동적 yaml 안전) ────
function Write-FileUtf8NoBomLF {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )
    $normalized = $Content -replace "`r`n", "`n"
    $utf8NoBom  = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

# ── 진입 디렉터리 (bash 의 OPENCLAW_MGR_DIR) ─────────────────────────────────
# 스크립트가 lib-win 안에 있으므로 부모 폴더가 openclaw-mgr.
$Script:OpenclawMgrDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:OPENCLAW_MGR_DIR  = $Script:OpenclawMgrDir
