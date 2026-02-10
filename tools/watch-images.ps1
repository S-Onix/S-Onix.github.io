# 이미지 폴더 감시 및 자동 최적화 스크립트 (PowerShell)

$imgDir = "assets\img\posts"

Write-Host "🔍 이미지 폴더 감시 시작..." -ForegroundColor Blue
Write-Host "💡 Ctrl+C로 종료" -ForegroundColor Yellow
Write-Host ""

# 이미지 최적화 함수
function Optimize-Image {
    param($FilePath)

    $ext = [System.IO.Path]::GetExtension($FilePath).ToLower()

    Write-Host "📸 새 이미지 감지: $FilePath" -ForegroundColor Blue

    # PNG 최적화 (pngquant 사용)
    if ($ext -eq ".png") {
        if (Get-Command pngquant -ErrorAction SilentlyContinue) {
            pngquant --quality 65-80 --ext .png --force "$FilePath" 2>$null
            Write-Host "  ✅ PNG 최적화 완료" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  pngquant이 설치되지 않았습니다." -ForegroundColor Yellow
        }
    }

    # JPG 최적화 (jpegoptim 사용)
    if ($ext -eq ".jpg" -or $ext -eq ".jpeg") {
        if (Get-Command jpegoptim -ErrorAction SilentlyContinue) {
            jpegoptim --max=85 "$FilePath" 2>$null
            Write-Host "  ✅ JPG 최적화 완료" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  jpegoptim이 설치되지 않았습니다." -ForegroundColor Yellow
        }
    }
}

# 폴더가 존재하는지 확인
if (-not (Test-Path $imgDir)) {
    Write-Host "❌ 이미지 폴더를 찾을 수 없습니다: $imgDir" -ForegroundColor Red
    exit 1
}

# FileSystemWatcher 생성
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = Resolve-Path $imgDir
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.Filter = "*.*"

# 이벤트 핸들러 정의
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $ext = [System.IO.Path]::GetExtension($path).ToLower()

    # 이미지 파일만 처리
    if ($ext -eq ".png" -or $ext -eq ".jpg" -or $ext -eq ".jpeg") {
        # 파일이 완전히 쓰여질 때까지 잠시 대기
        Start-Sleep -Milliseconds 500

        # 최적화 실행
        Optimize-Image -FilePath $path
    }
}

# 이벤트 등록
$created = Register-ObjectEvent $watcher "Created" -Action $action
$changed = Register-ObjectEvent $watcher "Changed" -Action $action

Write-Host "✅ 감시 시작됨: $imgDir" -ForegroundColor Green
Write-Host ""

try {
    # 무한 대기 (Ctrl+C로 종료)
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # 정리
    Unregister-Event -SourceIdentifier $created.Name
    Unregister-Event -SourceIdentifier $changed.Name
    $watcher.Dispose()
    Write-Host ""
    Write-Host "✅ 감시 종료" -ForegroundColor Green
}
