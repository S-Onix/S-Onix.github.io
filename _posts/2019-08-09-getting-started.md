---
title: 시작하기
description: >-
  Chirpy 기본 사항에 대한 포괄적인 개요입니다.
  Chirpy 기반 웹사이트를 설치, 구성, 사용하는 방법과 웹 서버에 배포하는 방법을 배우게 됩니다.
author: cotes
date: 2019-08-09 20:55:00 +0800
categories: [블로깅, 튜토리얼]
tags: [시작하기]
pin: true
media_subpath: '/posts/20180809'
---

## 사이트 저장소 만들기

사이트 저장소를 만들 때 필요에 따라 두 가지 옵션이 있습니다:

### 옵션 1. Starter 사용하기 (권장)

이 방법은 업그레이드를 단순화하고 불필요한 파일을 격리하며, 최소한의 구성으로 글쓰기에 집중하려는 사용자에게 완벽합니다.

1. GitHub에 로그인하고 [**starter**][starter]로 이동합니다.
2. <kbd>Use this template</kbd> 버튼을 클릭한 다음 <kbd>Create a new repository</kbd>를 선택합니다.
3. 새 저장소 이름을 `<username>.github.io`로 지정합니다. `username`은 소문자 GitHub 사용자 이름으로 바꾸세요.

### 옵션 2. 테마 Fork하기

이 방법은 기능이나 UI 디자인을 수정하는 데 편리하지만 업그레이드 시 어려움이 있습니다. Jekyll에 익숙하고 이 테마를 크게 수정할 계획이 아니라면 시도하지 마세요.

