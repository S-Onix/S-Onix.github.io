# 이미지 감시 스크립트 종료

Write-Host "🛑 이미지 감시 종료 중..." -ForegroundColor Yellow

# watch-images.ps1 프로세스 찾기
$watchProcesses = Get-Process -Name pwsh,powershell -ErrorAction SilentlyContinue |
    Where-Object {
        try {
            $_.CommandLine -like "*watch-images.ps1*"
        } catch {
            $false
        }
    }

if (-not $watchProcesses) {
    Write-Host "⚠️  실행 중인 이미지 감시 프로세스가 없습니다." -ForegroundColor Yellow
    exit 0
}

# 프로세스 종료
foreach ($process in $watchProcesses) {
    try {
        Stop-Process -Id $process.Id -Force
        Write-Host "✅ 프로세스 종료: PID $($process.Id)" -ForegroundColor Green
    } catch {
        Write-Host "❌ 프로세스 종료 실패: PID $($process.Id)" -ForegroundColor Red
    }
}

# 잠시 대기
Start-Sleep -Seconds 1

# 확인
$remainingProcesses = Get-Process -Name pwsh,powershell -ErrorAction SilentlyContinue |
    Where-Object {
        try {
            $_.CommandLine -like "*watch-images.ps1*"
        } catch {
            $false
        }
    }

if ($remainingProcesses) {
    Write-Host "❌ 일부 프로세스를 종료하지 못했습니다." -ForegroundColor Red
    Write-Host "💡 작업 관리자에서 수동으로 종료해주세요." -ForegroundColor Yellow
} else {
    Write-Host "✅ 모든 이미지 감시 프로세스가 종료되었습니다." -ForegroundColor Green
}
