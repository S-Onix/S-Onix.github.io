#!/bin/bash
# 이미지 폴더 감시 및 자동 최적화 스크립트

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

IMG_DIR="assets/img/posts"

echo -e "${BLUE}🔍 이미지 폴더 감시 시작...${NC}"
echo -e "${YELLOW}💡 Ctrl+C로 종료${NC}"
echo ""

# inotifywait 설치 확인 (Linux)
if command -v inotifywait &> /dev/null; then
    echo -e "${GREEN}✅ inotifywait 사용 (Linux)${NC}"
    inotifywait -m -r -e create,modify --format '%w%f' "$IMG_DIR" | while read file; do
        if [[ "$file" =~ \.(jpg|jpeg|png)$ ]]; then
            echo -e "${BLUE}📸 새 이미지 감지: $file${NC}"

            # PNG 최적화
            if [[ "$file" =~ \.png$ ]] && command -v pngquant &> /dev/null; then
                pngquant --quality 65-80 --ext .png --force "$file" 2>/dev/null
                echo -e "${GREEN}  ✅ PNG 최적화 완료${NC}"
            fi

            # JPG 최적화
            if [[ "$file" =~ \.(jpg|jpeg)$ ]] && command -v jpegoptim &> /dev/null; then
                jpegoptim --max=85 "$file" 2>/dev/null
                echo -e "${GREEN}  ✅ JPG 최적화 완료${NC}"
            fi
        fi
    done
elif command -v fswatch &> /dev/null; then
    # macOS
    echo -e "${GREEN}✅ fswatch 사용 (macOS)${NC}"
    fswatch -0 -r "$IMG_DIR" | while read -d "" file; do
        if [[ "$file" =~ \.(jpg|jpeg|png)$ ]]; then
            echo -e "${BLUE}📸 새 이미지 감지: $file${NC}"

            if [[ "$file" =~ \.png$ ]] && command -v pngquant &> /dev/null; then
                pngquant --quality 65-80 --ext .png --force "$file" 2>/dev/null
                echo -e "${GREEN}  ✅ PNG 최적화 완료${NC}"
            fi

            if [[ "$file" =~ \.(jpg|jpeg)$ ]] && command -v jpegoptim &> /dev/null; then
                jpegoptim --max=85 "$file" 2>/dev/null
                echo -e "${GREEN}  ✅ JPG 최적화 완료${NC}"
            fi
        fi
    done
else
    # 폴백: 주기적 체크 (Windows Git Bash 등)
    echo -e "${YELLOW}⚠️  파일 감시 도구가 없습니다. 5초마다 체크합니다.${NC}"
    echo -e "${YELLOW}💡 더 나은 성능을 위해 inotifywait(Linux) 또는 fswatch(macOS)를 설치하세요.${NC}"
    echo ""

    processed_file=".processed_images"
    touch "$processed_file"

    while true; do
        find "$IMG_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) -newer "$processed_file" 2>/dev/null | while read file; do
            echo -e "${BLUE}📸 새 이미지 감지: $file${NC}"

            if [[ "$file" =~ \.png$ ]] && command -v pngquant &> /dev/null; then
                pngquant --quality 65-80 --ext .png --force "$file" 2>/dev/null
                echo -e "${GREEN}  ✅ PNG 최적화 완료${NC}"
            fi

            if [[ "$file" =~ \.(jpg|jpeg)$ ]] && command -v jpegoptim &> /dev/null; then
                jpegoptim --max=85 "$file" 2>/dev/null
                echo -e "${GREEN}  ✅ JPG 최적화 완료${NC}"
            fi
        done

        touch "$processed_file"
        sleep 5
    done
fi
