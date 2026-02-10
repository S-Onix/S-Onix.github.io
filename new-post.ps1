# Jekyll 새 포스트 생성 스크립트
param(
    [Parameter(Mandatory=$true)]
    [string]$Title
)

# 현재 날짜와 시간
$date = Get-Date -Format "yyyy-MM-dd"
$datetime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 제목을 URL 친화적으로 변환
$urlTitle = $Title.ToLower() -replace '\s+', '-' -replace '[^\w\-가-힣]', ''

# 파일명 생성
$filename = "_posts/${date}-${urlTitle}.md"

# 템플릿 내용
$content = @"
---
layout: post
title: "$Title"
date: $datetime +0900
categories: []
tags: []
---

## 서론

여기에 내용을 작성하세요...

## 본론

### 소제목 1

내용...

## 결론

마무리...
"@

# 파일 생성
New-Item -Path $filename -ItemType File -Value $content -Force

Write-Host "✅ 포스트가 생성되었습니다: $filename" -ForegroundColor Green
Write-Host "📝 Typora로 열기: typora `"$filename`"" -ForegroundColor Cyan
