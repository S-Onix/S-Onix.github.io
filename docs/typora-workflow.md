# 📝 Typora로 블로그 작성하기 - 완벽 가이드

## 🎯 최적화된 워크플로우

### 1. 포스트 생성

```bash
# Bash
bash tools/new-post-typora.sh

# PowerShell
.\tools\new-post-typora.ps1
```

**자동으로 생성되는 것들:**
- ✅ Front Matter가 포함된 마크다운 파일
- ✅ 전용 이미지 폴더 (`assets/img/posts/날짜-제목/`)
- ✅ Typora로 바로 열기 (선택)

### 2. Typora에서 작성

#### 이미지 추가 방법

**방법 1: 복사 & 붙여넣기 (가장 쉬움)**
1. 스크린샷이나 이미지를 복사 (Ctrl+C)
2. Typora에서 붙여넣기 (Ctrl+V)
3. 자동으로 `assets/img/posts/날짜-제목/` 폴더에 저장됨

**방법 2: 드래그 & 드롭**
1. 이미지 파일을 Typora로 드래그
2. 자동으로 복사되고 경로가 삽입됨

**방법 3: 메뉴**
- `편집` → `이미지 도구` → `이미지 삽입` (Ctrl+Shift+I)

#### 이미지 경로 예시
```markdown
<!-- 자동 생성된 경로 -->
![스크린샷](../assets/img/posts/2026-02-10-my-post/screenshot-1.png)

<!-- Jekyll에서는 이렇게 변환됨 -->
/assets/img/posts/2026-02-10-my-post/screenshot-1.png
```

### 3. 미리보기 & 수정

Typora의 실시간 렌더링으로 즉시 확인:
- ✅ 이미지가 제대로 표시되는지
- ✅ 코드 블록 하이라이팅
- ✅ 수식, 다이어그램

### 4. 로컬에서 확인

```bash
bash tools/serve.sh
```

http://localhost:4000 에서 실제 블로그 모습 확인

### 5. 배포

```bash
bash tools/deploy.sh
```

---

## 🎨 Typora 설정 가이드

### 이미지 설정 (필수!)

**파일** → **환경설정** → **이미지**

```
[이미지 삽입 시]
☑ 이미지를 현재 폴더로 복사
☑ 가능한 경우 상대 경로 사용

[복사 이미지 위치]
./assets/img/posts/${filename}

[온라인 이미지]
☑ 온라인 이미지 자동 다운로드
☑ 우선 HTTPS 이미지 사용
```

### 편집기 설정

**파일** → **환경설정** → **편집기**

```
[일반]
☑ 자동 저장
☑ 복구 활성화

[고급]
☑ 코드 펜스에서 들여�기
☑ 라인 넘버 표시 (코드 블록)
```

### Markdown 설정

**파일** → **환경설정** → **Markdown**

```
[Markdown 확장 문법]
☑ 표 (Tables)
☑ 코드 펜스 (Fenced Code Blocks)
☑ 수식 (Math Blocks)
☑ 다이어그램 (Diagrams)

[스마트 문장 부호]
☑ 스마트 대시
☑ 스마트 따옴표
```

---

## 💡 프로 팁

### 1. 이미지 최적화 자동화

이미지 저장 후 자동으로 최적화하는 스크립트:

```bash
# tools/optimize-images.sh
for img in assets/img/posts/**/*.{jpg,png}; do
    if [ -f "$img" ]; then
        # PNG 최적화
        if [[ $img == *.png ]]; then
            pngquant --quality 65-80 --ext .png --force "$img"
        fi
        # JPG 최적화
        if [[ $img == *.jpg ]]; then
            jpegoptim --max=85 "$img"
        fi
    fi
done
```

### 2. Front Matter 빠른 작성

Typora의 코드 블록 자동완성 활용:

1. `---` 입력
2. Enter
3. Front Matter 템플릿 붙여넣기
4. `---` 입력

### 3. 스니펫 활용

자주 사용하는 코드를 별도 파일로 저장:

```
_snippets/
  ├── tip-box.md          # 팁 박스
  ├── code-comparison.md  # 코드 비교
  ├── tutorial-template.md # 튜토리얼 템플릿
  └── ...
```

필요할 때 복사해서 붙여넣기!

### 4. 표 쉽게 만들기

**온라인 도구 활용:**
- [Tables Generator](https://www.tablesgenerator.com/markdown_tables)
- 엑셀/구글 시트 → 복사 → Typora에 붙여넣기

**Typora 내장 기능:**
- `Ctrl + T` → 표 삽입
- 표 위에서 우클릭 → 행/열 추가

### 5. 수식 작성

**인라인 수식:** `$$ x = y $$`

**블록 수식:**
```
$$
\begin{equation}
  ...
\end{equation}
$$
```

**온라인 에디터:** [CodeCogs Equation Editor](https://www.codecogs.com/latex/eqneditor.php)

---

## 🚀 고급 워크플로우

### Git Integration

Typora에서 작성하면서 자동 커밋:

```bash
# .git/hooks/post-commit (자동 커밋 후 실행)
#!/bin/bash
# 이미지 최적화
bash tools/optimize-images.sh

# 자동 배포 (선택)
# bash tools/deploy.sh
```

### VS Code와 함께 사용

1. Typora에서 글 작성
2. VS Code에서 코드 블록 세밀 조정
3. Git으로 버전 관리

### 초안 관리

```
_drafts/
  ├── 2026-02-10-draft-post.md
  └── ideas.md  # 아이디어 메모
```

로컬 서버에서 초안 확인:
```bash
bash tools/serve.sh  # y 선택 (초안 포함)
```

---

## 📋 체크리스트

글 작성 전:
- [ ] `new-post-typora` 스크립트 실행
- [ ] Front Matter 카테고리/태그 작성
- [ ] 이미지 폴더 확인

글 작성 중:
- [ ] 이미지 alt 텍스트 추가
- [ ] 코드 블록 언어 지정
- [ ] 링크 확인
- [ ] 맞춤법 검사

글 완성 후:
- [ ] 로컬 서버에서 확인
- [ ] 이미지 최적화
- [ ] SEO 검토 (제목, 설명, 태그)
- [ ] 배포

---

## 🔧 문제 해결

### 이미지가 안 보여요

**원인:** 경로 문제
**해결:**
1. Typora 설정에서 상대 경로 사용 확인
2. 이미지가 `assets/img/posts/` 폴더에 있는지 확인
3. 로컬 서버 재시작

### 수식이 렌더링 안 돼요

**원인:** MathJax 미활성화
**해결:**
Front Matter에 추가:
```yaml
---
math: true
---
```

### 다이어그램이 안 보여요

**원인:** Mermaid 미활성화
**해결:**
Front Matter에 추가:
```yaml
---
mermaid: true
---
```

---

## 📚 참고 자료

- [Typora 공식 문서](https://support.typora.io/)
- [Jekyll 포스트 작성 가이드](_posts/2019-08-08-write-a-new-post.md)
- [Typora 스니펫 모음](typora-snippets.md)
- [Chirpy 테마 문서](https://chirpy.cotes.page/)

---

**🎉 이제 Typora로 효율적으로 블로그를 작성할 수 있습니다!**
