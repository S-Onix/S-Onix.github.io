# 포스트의 카테고리/태그를 taxonomy.yml과 동기화

$taxonomyFile = "_data\blog-taxonomy.yml"

Write-Host "🔄 Taxonomy 동기화 중..." -ForegroundColor Blue

# 포스트에서 모든 카테고리 추출
$postCategories = Get-ChildItem "_posts\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "(?m)^categories:\s*\[([^\]]+)\]") {
        $matches[1] -split "," | ForEach-Object {
            $_.Trim() -replace '#.*$', ''
        } | Where-Object { $_ -ne '' }
    }
} | Sort-Object -Unique

# 포스트에서 모든 태그 추출
$postTags = Get-ChildItem "_posts\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "(?m)^tags:\s*\[([^\]]+)\]") {
        $matches[1] -split "," | ForEach-Object {
            $_.Trim() -replace '#.*$', ''
        } | Where-Object { $_ -ne '' }
    }
} | Sort-Object -Unique

# taxonomy에 있는 카테고리 추출
$taxonomyContent = Get-Content $taxonomyFile -Raw
$categoriesSection = $taxonomyContent -split "tags:" | Select-Object -First 1
$taxonomyCategories = $categoriesSection -split "`n" | Where-Object { $_ -match "^\s+- name:" } | ForEach-Object {
    $_ -replace ".*name:\s*", ""
}

# taxonomy에 있는 태그 추출
$tagsSection = $taxonomyContent -split "tags:" | Select-Object -Last 1
$taxonomyTags = $tagsSection -split "`n" | Where-Object { $_ -match "^\s+- name:" } | ForEach-Object {
    $_ -replace ".*name:\s*", ""
}

# 새로운 카테고리 찾기
$newCategories = $postCategories | Where-Object { $taxonomyCategories -notcontains $_ }

# 새로운 태그 찾기
$newTags = $postTags | Where-Object { $taxonomyTags -notcontains $_ }

# 새로운 카테고리 추가
if ($newCategories.Count -gt 0) {
    Write-Host "📂 새로운 카테고리 발견:" -ForegroundColor Yellow
    $content = Get-Content $taxonomyFile
    $newLines = @()

    foreach ($line in $content) {
        if ($line -match "^# 태그 정의") {
            # 새 카테고리 추가
            foreach ($category in $newCategories) {
                Write-Host "  + $category" -ForegroundColor Green
                $newLines += "  - name: $category"
                $newLines += "    description: $category 관련"
                $newLines += ""
            }
        }
        $newLines += $line
    }

    $newLines | Set-Content $taxonomyFile -Encoding UTF8
}

# 새로운 태그 추가
if ($newTags.Count -gt 0) {
    Write-Host "🏷️  새로운 태그 발견:" -ForegroundColor Yellow
    $content = Get-Content $taxonomyFile
    $newLines = @()

    foreach ($line in $content) {
        if ($line -match "^# 사용 예시:") {
            # 새 태그 추가
            foreach ($tag in $newTags) {
                Write-Host "  + $tag" -ForegroundColor Green
                $newLines += "  - name: $tag"
                $newLines += "    description: $tag 관련"
                $newLines += ""
            }
        }
        $newLines += $line
    }

    $newLines | Set-Content $taxonomyFile -Encoding UTF8
}

# 결과 출력
if ($newCategories.Count -eq 0 -and $newTags.Count -eq 0) {
    Write-Host "✅ Taxonomy가 이미 최신 상태입니다." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "✅ Taxonomy 업데이트 완료!" -ForegroundColor Green
    Write-Host "💡 변경사항을 확인하세요: git diff $taxonomyFile" -ForegroundColor Yellow
}
