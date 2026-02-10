# 새 블로그 포스트 생성 스크립트 (PowerShell)

Write-Host "📝 새 포스트 생성" -ForegroundColor Blue
Write-Host ""

# 제목 입력
$title = Read-Host "포스트 제목을 입력하세요 (한글 가능)"
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
    $slug = Read-Host "URL 슬러그를 입력하세요 (영문, 예: python-tutorial)"

    if ([string]::IsNullOrWhiteSpace($slug)) {
        # 슬러그가 비어있으면 제목에서 자동 생성 (영문/숫자/하이픈만)
        $filename = $title.ToLower() -replace '\s+', '-' -replace '[^a-z0-9-]', '' -replace '--+', '-' -replace '^-|-$', ''
        if ([string]::IsNullOrWhiteSpace($filename)) {
            Write-Host "⚠️  제목에 영문이 없습니다. 영문 슬러그를 입력해주세요." -ForegroundColor Yellow
            continue
        }
        Write-Host "⚠️  슬러그가 비어있습니다. 자동 생성: $filename" -ForegroundColor Yellow
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
            if ($useClean -eq '' -or $useClean -match '^[Yy]$') {
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

# 카테고리 목록 추출
Write-Host ""
Write-Host "사용 가능한 카테고리:" -ForegroundColor Blue

if (Test-Path "_data\blog-taxonomy.yml") {
    # taxonomy 파일에서 추출
    $taxonomyContent = Get-Content "_data\blog-taxonomy.yml" -Raw
    $categoriesSection = $taxonomyContent -split 'tags:' | Select-Object -First 1
    $taxonomyCategories = $categoriesSection | Select-String -Pattern '  - name: (.+)' -AllMatches |
        ForEach-Object { $_.Matches } |
        ForEach-Object { $_.Groups[1].Value }

    Write-Host "  $($taxonomyCategories -join ', ')" -ForegroundColor Green
    Write-Host "  (새 카테고리는 _data\blog-taxonomy.yml에 추가하세요)" -ForegroundColor Yellow
} else {
    # 기존 포스트에서 추출
    $existingCategories = Get-ChildItem "_posts\*.md" -ErrorAction SilentlyContinue |
        Select-String -Pattern "^categories:" |
        ForEach-Object {
            $line = $_.Line -replace 'categories:', ''
            if ($line -match '#') {
                $line = $line.Substring(0, $line.IndexOf('#'))
            }
            $line -replace '[\[\]]', ''
        } |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            $_ -ne '' -and
            $_ -notmatch '^#' -and
            $_ -notmatch '^[A-Z_]+$'
        } |
        Sort-Object -Unique

    if ($existingCategories) {
        Write-Host "  $($existingCategories -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "  (아직 없음)" -ForegroundColor Yellow
    }
}

# 카테고리 입력
$categoriesInput = Read-Host "카테고리 (쉼표로 구분, 예: 개발,Python)"
if ([string]::IsNullOrWhiteSpace($categoriesInput)) {
    $categories = "[블로그]"
} else {
    $cats = $categoriesInput -split ',' | ForEach-Object { $_.Trim() }
    $categories = "[" + ($cats -join ", ") + "]"
}

# 태그 목록 추출
Write-Host ""
Write-Host "사용 가능한 태그:" -ForegroundColor Blue

if (Test-Path "_data\blog-taxonomy.yml") {
    # taxonomy 파일에서 추출
    $taxonomyContent = Get-Content "_data\blog-taxonomy.yml" -Raw
    $tagsSection = ($taxonomyContent -split 'tags:')[1]
    $taxonomyTags = $tagsSection | Select-String -Pattern '  - name: (.+)' -AllMatches |
        ForEach-Object { $_.Matches } |
        ForEach-Object { $_.Groups[1].Value }

    Write-Host "  $($taxonomyTags -join ', ')" -ForegroundColor Green
    Write-Host "  (새 태그는 _data\blog-taxonomy.yml에 추가하세요)" -ForegroundColor Yellow
} else {
    # 기존 포스트에서 추출
    $existingTags = Get-ChildItem "_posts\*.md" -ErrorAction SilentlyContinue |
        Select-String -Pattern "^tags:" |
        ForEach-Object {
            $line = $_.Line -replace 'tags:', ''
            if ($line -match '#') {
                $line = $line.Substring(0, $line.IndexOf('#'))
            }
            $line -replace '[\[\]]', ''
        } |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            $_ -ne '' -and
            $_ -notmatch '^#' -and
            $_ -notmatch '^[A-Z_]+$'
        } |
        Sort-Object -Unique

    if ($existingTags) {
        Write-Host "  $($existingTags -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "  (아직 없음)" -ForegroundColor Yellow
    }
}

# 태그 입력
$tagsInput = Read-Host "태그 (쉼표로 구분, 예: python,tutorial)"
if ([string]::IsNullOrWhiteSpace($tagsInput)) {
    $tags = "[]"
} else {
    $tagArray = $tagsInput -split ',' | ForEach-Object { $_.Trim() }
    $tags = "[" + ($tagArray -join ", ") + "]"
}

# Front Matter 생성
$content = @"
---
title: $title
date: $date $time +0900
categories: $categories
tags: $tags
---

## 소개

여기에 포스트 내용을 작성하세요.

## 본문

### 섹션 1

내용...

### 섹션 2

내용...

## 마무리

마무리 내용...
"@

# 파일 저장
$content | Out-File -FilePath $filepath -Encoding UTF8

Write-Host ""
Write-Host "✅ 포스트가 생성되었습니다!" -ForegroundColor Green
Write-Host "📁 파일 경로: $filepath" -ForegroundColor Blue
Write-Host ""
Write-Host "다음 명령으로 편집하세요:"
Write-Host "  code $filepath" -ForegroundColor Cyan
