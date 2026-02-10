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
echo ""
echo -e "${YELLOW}💡 팁: 제목이 '${title}'인 경우,${NC}"
echo -e "${YELLOW}   좋은 예: java-tutorial, python-basics, book-review-1${NC}"
echo ""

while true; do
    echo -n "URL 슬러그를 입력하세요 (영문, 예: python-tutorial): "
    read slug

    if [ -z "$slug" ]; then
        # 슬러그가 비어있으면 제목에서 자동 생성 (영문/숫자/하이픈만)
        filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
        if [ -z "$filename" ]; then
            echo -e "${YELLOW}⚠️  제목에 영문이 없습니다. 영문 슬러그를 입력해주세요.${NC}"
            continue
        fi
        echo -e "${YELLOW}⚠️  슬러그가 비어있습니다. 자동 생성: ${filename}${NC}"
        break
    else
        # 한글 포함 여부 확인
        if echo "$slug" | grep -q '[가-힣]'; then
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}⚠️  한글이 감지되었습니다!${NC}"
            echo -e "${BLUE}💡 제목 '${title}'을(를) 영문으로 표현하면?${NC}"
            echo -e "${GREEN}   예시:${NC}"
            echo -e "${GREEN}   • 자바의 신 1장 → java-god-chapter-1${NC}"
            echo -e "${GREEN}   • 파이썬 기초 → python-basics${NC}"
            echo -e "${GREEN}   • 알고리즘 정렬 → algorithm-sorting${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            continue
        fi

        # 입력된 슬러그 검증 (영문, 숫자, 하이픈만 허용)
        clean_slug=$(echo "$slug" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
        if [ "$slug" != "$clean_slug" ]; then
            echo -e "${YELLOW}⚠️  특수문자가 포함되어 있습니다.${NC}"
            echo -e "${BLUE}💡 자동 정리된 슬러그: ${clean_slug}${NC}"
            read -p "이 슬러그를 사용하시겠습니까? (Y/n): " use_clean
            if [[ "$use_clean" =~ ^[Yy]$ ]] || [ -z "$use_clean" ]; then
                filename="$clean_slug"
                break
            else
                continue
            fi
        fi
        filename="$clean_slug"
        break
    fi
done

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
