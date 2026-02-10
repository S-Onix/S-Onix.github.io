#!/bin/bash
# 로컬 Jekyll 서버 시작 스크립트

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 로컬 서버 시작 중...${NC}"
echo ""

# Node.js 의존성 확인 및 설치
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Node.js 의존성을 설치합니다...${NC}"
    npm install
    echo ""
fi

# JavaScript/CSS 빌드
echo -e "${BLUE}🔨 JavaScript와 CSS를 빌드합니다...${NC}"
npm run build
echo ""

# Bundler 확인
if ! command -v bundle &> /dev/null; then
    echo "Bundler가 설치되어 있지 않습니다."
    echo "설치: gem install bundler"
    exit 1
fi

# 초안 포함 여부 선택
echo "초안(_drafts)도 표시하시겠습니까? (y/N): "
read -n 1 include_drafts
echo ""

if [[ $include_drafts =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}📝 초안을 포함하여 서버를 시작합니다...${NC}"
    bundle exec jekyll serve --drafts --livereload
else
    echo -e "${BLUE}📄 정식 포스트만 표시합니다...${NC}"
    bundle exec jekyll serve --livereload
fi

echo ""
echo -e "${GREEN}✅ 서버가 중지되었습니다.${NC}"
