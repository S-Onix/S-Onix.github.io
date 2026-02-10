# 🛠️ 블로그 자동화 도구 모음

이 디렉토리에는 블로그 운영을 편리하게 해주는 자동화 스크립트들이 있습니다.

## 📋 스크립트 목록

### 1. 새 포스트 생성 ⭐

**Bash (Linux/Mac/Git Bash)**
```bash
bash tools/new-post.sh
```

**PowerShell (Windows)**
```powershell
.\tools\new-post.ps1
```

**기능:**
- 대화형으로 포스트 제목, 카테고리, 태그 입력
- 자동으로 날짜 형식의 파일명 생성 (YYYY-MM-DD-title.md)
- Front Matter 템플릿 자동 삽입

**예시:**
```
📝 새 포스트 생성
포스트 제목을 입력하세요: Python 시작하기
카테고리 (쉼표로 구분): 개발,Python
태그 (쉼표로 구분): python,tutorial,시작하기

✅ 포스트가 생성되었습니다!
📁 파일 경로: _posts/2026-02-10-python-시작하기.md
```

---

### 2. 빠른 배포

```bash
bash tools/deploy.sh
```

**기능:**
- 변경된 파일 목록 표시
- 커밋 메시지 입력
- 자동으로 add, commit, push
- GitHub Actions 링크 제공

**사용 시나리오:**
```bash
# 포스트 작성 완료 후
bash tools/deploy.sh
# 커밋 메시지: "Add new post about Python"
# → 자동으로 GitHub에 푸시 → 자동 배포
```

---

### 3. 로컬 서버 시작

**Bash (Linux/Mac/Git Bash)**
```bash
bash tools/serve.sh
```

**PowerShell (Windows)**
```powershell
.\tools\serve.ps1
```

**기능:**
- ✨ **자동 빌드**: Node.js 의존성 확인 및 JavaScript/CSS 자동 빌드
- Jekyll 로컬 서버 실행
- 초안 포함 여부 선택
- LiveReload 자동 활성화

> 💡 이제 `npm run build`를 별도로 실행할 필요가 없습니다!

**옵션:**
- 초안 포함: `_drafts` 폴더의 파일도 미리보기
- 정식 포스트만: 실제 배포될 내용만 표시

**접속:**
- http://localhost:4000

---

### 4. 초안 발행

```bash
bash tools/publish-draft.sh
```

**기능:**
- `_drafts` 폴더의 초안 목록 표시
- 선택한 초안을 `_posts`로 이동
- 자동으로 날짜 추가 및 Front Matter 업데이트

**워크플로우:**
```bash
# 1. 초안 작성
touch _drafts/my-draft-post.md

# 2. 내용 작성...

# 3. 발행
bash tools/publish-draft.sh
# → _posts/2026-02-10-my-draft-post.md로 이동
```

---

### 5. 백업

```bash
bash tools/backup.sh
```

**기능:**
- 중요 파일 압축 백업 (포스트, 설정, 이미지)
- `backups/` 폴더에 타임스탬프와 함께 저장
- 30일 이상 된 백업 자동 삭제

**백업 포함 내용:**
- 포스트 및 페이지 (`_posts/`, `_tabs/`)
- 설정 파일 (`_config.yml`, `Gemfile`)
- 이미지 및 에셋 (`assets/img/`)

---

### 6. Typora용 포스트 생성 ✨

**Bash (Linux/Mac/Git Bash)**
```bash
bash tools/new-post-typora.sh
```

**PowerShell (Windows)**
```powershell
.\tools\new-post-typora.ps1
```

**기능:**
- 기본 포스트 생성 기능 + Typora 최적화
- 전용 이미지 폴더 자동 생성 (`assets/img/posts/날짜-제목/`)
- 사용 가능한 카테고리와 태그 목록 표시
- **✨ 이미지 자동 최적화 통합** (선택 가능)
- Typora로 자동 열기 (선택)
- Front Matter에 가이드 주석 포함

**워크플로우:**
```bash
# 1. Typora용 포스트 생성
bash tools/new-post-typora.sh

# 2. 이미지 자동 최적화? (Y/n): Y 입력
# 3. Typora로 바로 여시겠습니까? (Y/n): Y 입력
# 4. Typora에서 작성
#    - 이미지 복사&붙여넣기 → 자동으로 전용 폴더에 저장 + 최적화!
```

**이미지 감시 종료:**
```bash
# Bash
bash tools/stop-watch-images.sh

# PowerShell
.\tools\stop-watch-images.ps1
```

**Typora 설정:**
- 파일 → 환경설정 → 이미지
  - ☑ 이미지를 지정한 폴더로 복사
  - ☑ 상대 경로 사용
  - 복사 위치: `./assets/img/posts/${filename}`

