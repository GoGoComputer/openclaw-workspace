# =============================================================================
# cmd-win/doctor.ps1 — Windows 네이티브 진단 / Windows-side health check
# -----------------------------------------------------------------------------
# 목적   : WSL2/Docker Desktop/Ollama/포트/경로 함정을 Windows 측에서 점검.
#          WSL 내부의 진단(컨테이너 상태 등)은 'wsl ./openclaw doctor' 가 담당.
# 사용   : .\openclaw.ps1 doctor
# Copyright 2026 Park Sungmo — MIT License
# =============================================================================

[CmdletBinding()]
param()

. "$PSScriptRoot\..\lib-win\common.ps1"
Assert-Windows

function _Row {
    param(
        [Parameter(Mandatory)][string]$Label,
        [ValidateSet('yes','no','warn')][string]$Status,
        [string]$Value = '',
        [string]$Hint  = ''
    )
    switch ($Status) {
        'yes'  { $mark = '✓'; $col = $Script:CGreen  }
        'no'   { $mark = '✗'; $col = $Script:CRed    }
        default{ $mark = '⚠'; $col = $Script:CYellow }
    }
    $valStr = if ($Value) { $Value } else { '—' }
    $line = ("  {0}{1}{2}  {3,-22} {4}{5}{6}" -f `
        $col, $mark, $Script:CReset, $Label, $Script:CDim, $valStr, $Script:CReset)
    [Console]::Error.WriteLine($line)
    if ($Hint) {
        [Console]::Error.WriteLine("       $($Script:CDim)↳ $Hint$($Script:CReset)")
    }
}

Write-Title "OpenClaw 시스템 진단 (Windows)"
Write-Hr

# ── OS / 빌드 ────────────────────────────────────────────────────────────────
$os = Get-CimInstance Win32_OperatingSystem
$build = [int]([Environment]::OSVersion.Version.Build)
_Row "OS"        'yes' "$($os.Caption) (build $build)"
$winOk = $build -ge 19041   # Windows 10 2004+ → WSL2 가능
_Row "WSL2 가능" $(if ($winOk) {'yes'} else {'no'}) `
    $(if ($winOk) {'build 19041+'} else {"build $build (19041 미만)"}) `
    $(if (-not $winOk) {'Windows 업데이트 후 재시도'} else {''})

# ── CPU / RAM ────────────────────────────────────────────────────────────────
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
_Row "CPU" 'yes' $cpu

$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$ramStatus = 'yes'; $ramHint = ''
if ($ramGB -lt 16) { $ramStatus = 'no';   $ramHint = '16GB 이상 권장 (24GB 권장)' }
elseif ($ramGB -lt 24) { $ramStatus = 'warn'; $ramHint = '24GB 권장 — 7B 모델은 동작' }
_Row "RAM" $ramStatus "${ramGB}GB" $ramHint

# ── 디스크 ───────────────────────────────────────────────────────────────────
$drive = (Get-PSDrive -Name C -ErrorAction SilentlyContinue)
if ($drive) {
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    $diskStatus = 'yes'; $diskHint = ''
    if ($freeGB -lt 20) { $diskStatus = 'no';   $diskHint = '20GB 이상 필요 (이미지+모델)' }
    elseif ($freeGB -lt 50) { $diskStatus = 'warn'; $diskHint = '50GB 이상 권장' }
    _Row "C: 여유" $diskStatus "${freeGB}GB" $diskHint
}

Write-Hr

# ── PowerShell 실행 정책 ─────────────────────────────────────────────────────
$ep = Get-ExecutionPolicy -Scope CurrentUser
$epOk = $ep -notin @('Restricted','AllSigned')
_Row "실행 정책" $(if ($epOk) {'yes'} else {'warn'}) "$ep" `
    $(if (-not $epOk) {'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'} else {''})

# ── 사용자 경로 함정 ─────────────────────────────────────────────────────────
$asciiHome = ($HOME -notmatch '[^\x00-\x7F]') -and ($HOME -notmatch ' ')
_Row "홈 경로 ASCII" $(if ($asciiHome) {'yes'} else {'warn'}) $HOME `
    $(if (-not $asciiHome) {"OPENCLAW_DIR 은 'C:\dev\openclaw' 권장 (한글/공백 회피)"} else {''})

Write-Hr

# ── 도구 설치 ────────────────────────────────────────────────────────────────
_Row "winget" $(if (Test-Have winget) {'yes'} else {'no'}) '' `
    $(if (-not (Test-Have winget)) {'Microsoft Store: App Installer'} else {''})

_Row "git" $(if (Test-Have git) {'yes'} else {'no'}) `
    $(if (Test-Have git) {(git --version 2>$null)} else {''}) `
    $(if (-not (Test-Have git)) {'winget install Git.Git'} else {''})

# ── Docker Desktop ───────────────────────────────────────────────────────────
$dockerInstalled = Test-Path "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
_Row "Docker Desktop" $(if ($dockerInstalled) {'yes'} else {'no'}) '' `
    $(if (-not $dockerInstalled) {'winget install Docker.DockerDesktop'} else {''})

$dockerUp = $false
if (Test-Have docker) {
    try {
        $null = docker info 2>$null
        $dockerUp = ($LASTEXITCODE -eq 0)
    } catch { $dockerUp = $false }
}
_Row "Docker 데몬" $(if ($dockerUp) {'yes'} else {'no'}) '' `
    $(if (-not $dockerUp) {'Docker Desktop 실행 후 30~60초 대기'} else {''})

if ($dockerUp) {
    try {
        $cv = (docker compose version 2>$null)
        _Row "Compose v2" $(if ($LASTEXITCODE -eq 0) {'yes'} else {'no'}) ($cv -join ' ')
    } catch { _Row "Compose v2" 'no' '' '' }
}

# ── WSL2 ─────────────────────────────────────────────────────────────────────
$wslReady = $false
if (Test-Have wsl) {
    try {
        $wv = (wsl --version 2>$null) -join ' '
        if ($LASTEXITCODE -eq 0 -and $wv) {
            $wslReady = $true
            $defLine  = ($wv -split "`n" | Select-Object -First 1)
            _Row "WSL" 'yes' $defLine
            $distros = (wsl -l -q 2>$null) -join ', '
            $distrosStr = if ($distros) { $distros } else { '없음' }
            _Row "  ↳ 배포판" $(if ($distros) {'yes'} else {'warn'}) `
                $distrosStr `
                $(if (-not $distros) {'wsl --install -d Ubuntu'} else {''})
        }
    } catch {
        Write-Debug "WSL probe failed: $($_.Exception.Message)"
    }
}
if (-not $wslReady) {
    _Row "WSL" 'no' '' '관리자 PowerShell:  wsl --install'
}

# ── Ollama (선택) ────────────────────────────────────────────────────────────
$ollamaInstalled = Test-Have ollama
_Row "Ollama" $(if ($ollamaInstalled) {'yes'} else {'warn'}) `
    $(if ($ollamaInstalled) {(ollama --version 2>$null)} else {'미설치 (선택)'}) `
    $(if (-not $ollamaInstalled) {'winget install Ollama.Ollama (호스트 네이티브)'} else {''})

if ($ollamaInstalled) {
    $ollamaResp = $false
    try {
        $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        $ollamaResp = ($r.StatusCode -eq 200)
    } catch { $ollamaResp = $false }
    _Row "  ↳ 데몬" $(if ($ollamaResp) {'yes'} else {'warn'}) `
        '127.0.0.1:11434' `
        $(if (-not $ollamaResp) {'Ollama 앱 실행 (트레이 아이콘 확인)'} else {''})
}

Write-Hr

# ── 포트 충돌 ────────────────────────────────────────────────────────────────
$ports = @(8000, 18789, 11434)
$conflicts = @()
foreach ($p in $ports) {
    try {
        $c = Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue
        if ($c) { $conflicts += "$p" }
    } catch {
        Write-Debug "Port $p probe failed: $($_.Exception.Message)"
    }
}
if ($conflicts.Count -eq 0) {
    _Row "포트" 'yes' "$($ports -join ', ') 모두 사용 가능"
} else {
    _Row "포트 충돌" 'warn' ($conflicts -join ', ') 'Get-NetTCPConnection -LocalPort <포트> 로 점유 프로세스 확인'
}

Write-Hr

# ── 종합 ─────────────────────────────────────────────────────────────────────
$issues = 0
if (-not $dockerInstalled) { $issues++ }
if (-not $dockerUp)        { $issues++ }
if (-not $wslReady)        { $issues++ }
if (-not (Test-Have git))  { $issues++ }

if ($issues -eq 0) {
    Write-Ok "Windows 측 점검 통과 — 다음:  wsl bash -c './openclaw doctor'  로 컨테이너 측 진단"
} else {
    Write-Warn2 "$issues 개 항목이 미설정입니다 — '.\openclaw.ps1 install-bootstrap' 으로 자동 안내됩니다"
}