1. GitHub에 로그인합니다.
2. [테마 저장소를 Fork합니다](https://github.com/cotes2020/jekyll-theme-chirpy/fork).
3. 새 저장소 이름을 `<username>.github.io`로 지정합니다. `username`은 소문자 GitHub 사용자 이름으로 바꾸세요.

## 환경 설정하기

저장소가 생성되면 개발 환경을 설정할 차례입니다. 두 가지 주요 방법이 있습니다:

### Dev Containers 사용하기 (Windows에 권장)

Dev Containers는 Docker를 사용하여 격리된 환경을 제공하므로 시스템과의 충돌을 방지하고 모든 종속성이 컨테이너 내에서 관리됩니다.

**단계**:

1. Docker 설치:
   - Windows/macOS의 경우 [Docker Desktop][docker-desktop]을 설치합니다.
   - Linux의 경우 [Docker Engine][docker-engine]을 설치합니다.
2. [VS Code][vscode]와 [Dev Containers extension][dev-containers]을 설치합니다.
3. 저장소 복제:
   - Docker Desktop의 경우: VS Code를 시작하고 [컨테이너 볼륨에서 저장소를 복제][dc-clone-in-vol]합니다.
   - Docker Engine의 경우: 저장소를 로컬로 복제한 다음 VS Code를 통해 [컨테이너에서 엽니다][dc-open-in-container].
4. Dev Containers 설정이 완료될 때까지 기다립니다.

### 네이티브로 설정하기 (Unix 계열 OS에 권장)

Unix 계열 시스템의 경우 최적의 성능을 위해 네이티브로 환경을 설정할 수 있습니다. 대안으로 Dev Containers를 사용할 수도 있습니다.

**단계**:

1. [Jekyll 설치 가이드](https://jekyllrb.com/docs/installation/)를 따라 Jekyll을 설치하고 [Git](https://git-scm.com/)이 설치되어 있는지 확인합니다.
2. 저장소를 로컬 컴퓨터에 복제합니다.
3. 테마를 fork한 경우 [Node.js][nodejs]를 설치하고 루트 디렉토리에서 `bash tools/init.sh`를 실행하여 저장소를 초기화합니다.
4. 저장소 루트에서 `bundle` 명령을 실행하여 종속성을 설치합니다.

## 사용법

### Jekyll 서버 시작하기

사이트를 로컬에서 실행하려면 다음 명령을 사용하세요:

```terminal
$ bundle exec jekyll serve
```

> Dev Containers를 사용하는 경우 **VS Code** 터미널에서 해당 명령을 실행해야 합니다.
{: .prompt-info }

몇 초 후 로컬 서버가 <http://127.0.0.1:4000>에서 사용 가능해집니다.

### 설정

필요에 따라 `_config.yml`{: .filepath}의 변수를 업데이트하세요. 일반적인 옵션은 다음과 같습니다:

- `url`
- `avatar`
- `timezone`
- `lang`

### 소셜 연락처 옵션

소셜 연락처 옵션은 사이드바 하단에 표시됩니다. `_data/contact.yml`{: .filepath} 파일에서 특정 연락처를 활성화하거나 비활성화할 수 있습니다.

### 스타일시트 커스터마이징

스타일시트를 커스터마이징하려면 테마의 `assets/css/jekyll-theme-chirpy.scss`{: .filepath} 파일을 Jekyll 사이트의 동일한 경로에 복사하고 파일 끝에 사용자 정의 스타일을 추가하세요.

### 정적 자산 커스터마이징

정적 자산 구성은 버전 `5.1.0`에서 도입되었습니다. 정적 자산의 CDN은 `_data/origin/cors.yml`{: .filepath }에 정의되어 있습니다. 웹사이트가 게시되는 지역의 네트워크 조건에 따라 일부를 교체할 수 있습니다.

정적 자산을 자체 호스팅하려면 [_chirpy-static-assets_](https://github.com/cotes2020/chirpy-static-assets#readme) 저장소를 참조하세요.

## 배포

배포하기 전에 `_config.yml`{: .filepath} 파일을 확인하고 `url`이 올바르게 구성되어 있는지 확인하세요. [**project site**](https://help.github.com/en/github/working-with-github-pages/about-github-pages#types-of-github-pages-sites)를 선호하고 사용자 정의 도메인을 사용하지 않거나, **GitHub Pages**가 아닌 다른 웹 서버에서 기본 URL로 웹사이트를 방문하려면 `baseurl`을 슬래시로 시작하는 프로젝트 이름으로 설정해야 합니다. 예: `/project-name`.

이제 다음 방법 중 _하나_를 선택하여 Jekyll 사이트를 배포할 수 있습니다.

### Github Actions를 사용한 배포

다음을 준비하세요:

- GitHub Free 플랜을 사용하는 경우 사이트 저장소를 공개로 유지하세요.
- `Gemfile.lock`{: .filepath}을 저장소에 커밋했고 로컬 컴퓨터가 Linux를 실행하지 않는 경우 lock 파일의 플랫폼 목록을 업데이트하세요:

  ```console
  $ bundle lock --add-platform x86_64-linux
  ```

다음으로 _Pages_ 서비스를 구성합니다:

1. GitHub에서 저장소로 이동합니다. _Settings_ 탭을 선택한 다음 왼쪽 탐색 모음에서 _Pages_를 클릭합니다. **Source** 섹션(_Build and deployment_ 아래)에서 드롭다운 메뉴에서 [**GitHub Actions**][pages-workflow-src]를 선택합니다.
   ![Build source](pages-source-light.png){: .light .border .normal w='375' h='140' }
   ![Build source](pages-source-dark.png){: .dark .normal w='375' h='140' }

2. 커밋을 GitHub에 푸시하여 _Actions_ 워크플로우를 트리거합니다. 저장소의 _Actions_ 탭에서 _Build and Deploy_ 워크플로우가 실행되는 것을 볼 수 있습니다. 빌드가 완료되고 성공하면 사이트가 자동으로 배포됩니다.

이제 GitHub에서 제공하는 URL로 사이트에 접속할 수 있습니다.

### 수동 빌드 및 배포

자체 호스팅 서버의 경우 로컬 컴퓨터에서 사이트를 빌드한 다음 사이트 파일을 서버에 업로드해야 합니다.

소스 프로젝트의 루트로 이동하여 다음 명령으로 사이트를 빌드하세요:

```console
$ JEKYLL_ENV=production bundle exec jekyll b
```

출력 경로를 지정하지 않은 경우 생성된 사이트 파일은 프로젝트 루트 디렉토리의 `_site`{: .filepath} 폴더에 배치됩니다. 이 파일들을 대상 서버에 업로드하세요.

[nodejs]: https://nodejs.org/
[starter]: https://github.com/cotes2020/chirpy-starter
[pages-workflow-src]: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow
[docker-desktop]: https://www.docker.com/products/docker-desktop/
[docker-engine]: https://docs.docker.com/engine/install/
[vscode]: https://code.visualstudio.com/
[dev-containers]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[dc-clone-in-vol]: https://code.visualstudio.com/docs/devcontainers/containers#_quick-start-open-a-git-repository-or-github-pr-in-an-isolated-container-volume
[dc-open-in-container]: https://code.visualstudio.com/docs/devcontainers/containers#_quick-start-open-an-existing-folder-in-a-container
