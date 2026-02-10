#!/bin/bash
# 블로그 백업 스크립트

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# 백업 디렉토리 설정
BACKUP_DIR="backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="blog_backup_${DATE}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}💾 블로그 백업 중...${NC}"

# 중요한 파일들만 백업
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" \
    --exclude='node_modules' \
    --exclude='vendor' \
    --exclude='.git' \
    --exclude='_site' \
    --exclude='.jekyll-cache' \
    --exclude='backups' \
    _config.yml \
    _posts/ \
    _tabs/ \
    _data/ \
    assets/img/ \
    Gemfile \
    Gemfile.lock \
    package.json \
    2>/dev/null || true

echo ""
echo -e "${GREEN}✅ 백업 완료!${NC}"
echo -e "${BLUE}📦 파일: ${BACKUP_DIR}/${BACKUP_NAME}${NC}"

# 오래된 백업 삭제 (30일 이상)
find "$BACKUP_DIR" -name "blog_backup_*.tar.gz" -mtime +30 -delete 2>/dev/null || true

echo ""
echo "백업 목록:"
ls -lh "$BACKUP_DIR"
