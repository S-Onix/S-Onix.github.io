#!/bin/bash
# 빠른 배포 스크립트

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 블로그 배포 시작${NC}"
echo ""

# Taxonomy 자동 동기화
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/sync-taxonomy.sh"
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

# Conventional Commit 타입 선택
echo -e "${BLUE}📝 커밋 타입을 선택하세요:${NC}"
echo "  1) feat      - 새 기능 (새 포스트 등)"
echo "  2) fix       - 버그 수정"
echo "  3) docs      - 문서 수정 (포스트 내용 수정)"
echo "  4) style     - 스타일 변경"
echo "  5) refactor  - 리팩토링"
echo "  6) chore     - 기타 변경사항"
echo ""
echo -n "타입 번호 (기본: 1): "
read type_choice

case "$type_choice" in
    2) commit_type="fix" ;;
    3) commit_type="docs" ;;
    4) commit_type="style" ;;
    5) commit_type="refactor" ;;
    6) commit_type="chore" ;;
    *) commit_type="feat" ;;
esac

# 커밋 메시지 입력
echo ""
echo -n "커밋 메시지를 입력하세요: "
read commit_message

if [ -z "$commit_message" ]; then
    echo -e "${YELLOW}⚠️  커밋 메시지가 비어있습니다. 기본 메시지를 사용합니다.${NC}"
    commit_message="update blog posts"
fi

# Conventional Commit 형식으로 조합
full_commit_message="${commit_type}: ${commit_message}"

# 이미지 경로 자동 변환 (Windows 절대 경로 → 상대 경로)
echo -e "${BLUE}🔄 이미지 경로 검사 중...${NC}"
fixed_count=0
for post in _posts/*.md; do
    if grep -q 'C:\\S-Onix' "$post" 2>/dev/null || grep -q 'C:/S-Onix' "$post" 2>/dev/null; then
        # Windows 절대 경로를 상대 경로로 변환 (이미지 라인만 대상)
        sed -i '/!\[/s|C:\\S-Onix\.github\.io\\|/|g' "$post"
        sed -i '/!\[/s|C:/S-Onix\.github\.io/|/|g' "$post"
        # 이미지 라인의 백슬래시만 슬래시로 변환
        sed -i '/!\[/s|\\|/|g' "$post"
        fixed_count=$((fixed_count + 1))
        echo -e "${GREEN}  ✅ 경로 수정: $(basename "$post")${NC}"
    fi
done
if [ "$fixed_count" -eq 0 ]; then
    echo -e "${GREEN}  ✅ 모든 이미지 경로가 정상입니다.${NC}"
fi
echo ""

# Git 작업
echo ""
echo -e "${BLUE}📦 변경사항 커밋 중...${NC}"
echo -e "${YELLOW}   커밋 메시지: ${full_commit_message}${NC}"
git add .
git commit -m "$full_commit_message" -m "Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

echo -e "${BLUE}⬆️  원격 저장소에 푸시 중...${NC}"
git push origin main

echo ""
echo -e "${GREEN}✅ 배포 완료!${NC}"
echo -e "${BLUE}🌐 잠시 후 https://s-onix.github.io 에서 확인하세요.${NC}"
echo -e "${YELLOW}📊 GitHub Actions: https://github.com/S-Onix/S-Onix.github.io/actions${NC}"
