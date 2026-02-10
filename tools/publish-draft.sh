#!/bin/bash
# 초안을 정식 포스트로 발행하는 스크립트

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# _drafts 폴더가 없으면 생성
if [ ! -d "_drafts" ]; then
    mkdir -p _drafts
    echo -e "${BLUE}📁 _drafts 폴더를 생성했습니다.${NC}"
fi

# 초안 목록 표시
echo -e "${BLUE}📝 초안 목록:${NC}"
echo ""

drafts=($(ls -1 _drafts/*.md 2>/dev/null))

if [ ${#drafts[@]} -eq 0 ]; then
    echo -e "${YELLOW}초안이 없습니다.${NC}"
    echo ""
    echo "초안을 만들려면:"
    echo "  touch _drafts/my-draft.md"
    exit 0
fi

for i in "${!drafts[@]}"; do
    echo "  [$i] ${drafts[$i]}"
done

echo ""
echo -n "발행할 초안 번호를 선택하세요: "
read draft_index

if [ -z "$draft_index" ] || [ "$draft_index" -ge "${#drafts[@]}" ]; then
    echo -e "${YELLOW}⚠️  잘못된 선택입니다.${NC}"
    exit 1
fi

selected_draft="${drafts[$draft_index]}"
filename=$(basename "$selected_draft")
date=$(date +"%Y-%m-%d")

# 날짜가 없으면 추가
if [[ ! $filename =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]]; then
    new_filename="${date}-${filename}"
else
    new_filename="$filename"
fi

target_path="_posts/${new_filename}"

# 파일 이동
mv "$selected_draft" "$target_path"

# Front Matter의 날짜 업데이트
time=$(date +"%H:%M:%S")
sed -i "s/^date:.*/date: ${date} ${time} +0900/" "$target_path"

echo ""
echo -e "${GREEN}✅ 초안이 발행되었습니다!${NC}"
echo -e "${BLUE}📁 위치: ${target_path}${NC}"
echo ""
echo "로컬에서 확인하려면:"
echo "  bundle exec jekyll serve"