> 💡 자세한 Typora 워크플로우는 [docs/typora-workflow.md](../docs/typora-workflow.md) 참조

---

### 7. 이미지 감시 및 자동 최적화 🖼️

**Bash (Linux/Mac/Git Bash)**
```bash
bash tools/watch-images.sh
```

**PowerShell (Windows)**
```powershell
.\tools\watch-images.ps1
```

**기능:**
- 이미지 폴더 실시간 감시
- 새 이미지 추가 시 자동 최적화
  - PNG: pngquant (65-80% 품질)
  - JPG: jpegoptim (85% 품질)
- 파일 크기 줄여 블로그 성능 향상

**사용 시나리오:**
```bash
# 터미널 1: 이미지 감시 시작
bash tools/watch-images.sh

# 터미널 2: Typora로 포스트 작성
bash tools/new-post-typora.sh

# Typora에서 이미지 붙여넣기 → 자동으로 최적화됨!
```

**최적화 도구 설치:**

```bash
# Linux (Ubuntu/Debian)
sudo apt install pngquant jpegoptim

# macOS
brew install pngquant jpegoptim

# Windows (Scoop)
scoop install pngquant jpegoptim
```

---

## 🚀 빠른 시작

### Windows 사용자

1. **PowerShell 실행 정책 설정** (최초 1회)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

2. **새 포스트 만들기**
```powershell
.\tools\new-post.ps1
```

### Linux/Mac/Git Bash 사용자

1. **실행 권한 부여** (최초 1회)
```bash
chmod +x tools/*.sh
```

2. **새 포스트 만들기**
```bash
bash tools/new-post.sh
```

---

## 📖 일반적인 워크플로우

### 포스트 작성 → 배포

```bash
# 1. 새 포스트 생성
bash tools/new-post.sh

# 2. 포스트 작성
code _posts/2026-02-10-my-post.md

# 3. 로컬에서 미리보기
bash tools/serve.sh

# 4. 배포
bash tools/deploy.sh
```

### 초안 작성 → 발행 → 배포

```bash
# 1. 초안 작성
touch _drafts/my-idea.md
code _drafts/my-idea.md

# 2. 초안 미리보기
bash tools/serve.sh  # "y" 선택 (초안 포함)

# 3. 완성되면 발행
bash tools/publish-draft.sh

# 4. 배포
bash tools/deploy.sh
```

### Typora로 작성 (추천!) ⭐

```bash
# 1. 포스트 생성 + Typora 열기 (이미지 최적화 자동 시작)
bash tools/new-post-typora.sh
# → "이미지 자동 최적화를 실행하시겠습니까? (Y/n):" Y 입력
# → "Typora로 바로 여시겠습니까? (Y/n):" Y 입력

# 2. Typora에서 작성:
# - 이미지 복사&붙여넣기 → 자동 저장 + 자동 최적화!
# - 실시간 미리보기
# - 저장 (Ctrl+S)

# 3. 로컬 확인
bash tools/serve.sh

# 4. 배포
bash tools/deploy.sh

# 5. 작업 완료 후 이미지 감시 종료 (선택)
bash tools/stop-watch-images.sh
```

---

## 💡 팁

### VS Code 통합

`.vscode/tasks.json`에 추가하면 단축키로 실행 가능:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "새 포스트",
      "type": "shell",
      "command": "bash tools/new-post.sh",
      "group": "build"
    },
    {
      "label": "로컬 서버",
      "type": "shell",
      "command": "bash tools/serve.sh",
      "group": "build"
    }
  ]
}
```

### Git Alias 설정

`.gitconfig`에 추가:

```ini
[alias]
    blog-deploy = !bash tools/deploy.sh
    blog-serve = !bash tools/serve.sh
```

사용:
```bash
git blog-deploy
git blog-serve
```

---

## 🔧 고급 사용

### 포스트 템플릿 커스터마이징

`tools/new-post.sh` 파일의 템플릿 부분을 수정하세요:

```bash
cat > "$filepath" << EOF
---
title: ${title}
date: ${date} ${time} +0900
categories: ${categories}
tags: ${tags}
# 추가 옵션
pin: false
math: false
mermaid: false
---

## 👋 소개

여기에 나만의 템플릿...
EOF
```

### 자동 백업 스케줄링

**Windows (작업 스케줄러)**
- 작업 스케줄러에서 매주 자동 실행 설정

**Linux/Mac (crontab)**
```bash
# 매주 일요일 자정에 백업
0 0 * * 0 cd /path/to/blog && bash tools/backup.sh
```

---

## 📞 문제 해결

### "Permission denied" 오류
```bash
chmod +x tools/*.sh
```

### "bundle: command not found"
```bash
gem install bundler
```

### PowerShell 스크립트 실행 불가
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🎉 즐거운 블로깅!

문제가 있거나 개선 아이디어가 있으면 이슈를 열어주세요.
