#!/bin/bash
# 빠른 배포 스크립트

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 블로그 배포 시작${NC}"
echo ""

# 변경사항 확인
if [[ -z $(git status -s) ]]; then
    echo -e "${YELLOW}⚠️  변경사항이 없습니다.${NC}"
    exit 0
fi

# 변경된 파일 표시
echo -e "${BLUE}📝 변경된 파일:${NC}"
git status -s
echo ""

# 커밋 메시지 입력
echo -n "커밋 메시지를 입력하세요: "
read commit_message

if [ -z "$commit_message" ]; then
    echo -e "${YELLOW}⚠️  커밋 메시지가 비어있습니다. 기본 메시지를 사용합니다.${NC}"
    commit_message="Update blog posts"
fi

# Git 작업
echo -e "${BLUE}📦 변경사항 커밋 중...${NC}"
git add .
git commit -m "$commit_message"

echo -e "${BLUE}⬆️  원격 저장소에 푸시 중...${NC}"
git push origin main

echo ""
echo -e "${GREEN}✅ 배포 완료!${NC}"
echo -e "${BLUE}🌐 잠시 후 https://s-onix.github.io 에서 확인하세요.${NC}"
echo -e "${YELLOW}📊 GitHub Actions: https://github.com/S-Onix/S-Onix.github.io/actions${NC}"
