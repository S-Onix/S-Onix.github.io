# 로컬 Jekyll 서버 시작 스크립트 (PowerShell)

Write-Host "🚀 로컬 서버 시작 중..." -ForegroundColor Blue
Write-Host ""

# Node.js 의존성 확인 및 설치
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Node.js 의존성을 설치합니다..." -ForegroundColor Yellow
    npm install
    Write-Host ""
}

# JavaScript/CSS 빌드
Write-Host "🔨 JavaScript와 CSS를 빌드합니다..." -ForegroundColor Blue
npm run build
Write-Host ""

# Bundler 확인
if (-not (Get-Command bundle -ErrorAction SilentlyContinue)) {
    Write-Host "Bundler가 설치되어 있지 않습니다." -ForegroundColor Red
    Write-Host "설치: gem install bundler"
    exit 1
}

# 초안 포함 여부 선택
$includeDrafts = Read-Host "초안(_drafts)도 표시하시겠습니까? (y/N)"

if ($includeDrafts -match '^[Yy]$') {
    Write-Host "📝 초안을 포함하여 서버를 시작합니다..." -ForegroundColor Blue
    bundle exec jekyll serve --drafts --livereload
} else {
    Write-Host "📄 정식 포스트만 표시합니다..." -ForegroundColor Blue
    bundle exec jekyll serve --livereload
}

Write-Host ""
Write-Host "✅ 서버가 중지되었습니다." -ForegroundColor Green
