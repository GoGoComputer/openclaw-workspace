# =============================================================================
# openclaw.ps1 — Windows 진입점 / Windows entry-point dispatcher
# -----------------------------------------------------------------------------
# 사용법: .\openclaw.ps1 <subcommand> [args...]
# 전략 : WSL2-first
#   ① install-bootstrap / doctor / schedule  → Windows 네이티브 .ps1
#   ② 그 외 (install / start / stop / logs / update / 기타)
#       → WSL 안의 bash ./openclaw 로 위임 (코드 중복 회피)
# Copyright 2026 Park Sungmo — MIT License
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'menu',

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Rest = @()
)

. "$PSScriptRoot\lib-win\common.ps1"

$Version = '0.2.21'

# help / version 은 OS 무관하게 동작 (Linux pwsh 환경에서도 사용법 확인 가능).
# 그 외 실 명령(install/start/...) 은 각 case 에서 Assert-Windows 로 차단.

# ── Windows 경로 → WSL /mnt/<drive>/... 변환 ─────────────────────────────────
function ConvertTo-WslPath {
    param([Parameter(Mandatory)][string]$WinPath)
    $resolved = (Resolve-Path -LiteralPath $WinPath).Path
    if ($resolved -match '^([A-Za-z]):(.*)$') {
        $drive = $Matches[1].ToLower()
        $rest  = $Matches[2] -replace '\\','/'
        return "/mnt/$drive$rest"
    }
    return ($resolved -replace '\\','/')
}

# ── WSL 사용 가능 여부 (배포판까지 있어야 진짜 사용 가능) ───────────────────
function Test-WslReady {
    if (-not (Test-Have wsl)) { return $false }
    try {
        $null = wsl --status 2>$null
        if ($LASTEXITCODE -ne 0) { return $false }
        $distros = (wsl -l -q 2>$null) -join ''
        return [bool]$distros
    } catch {
        return $false
    }
}

# ── WSL 안에서 ./openclaw 호출 ──────────────────────────────────────────────
function Invoke-WslOpenclaw {
    param([Parameter(Mandatory)][string[]]$ArgsList)

    if (-not (Test-WslReady)) {
        Write-Err2 "WSL2 가 준비되어 있지 않습니다."
        Write-Info ""
        Write-Info "  ① 부트스트랩 실행:  .\openclaw.ps1 install-bootstrap"
        Write-Info "  ② 관리자 PowerShell:  wsl --install"
        Write-Info "  ③ 재부팅 후 다시 시도"
        exit 2
    }

    $mgrWsl = ConvertTo-WslPath $PSScriptRoot

    # 인자 escape — single-quote 가 들어간 인자는 거의 없지만 안전하게.
    $escapedArgs = @()
    foreach ($a in $ArgsList) {
        if ($null -eq $a) { continue }
        $escapedArgs += "'$($a -replace "'", "'\''")'"
    }
    $argString = $escapedArgs -join ' '

    $bashCmd = "cd '$mgrWsl' && ./openclaw $argString"
    Write-Info "[WSL 위임] $bashCmd"
    & wsl.exe -e bash -lc $bashCmd
    exit $LASTEXITCODE
}

function Show-Usage {
@"
openclaw — OpenClaw 셀프호스트 자동화 (macOS · Windows/WSL2)

사용법:
  .\openclaw.ps1 <명령> [옵션]

Windows 네이티브 (PowerShell 측):
  install-bootstrap   winget · WSL2 · Git · Docker Desktop · Ollama 사전 설치 안내
  doctor              Windows 측 진단 (WSL2/Docker Desktop/포트/경로 함정)
  schedule e|d|s      매일 자동 update 작업 스케줄러 (Register-ScheduledTask)
  version             버전 출력
  help                이 도움말

WSL2 위임 (WSL 안의 bash openclaw 가 처리):
  install             OpenClaw 부족분 자동 설치 + 컨테이너 기동
  start               컨테이너 시작
  stop                컨테이너 정지
  logs                컨테이너 로그
  update              저장소 pull + 이미지/모델 갱신
  backup [--name N]   현재 데이터 백업
  restore <file>      백업 복원
  network <mode>      네트워크 격리 토글
  models              로컬 LLM 모델 관리
  clean               메모리·디스크 정리
  menu                대화형 메뉴
  uninstall           OpenClaw 제거

빠른 시작:
  .\openclaw.ps1 install-bootstrap   # 처음 한 번
  .\openclaw.ps1 doctor              # Windows 측 점검
  .\openclaw.ps1 install             # WSL 안에서 본격 설치
  .\openclaw.ps1 logs                # 컨테이너 로그

문서: https://github.com/GoGoComputer/openclaw-workspace
"@ | Write-Host
}

# ── 라우팅 ───────────────────────────────────────────────────────────────────
switch -Regex ($Command) {

    '^(-h|--help|help)$' {
        Show-Usage
        exit 0
    }

    '^(-v|--version|version)$' {
        Write-Host "openclaw-mgr $Version (Windows)"
        exit 0
    }

    '^install-bootstrap$' {
        Assert-Windows
        & "$PSScriptRoot\cmd-win\install-bootstrap.ps1" @Rest
        exit $LASTEXITCODE
    }

    '^doctor$' {
        Assert-Windows
        # 1. Windows 측 doctor
        & "$PSScriptRoot\cmd-win\doctor.ps1"
        $winRc = $LASTEXITCODE

        # 2. WSL 측 doctor (있으면)
        if (Test-WslReady) {
            Write-Hr
            Write-Info "WSL 측 진단도 실행합니다 (컨테이너·저장소 상태)..."
            Invoke-WslOpenclaw -ArgsList @('doctor')
        } else {
            Write-Hr
            Write-Warn2 "WSL2 미준비 — 컨테이너 측 진단은 wsl --install 후 다시 실행"
        }
        exit $winRc
    }

    '^schedule$' {
        Assert-Windows
        & "$PSScriptRoot\cmd-win\schedule.ps1" @Rest
        exit $LASTEXITCODE
    }

    # 그 외 모든 서브커맨드는 WSL bash 로 위임 (install, start, stop, logs, ...)
    '^(install|start|stop|logs|update|backup|restore|uninstall|clean|network|menu|models|self-update|ai-update|upgrade)$' {
        Assert-Windows
        Invoke-WslOpenclaw -ArgsList (@($Command) + $Rest)
    }

    default {
        Write-Err2 "알 수 없는 명령: $Command"
        Show-Usage
        exit 2
    }
}
