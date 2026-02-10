# Typora용 블로그 포스트 생성 스크립트 (PowerShell)

Write-Host "📝 Typora용 새 포스트 생성" -ForegroundColor Blue
Write-Host ""

# 제목 입력
$title = Read-Host "포스트 제목을 입력하세요"
if ([string]::IsNullOrWhiteSpace($title)) {
    Write-Host "⚠️  제목이 비어있습니다. 종료합니다." -ForegroundColor Yellow
    exit 1
}

# URL 슬러그 입력
Write-Host ""
Write-Host "💡 팁: 제목이 '$title'인 경우," -ForegroundColor Yellow
Write-Host "   좋은 예: java-tutorial, python-basics, book-review-1" -ForegroundColor Yellow
Write-Host ""

while ($true) {
    $slug = Read-Host "URL 슬러그 (영문, 예: python-tutorial)"

    if ([string]::IsNullOrWhiteSpace($slug)) {
        # 슬러그가 비어있으면 제목에서 자동 생성 (영문/숫자/하이픈만)
        $filename = $title.ToLower() -replace '\s+', '-' -replace '[^a-z0-9-]', '' -replace '--+', '-' -replace '^-|-$', ''
        if ([string]::IsNullOrWhiteSpace($filename)) {
            Write-Host "⚠️  제목에 영문이 없습니다. 영문 슬러그를 입력해주세요." -ForegroundColor Yellow
            continue
        }
        break
    } else {
        # 한글 포함 여부 확인
        if ($slug -match '[가-힣]') {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
            Write-Host "⚠️  한글이 감지되었습니다!" -ForegroundColor Yellow
            Write-Host "💡 제목 '$title'을(를) 영문으로 표현하면?" -ForegroundColor Blue
            Write-Host "   예시:" -ForegroundColor Green
            Write-Host "   • 자바의 신 1장 → java-god-chapter-1" -ForegroundColor Green
            Write-Host "   • 파이썬 기초 → python-basics" -ForegroundColor Green
            Write-Host "   • 알고리즘 정렬 → algorithm-sorting" -ForegroundColor Green
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
            continue
        }

        # 입력된 슬러그 검증 (영문, 숫자, 하이픈만 허용)
        $cleanSlug = $slug.ToLower() -replace '[^a-z0-9-]', '' -replace '--+', '-' -replace '^-|-$', ''
        if ($slug -ne $cleanSlug) {
            Write-Host "⚠️  특수문자가 포함되어 있습니다." -ForegroundColor Yellow
            Write-Host "💡 자동 정리된 슬러그: $cleanSlug" -ForegroundColor Blue
            $useClean = Read-Host "이 슬러그를 사용하시겠습니까? (Y/n)"
            if ($useClean -match '^[Yy]$' -or [string]::IsNullOrWhiteSpace($useClean)) {
                $filename = $cleanSlug
                break
            } else {
                continue
            }
        }
        $filename = $cleanSlug
        break
    }
}

$date = Get-Date -Format "yyyy-MM-dd"
$time = Get-Date -Format "HH:mm:ss"
$filepath = "_posts\$date-$filename.md"
$imgDir = "assets\img\posts\$date-$filename"

# 카테고리 목록 보여주기
Write-Host ""
Write-Host "📂 사용 가능한 카테고리:" -ForegroundColor Blue
if (Test-Path "_data\blog-taxonomy.yml") {
    $taxonomyContent = Get-Content "_data\blog-taxonomy.yml" -Raw
    $categoriesSection = $taxonomyContent -split "tags:" | Select-Object -First 1
    $categories = $categoriesSection -split "`n" | Where-Object { $_ -match "^\s+- name:" } | ForEach-Object {
        $_ -replace ".*name:\s*", ""
    }
    if ($categories) {
        Write-Host "  $($categories -join ', ')" -ForegroundColor Green
    }
} else {
    $existingCategories = Get-ChildItem "_posts\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match "(?m)^categories:\s*\[([^\]]+)\]") {
            $matches[1] -split "," | ForEach-Object { $_.Trim() }
        }
    } | Sort-Object -Unique
    if ($existingCategories) {
        Write-Host "  $($existingCategories -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "  (아직 없음)" -ForegroundColor Yellow
    }
}

