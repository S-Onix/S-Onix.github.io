#!/bin/bash
# Jekyll 새 포스트 생성 스크립트

# 사용법 확인
if [ -z "$1" ]; then
    echo "사용법: ./new-post.sh \"포스트 제목\""
    exit 1
fi

TITLE="$1"

# 현재 날짜와 시간
DATE=$(date +"%Y-%m-%d")
DATETIME=$(date +"%Y-%m-%d %H:%M:%S")

# 제목을 URL 친화적으로 변환 (공백을 - 로, 특수문자 제거)
URL_TITLE=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9가-힣-]//g')

# 파일명 생성
FILENAME="_posts/${DATE}-${URL_TITLE}.md"

# 템플릿 내용
cat > "$FILENAME" <<EOF
---
layout: post
title: "$TITLE"
date: $DATETIME +0900
categories: []
tags: []
---

## 서론

여기에 내용을 작성하세요...

## 본론

### 소제목 1

내용...

## 결론

마무리...
EOF

echo "✅ 포스트가 생성되었습니다: $FILENAME"
echo "📝 Typora로 열기: typora \"$FILENAME\""
