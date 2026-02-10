#!/bin/bash
# 포스트의 카테고리/태그를 taxonomy.yml과 동기화

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

TAXONOMY_FILE="_data/blog-taxonomy.yml"

echo -e "${BLUE}🔄 Taxonomy 동기화 중...${NC}"

# 포스트에서 모든 카테고리 추출
post_categories=$(grep -h "^categories:" _posts/*.md 2>/dev/null | \
    sed 's/categories://g' | sed 's/#.*//g' | tr -d '[]' | tr ',' '\n' | \
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | \
    sort -u)

# 포스트에서 모든 태그 추출
post_tags=$(grep -h "^tags:" _posts/*.md 2>/dev/null | \
    sed 's/tags://g' | sed 's/#.*//g' | tr -d '[]' | tr ',' '\n' | \
    sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | \
    sort -u)

# taxonomy에 있는 카테고리 추출
taxonomy_categories=$(sed -n '/^categories:/,/^tags:/p' "$TAXONOMY_FILE" | \
    grep "  - name:" | \
    sed 's/.*name: //g')

# taxonomy에 있는 태그 추출
taxonomy_tags=$(awk '/^tags:/,0' "$TAXONOMY_FILE" | \
    grep "  - name:" | \
    sed 's/.*name: //g')

new_categories=()
new_tags=()

# 새로운 카테고리 찾기
while IFS= read -r category; do
    if [ -n "$category" ] && ! echo "$taxonomy_categories" | grep -qx "$category"; then
        new_categories+=("$category")
    fi
done <<< "$post_categories"

# 새로운 태그 찾기
while IFS= read -r tag; do
    if [ -n "$tag" ] && ! echo "$taxonomy_tags" | grep -qx "$tag"; then
        new_tags+=("$tag")
    fi
done <<< "$post_tags"

# 새로운 카테고리가 있으면 추가
if [ ${#new_categories[@]} -gt 0 ]; then
    echo -e "${YELLOW}📂 새로운 카테고리 발견:${NC}"
    for category in "${new_categories[@]}"; do
        echo -e "  ${GREEN}+ $category${NC}"

        # '# 태그 정의' 앞에 새 카테고리 추가
        sed -i "/^# 태그 정의/i\\  - name: $category\n    description: $category 관련\n" "$TAXONOMY_FILE"
    done
fi

# 새로운 태그가 있으면 추가
if [ ${#new_tags[@]} -gt 0 ]; then
    echo -e "${YELLOW}🏷️  새로운 태그 발견:${NC}"
    for tag in "${new_tags[@]}"; do
        echo -e "  ${GREEN}+ $tag${NC}"

        # '# 사용 예시:' 앞에 새 태그 추가
        sed -i "/^# 사용 예시:/i\\  - name: $tag\n    description: $tag 관련\n" "$TAXONOMY_FILE"
    done
fi

# 결과 출력
if [ ${#new_categories[@]} -eq 0 ] && [ ${#new_tags[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ Taxonomy가 이미 최신 상태입니다.${NC}"
else
    echo ""
    echo -e "${GREEN}✅ Taxonomy 업데이트 완료!${NC}"
    echo -e "${YELLOW}💡 변경사항을 확인하세요: git diff $TAXONOMY_FILE${NC}"
fi
