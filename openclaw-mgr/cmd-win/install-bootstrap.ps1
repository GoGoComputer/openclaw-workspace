# =============================================================================
# cmd-win/install-bootstrap.ps1 — Windows 부트스트랩 (winget + WSL2 + 함정 검사)
# -----------------------------------------------------------------------------
# 목적   : 새 Windows PC 에서 OpenClaw 를 굴리기 전 단 한 번의 사전 준비
#          ① 실행 정책 점검  ② winget 점검  ③ Git/Docker Desktop/Ollama 설치
#          ④ WSL2 점검 + 미설치 시 `wsl --install` 안내
#          ⑤ 한글 사용자명·공백 경로 같은 함정 사전 경고
# 사용   : .\openclaw.ps1 install-bootstrap        (사용자가 직접 호출)
#          .\openclaw.ps1 install-bootstrap -DryRun (CI 전용 — 실제 설치 안 함)
# 위임   : 본격적인 docker compose 기반 install 은 WSL2 안에서 ./openclaw install
# Copyright 2026 Park Sungmo — MIT License
# =============================================================================

[CmdletBinding()]
param(
    [switch]$DryRun
)

. "$PSScriptRoot\..\lib-win\common.ps1"
Assert-Windows

Write-Title "OpenClaw — Windows 부트스트랩"
Write-Info  "이 스크립트는 ① winget 도구 설치  ② WSL2 활성화 안내까지만 합니다."
Write-Info  "본격적인 OpenClaw 기동은 WSL2 안에서 './openclaw install' 이 처리합니다."
if ($DryRun) { Write-Warn2 "DryRun 모드 — 실제 winget 설치는 하지 않습니다." }
Write-Hr

# ── 1. PowerShell 실행 정책 ──────────────────────────────────────────────────
Write-Title "1. PowerShell 실행 정책 / Execution Policy"
$ep = Get-ExecutionPolicy -Scope CurrentUser
Write-Info "현재 CurrentUser 정책: $ep"
if ($ep -in @('Restricted','AllSigned','Undefined')) {
    Write-Warn2 "현재 정책으로는 .ps1 실행이 차단될 수 있습니다."
    Write-Info  "권장 조치 (관리자 권한 불필요):"
    Write-Info  "    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
} else {
    Write-Ok "정책 OK ($ep) — 로컬 .ps1 실행 가능"
}
Write-Hr

# ── 2. 사용자 환경 함정 사전 점검 ────────────────────────────────────────────
Write-Title "2. 환경 함정 사전 점검 / Common Pitfalls"

# 2-A. 한글/공백 사용자명 → Docker 볼륨 마운트 깨짐
$userPath = $HOME
if ($userPath -match '[^\x00-\x7F]' -or $userPath -match ' ') {
    Write-Warn2 "사용자 홈 경로에 한글/공백이 있습니다: $userPath"
    Write-Info  "  → Docker 볼륨 마운트가 일부 환경에서 깨집니다."
    Write-Info  "  → OpenClaw 디렉터리는 'C:\dev\openclaw' 처럼 ASCII 경로 권장:"
    Write-Info  "      mkdir C:\dev; cd C:\dev; git clone <repo>"
    Write-Info  "      .env 의 OPENCLAW_DIR=C:\dev\openclaw 로 명시"
} else {
    Write-Ok "사용자 홈 경로 ASCII OK ($userPath)"
}

# 2-B. PATH 길이 제한 (260자) — 이미 활성화된 경우만 OK
$lpe = $null
try {
    $lpe = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -ErrorAction SilentlyContinue).LongPathsEnabled
} catch { $lpe = $null }
if ($lpe -eq 1) {
    Write-Ok "Long Path 지원 활성화됨"
} else {
    Write-Warn2 "Long Path 미활성 — 깊은 경로에서 'path too long' 가능"
    Write-Info  "  관리자 PowerShell:  Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' LongPathsEnabled 1"
}
Write-Hr

# ── 3. winget ────────────────────────────────────────────────────────────────
Write-Title "3. winget (Windows Package Manager)"
if (Test-Have winget) {
    $wv = (winget --version 2>$null)
    Write-Ok "winget 사용 가능 ($wv)"
} else {
    Write-Warn2 "winget 미설치 — Windows 10 (1809-) 또는 Server 일 가능성"
    Write-Info  "  Microsoft Store 에서 'App Installer' 설치 후 다시 실행하세요:"
    Write-Info  "    https://apps.microsoft.com/detail/9nblggh4nns1"
    Write-Info  "  또는 GitHub: https://github.com/microsoft/winget-cli/releases/latest"
}
Write-Hr

# ── 4. Git ────────────────────────────────────────────────────────────────────
Write-Title "4. Git for Windows"
if (Test-Have git) {
    $gv = (git --version 2>$null)
    Write-Ok "$gv"
} else {
    Write-Warn2 "git 미설치"
    if ($DryRun) {
        Write-Info "DryRun — 설치 명령:  winget install --id Git.Git -e"
    } elseif (Test-Have winget) {
        if (Confirm-Yn "winget 으로 Git 을 설치하시겠습니까?" -Default 'y') {
            winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
        }
    } else {
        Write-Info "수동 다운로드: https://git-scm.com/download/win"
    }
}
Write-Hr

