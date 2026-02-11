#!/bin/bash
# Typora용 블로그 포스트 생성 스크립트

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📝 Typora용 새 포스트 생성${NC}"
echo ""

# 파일명(슬러그) 입력
echo -e "${YELLOW}💡 팁: 좋은 파일명 예시: java-tutorial, python-basics, book-review-1${NC}"
echo ""

while true; do
    echo -n "파일명(슬러그)을 입력하세요 (영문, 예: python-tutorial): "
    read slug

    if [ -z "$slug" ]; then
        echo -e "${YELLOW}⚠️  파일명을 입력해주세요.${NC}"
        continue
    fi

    # 한글 포함 여부 확인
    if echo "$slug" | grep -q '[가-힣]'; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠️  한글이 감지되었습니다!${NC}"
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
done

# 포스트 제목 입력 (블로그에 표시되는 제목, 한글 가능)
echo ""
echo -e "${BLUE}📌 블로그에 표시될 제목을 입력하세요 (한글 가능)${NC}"
echo -n "포스트 제목: "
read title

if [ -z "$title" ]; then
    echo -e "${YELLOW}⚠️  제목이 비어있습니다. 종료합니다.${NC}"
    exit 1
fi

date=$(date +"%Y-%m-%d")
time=$(date +"%H:%M:%S")
filepath="_posts/${date}-${filename}.md"
img_dir="assets/img/posts/${date}-${filename}"

# 카테고리 목록 보여주기
echo ""
echo -e "${BLUE}📂 사용 가능한 카테고리:${NC}"
if [ -f "_data/blog-taxonomy.yml" ]; then
    taxonomy_categories=$(sed -n '/^categories:/,/^tags:/p' _data/blog-taxonomy.yml | \
        grep "  - name:" | \
        sed 's/.*name: //g' | \
        paste -sd ', ' -)
    echo -e "${GREEN}  $taxonomy_categories${NC}"
else
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

# 태그 목록 보여주기
echo ""
echo -e "${BLUE}🏷️  사용 가능한 태그:${NC}"
if [ -f "_data/blog-taxonomy.yml" ]; then
    taxonomy_tags=$(awk '/^tags:/,0' _data/blog-taxonomy.yml | \
        grep "  - name:" | \
        sed 's/.*name: //g' | \
        paste -sd ', ' -)
    echo -e "${GREEN}  $taxonomy_tags${NC}"
else
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

echo ""
echo -e "${YELLOW}💡 Typora에서 Front Matter의 categories와 tags를 수정하세요!${NC}"
echo ""

# 이미지 폴더 생성
mkdir -p "$img_dir"

# Front Matter 템플릿 생성 (주석으로 가이드 추가)
cat > "$filepath" << EOF
---
title: ${title}
date: ${date} ${time} +0900
categories: []  # 예: [개발, Python]
tags: []        # 예: [python, tutorial]
image:
  path: /${img_dir}/cover.jpg
  alt: ${title}
---

## 📌 소개

여기에 내용을 작성하세요.

## 📝 본문

### 섹션 1

내용...

## 🎯 마무리

마무리 내용...

---

**관련 포스트:**
- [링크1](#)
- [링크2](#)
EOF

echo ""
echo -e "${GREEN}✅ 포스트가 생성되었습니다!${NC}"
echo -e "${BLUE}📁 포스트: ${filepath}${NC}"
echo -e "${BLUE}🖼️  이미지 폴더: ${img_dir}${NC}"
echo ""
echo -e "${YELLOW}💡 Typora로 열기:${NC}"
echo "   typora \"${filepath}\""
echo ""
echo -e "${YELLOW}💡 이미지는 다음 경로에 저장하세요:${NC}"
echo "   ${img_dir}/"

# 이미지 자동 최적화 여부 확인
echo ""
read -p "이미지 자동 최적화를 실행하시겠습니까? (Y/n): " start_watch
if [[ "$start_watch" =~ ^[Yy]$ ]] || [ -z "$start_watch" ]; then
    # 이미 실행 중인지 확인
    if pgrep -f "watch-images.sh" > /dev/null; then
        echo -e "${GREEN}✅ 이미지 감시가 이미 실행 중입니다.${NC}"
    else
        # 백그라운드로 실행
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        nohup bash "$script_dir/watch-images.sh" > /dev/null 2>&1 &
        echo -e "${GREEN}✅ 이미지 자동 최적화가 시작되었습니다.${NC}"
        echo -e "${YELLOW}💡 종료하려면: pkill -f watch-images.sh${NC}"
    fi
fi

# Typora로 자동 열기
if command -v typora &> /dev/null; then
    echo ""
    read -p "Typora로 바로 여시겠습니까? (Y/n): " open_typora
    if [[ "$open_typora" =~ ^[Yy]$ ]] || [ -z "$open_typora" ]; then
        typora "$filepath" &
        echo ""
        echo -e "${GREEN}✅ Typora가 열렸습니다!${NC}"
    fi
fi