# 태그 목록 보여주기
Write-Host ""
Write-Host "🏷️  사용 가능한 태그:" -ForegroundColor Blue
if (Test-Path "_data\blog-taxonomy.yml") {
    $taxonomyContent = Get-Content "_data\blog-taxonomy.yml" -Raw
    $tagsSection = $taxonomyContent -split "tags:" | Select-Object -Last 1
    $tags = $tagsSection -split "`n" | Where-Object { $_ -match "^\s+- name:" } | ForEach-Object {
        $_ -replace ".*name:\s*", ""
    }
    if ($tags) {
        Write-Host "  $($tags -join ', ')" -ForegroundColor Green
    }
} else {
    $existingTags = Get-ChildItem "_posts\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match "(?m)^tags:\s*\[([^\]]+)\]") {
            $matches[1] -split "," | ForEach-Object { $_.Trim() }
        }
    } | Sort-Object -Unique
    if ($existingTags) {
        Write-Host "  $($existingTags -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "  (아직 없음)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "💡 Typora에서 Front Matter의 categories와 tags를 수정하세요!" -ForegroundColor Yellow
Write-Host ""

# 이미지 폴더 생성
New-Item -ItemType Directory -Force -Path $imgDir | Out-Null

# Front Matter 템플릿 생성
$content = @"
---
title: $title
date: $date $time +0900
categories: []  # 예: [개발, Python]
tags: []        # 예: [python, tutorial]
image:
  path: /$($imgDir -replace '\\', '/')/cover.jpg
  alt: $title
---

## 📌 소개

여기에 내용을 작성하세요.

## 📝 본문

### 섹션 1

내용...

## 🎯 마무리

마무리 내용...

---

**관련 포스트:**
- [링크1](#)
- [링크2](#)
"@

$content | Out-File -FilePath $filepath -Encoding UTF8

Write-Host ""
Write-Host "✅ 포스트가 생성되었습니다!" -ForegroundColor Green
Write-Host "📁 포스트: $filepath" -ForegroundColor Blue
Write-Host "🖼️  이미지 폴더: $imgDir" -ForegroundColor Blue
Write-Host ""
Write-Host "💡 이미지는 다음 경로에 저장하세요:" -ForegroundColor Yellow
Write-Host "   $imgDir\"

# 이미지 자동 최적화 여부 확인
Write-Host ""
$startWatch = Read-Host "이미지 자동 최적화를 실행하시겠습니까? (Y/n)"
if ($startWatch -match '^[Yy]$' -or [string]::IsNullOrWhiteSpace($startWatch)) {
    # 이미 실행 중인지 확인
    $watchProcess = Get-Process -Name pwsh,powershell -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*watch-images.ps1*" }

    if ($watchProcess) {
        Write-Host "✅ 이미지 감시가 이미 실행 중입니다." -ForegroundColor Green
    } else {
        # 백그라운드로 실행
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        Start-Process pwsh -ArgumentList "-NoProfile -WindowStyle Hidden -File `"$scriptDir\watch-images.ps1`"" -WindowStyle Hidden
        Write-Host "✅ 이미지 자동 최적화가 시작되었습니다." -ForegroundColor Green
        Write-Host "💡 종료하려면: Get-Process pwsh | Where-Object { `$_.CommandLine -like '*watch-images*' } | Stop-Process" -ForegroundColor Yellow
    }
}

# Typora로 자동 열기
Write-Host ""
$typoraPath = "C:\Program Files\Typora\Typora.exe"
if (Test-Path $typoraPath) {
    $openTypora = Read-Host "Typora로 바로 여시겠습니까? (Y/n)"
    if ($openTypora -match '^[Yy]$' -or [string]::IsNullOrWhiteSpace($openTypora)) {
        Start-Process $typoraPath -ArgumentList $filepath
        Write-Host ""
        Write-Host "✅ Typora가 열렸습니다!" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "💡 Typora로 열기:" -ForegroundColor Yellow
    Write-Host "   typora `"$filepath`""
}
