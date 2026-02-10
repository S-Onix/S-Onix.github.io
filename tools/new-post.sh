#!/bin/bash
# 새 블로그 포스트 생성 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 제목 입력
echo -e "${BLUE}📝 새 포스트 생성${NC}"
echo -n "포스트 제목을 입력하세요 (한글 가능): "
read title

if [ -z "$title" ]; then
    echo -e "${YELLOW}⚠️  제목이 비어있습니다. 종료합니다.${NC}"
    exit 1
fi

# URL 슬러그 입력 (파일명용)
echo -n "URL 슬러그를 입력하세요 (영문, 예: python-tutorial): "
read slug

if [ -z "$slug" ]; then
    echo -e "${YELLOW}⚠️  슬러그가 비어있습니다. 제목에서 자동 생성합니다.${NC}"
    # 한글 포함 가능하도록 수정
    filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9가-힣-]//g')
else
    # 슬러그를 소문자로 변환하고 정리
    filename=$(echo "$slug" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
fi

date=$(date +"%Y-%m-%d")
time=$(date +"%H:%M:%S")
filepath="_posts/${date}-${filename}.md"

# 카테고리 목록 추출
echo -e "${BLUE}사용 가능한 카테고리:${NC}"
if [ -f "_data/blog-taxonomy.yml" ]; then
    # taxonomy 파일에서 추출
    taxonomy_categories=$(sed -n '/^categories:/,/^tags:/p' _data/blog-taxonomy.yml | \
        grep "  - name:" | \
        sed 's/.*name: //g' | \
        paste -sd ', ' -)
    echo -e "${GREEN}  $taxonomy_categories${NC}"
    echo -e "${YELLOW}  (새 카테고리는 _data/blog-taxonomy.yml에 추가하세요)${NC}"
else
    # 기존 포스트에서 추출
    existing_categories=$(grep -h "^categories:" _posts/*.md 2>/dev/null | \
        sed 's/categories://g' | sed 's/#.*//g' | tr -d '[]' | tr ',' '\n' | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | grep -v '^[A-Z_]*$' | \
        sort -u | paste -sd ', ' -)
    if [ -n "$existing_categories" ]; then
        echo -e "${GREEN}  $existing_categories${NC}"
    else
        echo -e "${YELLOW}  (아직 없음)${NC}"
    fi
fi

# 카테고리 입력
echo -n "카테고리 (쉼표로 구분, 예: 개발,Python): "
read categories_input
if [ -z "$categories_input" ]; then
    categories="[블로그]"
else
    IFS=',' read -ra CATS <<< "$categories_input"
    categories="["
    for i in "${!CATS[@]}"; do
        categories+="${CATS[$i]}"
        if [ $i -lt $((${#CATS[@]} - 1)) ]; then
            categories+=", "
        fi
    done
    categories+="]"
fi

# 태그 목록 추출
echo -e "${BLUE}사용 가능한 태그:${NC}"
if [ -f "_data/blog-taxonomy.yml" ]; then
    # taxonomy 파일에서 추출
    taxonomy_tags=$(sed -n '/^tags:/,$p' _data/blog-taxonomy.yml | \
        grep "  - name:" | \
        sed 's/.*name: //g' | \
        paste -sd ', ' -)
    echo -e "${GREEN}  $taxonomy_tags${NC}"
    echo -e "${YELLOW}  (새 태그는 _data/blog-taxonomy.yml에 추가하세요)${NC}"
else
    # 기존 포스트에서 추출
    existing_tags=$(grep -h "^tags:" _posts/*.md 2>/dev/null | \
        sed 's/tags://g' | sed 's/#.*//g' | tr -d '[]' | tr ',' '\n' | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | grep -v '^[A-Z_]*$' | \
        sort -u | paste -sd ', ' -)
    if [ -n "$existing_tags" ]; then
        echo -e "${GREEN}  $existing_tags${NC}"
    else
        echo -e "${YELLOW}  (아직 없음)${NC}"
    fi
fi

if [ -n "$existing_tags" ]; then
    echo -e "${GREEN}  $existing_tags${NC}"
else
    echo -e "${YELLOW}  (아직 없음)${NC}"
fi

# 태그 입력
echo -n "태그 (쉼표로 구분, 예: python,tutorial): "
read tags_input
if [ -z "$tags_input" ]; then
    tags="[]"
else
    IFS=',' read -ra TAGS <<< "$tags_input"
    tags="["
    for i in "${!TAGS[@]}"; do
        tags+="${TAGS[$i]}"
        if [ $i -lt $((${#TAGS[@]} - 1)) ]; then
            tags+=", "
        fi
    done
    tags+="]"
fi

# Front Matter 생성
cat > "$filepath" << EOF
---
title: ${title}
date: ${date} ${time} +0900
categories: ${categories}
tags: ${tags}
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
EOF

echo -e "${GREEN}✅ 포스트가 생성되었습니다!${NC}"
echo -e "${BLUE}📁 파일 경로: ${filepath}${NC}"
echo ""
echo "다음 명령으로 편집하세요:"
echo "  code ${filepath}"
