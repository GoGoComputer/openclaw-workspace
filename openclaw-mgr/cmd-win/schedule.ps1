# =============================================================================
# cmd-win/schedule.ps1 — 매일 자동 update (Windows 작업 스케줄러)
# -----------------------------------------------------------------------------
# 목적   : macOS launchd plist 와 동등한 매일 update 스케줄을
#          Windows 작업 스케줄러(Register-ScheduledTask) 로 등록.
#          실제 update 명령은 WSL2 안의 './openclaw update' 위임.
# 사용   : .\openclaw.ps1 schedule enable | disable | status
# 환경   : SCHEDULE_TIME=HH:MM (기본 03:00)
# Copyright 2026 Park Sungmo — MIT License
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('enable','disable','status')]
    [string]$Action = 'status'
)

. "$PSScriptRoot\..\lib-win\common.ps1"
Assert-Windows

$TaskName     = 'OpenClawDailyUpdate'
$ScheduleTime = if ($env:SCHEDULE_TIME) { $env:SCHEDULE_TIME } else { '03:00' }

if ($ScheduleTime -notmatch '^\d{2}:\d{2}$') {
    Invoke-Die "SCHEDULE_TIME 형식 오류 (HH:MM): $ScheduleTime"
}

# WSL 안 bash 경로 — Windows 의 OPENCLAW_MGR_DIR 을 /mnt/c/... 로 변환
# PS 5.1 호환: -replace 의 callback 형태(PS 7+) 대신 -match + 분해
$mgrDirWin = $Script:OpenclawMgrDir
if ($mgrDirWin -match '^([A-Za-z]):(.*)$') {
    $mgrDirWsl = '/mnt/' + $Matches[1].ToLower() + ($Matches[2] -replace '\\','/')
} else {
    $mgrDirWsl = $mgrDirWin -replace '\\','/'
}

switch ($Action) {

    'enable' {
        if (-not (Test-Have wsl)) {
            Invoke-Die "WSL 미설치 — 'wsl --install' 후 다시 시도하세요"
        }
        $wslCmd = "cd '$mgrDirWsl' && bash ./openclaw update"
        $action  = New-ScheduledTaskAction `
            -Execute 'wsl.exe' `
            -Argument "-e bash -lc `"$wslCmd`""
        $trigger = New-ScheduledTaskTrigger -Daily -At $ScheduleTime
        # WakeToRun: 절전 상태에서도 깨워서 실행
        # StartWhenAvailable: 컴퓨터가 꺼져 있어 못 돌렸으면 켜진 직후 실행
        $settings = New-ScheduledTaskSettingsSet `
            -WakeToRun `
            -StartWhenAvailable `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -ExecutionTimeLimit (New-TimeSpan -Hours 1)

        # 기존 등록 제거 후 재등록 (멱등)
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action   $action `
            -Trigger  $trigger `
            -Settings $settings `
            -Description "OpenClaw 매일 자동 업데이트 (WSL bash openclaw update)" | Out-Null

        Write-Ok "매일 ${ScheduleTime} 에 자동 업데이트 등록 (Task: $TaskName)"
        Write-Info "절전 상태에서도 깨워서 실행 (WakeToRun + StartWhenAvailable)."
        Write-Info "확인:  Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo"
    }

    'disable' {
        $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Ok "스케줄 해제됨 (Task: $TaskName)"
        } else {
            Write-Info "이미 해제 상태"
        }
    }

    'status' {
        $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existing) {
            $info = Get-ScheduledTaskInfo -TaskName $TaskName
            Write-Ok "활성화됨 (Task: $TaskName, 매일 ${ScheduleTime})"
            Write-Info "  마지막 실행 : $($info.LastRunTime)"
            Write-Info "  마지막 결과 : $($info.LastTaskResult)"
            Write-Info "  다음 실행   : $($info.NextRunTime)"
        } else {
            Write-Warn2 "비활성화됨 — '.\openclaw.ps1 schedule enable' 로 활성화"
        }
    }
}
