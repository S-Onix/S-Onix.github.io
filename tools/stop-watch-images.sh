#!/bin/bash
# 이미지 감시 스크립트 종료

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🛑 이미지 감시 종료 중...${NC}"

# watch-images.sh 프로세스 찾기
pids=$(pgrep -f "watch-images.sh")

if [ -z "$pids" ]; then
    echo -e "${YELLOW}⚠️  실행 중인 이미지 감시 프로세스가 없습니다.${NC}"
    exit 0
fi

# 프로세스 종료
echo "$pids" | while read pid; do
    kill "$pid" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 프로세스 종료: PID $pid${NC}"
    fi
done

# 잠시 대기
sleep 1

# 확인
if pgrep -f "watch-images.sh" > /dev/null; then
    echo -e "${RED}❌ 일부 프로세스를 종료하지 못했습니다.${NC}"
    echo -e "${YELLOW}💡 강제 종료: pkill -9 -f watch-images.sh${NC}"
else
    echo -e "${GREEN}✅ 모든 이미지 감시 프로세스가 종료되었습니다.${NC}"
fi