# ── 5. Docker Desktop ────────────────────────────────────────────────────────
Write-Title "5. Docker Desktop for Windows"
$dockerExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
if (Test-Path $dockerExe) {
    Write-Ok "Docker Desktop 설치됨 ($dockerExe)"
    if (Test-Have docker) {
        try {
            $null = docker info 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "Docker 데몬 응답 OK"
            } else {
                Write-Warn2 "Docker Desktop 이 켜져 있지 않습니다."
                Write-Info  "  Start-Process '$dockerExe'  로 시작 후 30~60초 대기"
            }
        } catch {
            Write-Warn2 "docker info 실행 실패 — Docker Desktop 을 실행하세요"
        }
    }
} else {
    Write-Warn2 "Docker Desktop 미설치"
    if ($DryRun) {
        Write-Info "DryRun — 설치 명령:  winget install --id Docker.DockerDesktop -e"
    } elseif (Test-Have winget) {
        Write-Info "  ⚠ Docker Desktop 은 WSL2 백엔드를 권장합니다 (다음 6단계 먼저 확인)."
        if (Confirm-Yn "winget 으로 Docker Desktop 을 설치하시겠습니까? (~500MB)" -Default 'n') {
            winget install --id Docker.DockerDesktop -e --accept-source-agreements --accept-package-agreements
            Write-Info "설치 후 한 번 로그아웃/재시작이 필요할 수 있습니다."
        }
    } else {
        Write-Info "수동 다운로드: https://www.docker.com/products/docker-desktop/"
    }
}
Write-Hr

# ── 6. WSL2 ──────────────────────────────────────────────────────────────────
Write-Title "6. WSL2 (Windows Subsystem for Linux)"
$wslOk = $false
if (Test-Have wsl) {
    try {
        $wslVer = (wsl --version 2>$null) -join "`n"
        if ($LASTEXITCODE -eq 0 -and $wslVer) {
            Write-Ok "WSL 사용 가능"
            Write-Info ($wslVer.Split("`n") | Select-Object -First 1)
            $wslOk = $true
            # 기본 배포판 확인
            $distros = (wsl -l -q 2>$null) -join "`n"
            if ($distros) {
                Write-Info "설치된 배포판:`n$distros"
            } else {
                Write-Warn2 "기본 배포판이 없습니다 — Ubuntu 권장"
                Write-Info  "  관리자 PowerShell:  wsl --install -d Ubuntu"
            }
        } else {
            Write-Warn2 "WSL 명령은 있으나 활성화되지 않았습니다 — wsl --install 필요"
        }
    } catch {
        Write-Warn2 "WSL 상태 확인 실패: $($_.Exception.Message)"
    }
} else {
    Write-Warn2 "WSL 미설치"
}

if (-not $wslOk) {
    Write-Info "  관리자 PowerShell 에서 한 줄:"
    Write-Info "      wsl --install"
    Write-Info "  설치 후 1회 재부팅이 필요합니다."
    Write-Info "  자세한 안내: https://learn.microsoft.com/windows/wsl/install"
}
Write-Hr

# ── 7. Ollama (Windows 네이티브, 선택) ───────────────────────────────────────
Write-Title "7. Ollama (선택 — 로컬 LLM)"
if (Test-Have ollama) {
    $ov = (ollama --version 2>$null)
    Write-Ok "Ollama 설치됨 — $ov"
    Write-Info "  컨테이너에서는 host.docker.internal:11434 로 접근합니다."
} else {
    Write-Warn2 "Ollama 미설치 (선택 사항)"
    if ($DryRun) {
        Write-Info "DryRun — 설치 명령:  winget install --id Ollama.Ollama -e"
    } elseif (Test-Have winget) {
        if (Confirm-Yn "winget 으로 Ollama (Windows 네이티브) 를 설치하시겠습니까?" -Default 'n') {
            winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements
        }
    } else {
        Write-Info "수동 다운로드: https://ollama.com/download/windows"
    }
}
Write-Hr

# ── 8. 마무리 안내 ───────────────────────────────────────────────────────────
Write-Title "다음 단계 / Next Steps"
Write-Info "이 부트스트랩은 도구 설치만 합니다. 실제 OpenClaw 기동은:"
Write-Info ""
Write-Info "  ① WSL2 안에서 (권장):"
Write-Info "      wsl bash"
Write-Info "      cd /mnt/c/dev/openclaw-workspace/openclaw-mgr   # 또는 본인 경로"
Write-Info "      ./openclaw install"
Write-Info ""
Write-Info "  ② 또는 PowerShell 진입점 위임:"
Write-Info "      .\openclaw.ps1 install"
Write-Info ""
Write-Info "  진단:  .\openclaw.ps1 doctor"
Write-Info "  로그:  .\openclaw.ps1 logs"

if ($DryRun) {
    Write-Hr
    Write-Ok "DryRun 종료 — 실제 변경 없음"
}
