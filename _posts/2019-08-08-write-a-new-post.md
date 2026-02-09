---
title: 새 포스트 작성하기
author: cotes
date: 2019-08-08 14:10:00 +0800
categories: [블로깅, 튜토리얼]
tags: [글쓰기]
render_with_liquid: false
---

이 튜토리얼은 _Chirpy_ 템플릿에서 포스트를 작성하는 방법을 안내하며, Jekyll을 이전에 사용해본 적이 있더라도 읽어볼 가치가 있습니다. 많은 기능이 특정 변수를 설정해야 하기 때문입니다.

## 이름 및 경로

`YYYY-MM-DD-TITLE.EXTENSION`{: .filepath} 형식으로 새 파일을 만들고 루트 디렉토리의 `_posts`{: .filepath}에 저장합니다. `EXTENSION`{: .filepath}은 `md`{: .filepath} 또는 `markdown`{: .filepath} 중 하나여야 합니다. 파일 생성 시간을 절약하려면 플러그인 [`Jekyll-Compose`](https://github.com/jekyll/jekyll-compose)를 사용하는 것을 고려해보세요.

## Front Matter

기본적으로 포스트 상단에 아래와 같이 [Front Matter](https://jekyllrb.com/docs/front-matter/)를 작성해야 합니다:

```yaml
---
title: TITLE
date: YYYY-MM-DD HH:MM:SS +/-TTTT
categories: [TOP_CATEGORY, SUB_CATEGORY]
tags: [TAG]     # TAG names should always be lowercase
---
```

> 포스트의 _layout_은 기본적으로 `post`로 설정되어 있으므로 Front Matter 블록에 _layout_ 변수를 추가할 필요가 없습니다.
{: .prompt-tip }

### 날짜의 시간대

포스트의 게시 날짜를 정확하게 기록하려면 `_config.yml`{: .filepath}의 `timezone`을 설정할 뿐만 아니라 Front Matter 블록의 `date` 변수에 포스트의 시간대를 제공해야 합니다. 형식: `+/-TTTT`, 예: `+0800`.

### 카테고리와 태그

각 포스트의 `categories`는 최대 두 개의 요소를 포함하도록 설계되었으며, `tags`의 요소 수는 0개부터 무한대까지 가능합니다. 예를 들어:

```yaml
---
categories: [Animal, Insect]
tags: [bee]
---
```

### 작성자 정보

포스트의 작성자 정보는 일반적으로 _Front Matter_에 작성할 필요가 없으며, 기본적으로 설정 파일의 `social.name` 변수와 `social.links`의 첫 번째 항목에서 가져옵니다. 그러나 다음과 같이 재정의할 수도 있습니다:

`_data/authors.yml`에 작성자 정보를 추가합니다 (웹사이트에 이 파일이 없으면 주저하지 말고 생성하세요).

```yaml
<author_id>:
  name: <full name>
  twitter: <twitter_of_author>
  url: <homepage_of_author>
```
{: file="_data/authors.yml" }

그런 다음 `author`를 사용하여 단일 항목을 지정하거나 `authors`를 사용하여 여러 항목을 지정합니다:

```yaml
---
author: <author_id>                     # for single entry
# or
authors: [<author1_id>, <author2_id>]   # for multiple entries
---
```

`author` 키는 여러 항목도 식별할 수 있습니다.

> `_data/authors.yml`{: .filepath } 파일에서 작성자 정보를 읽는 이점은 페이지에 메타 태그 `twitter:creator`가 포함되어 [Twitter Cards](https://developer.twitter.com/en/docs/twitter-for-websites/cards/guides/getting-started#card-and-content-attribution)를 강화하고 SEO에 좋다는 것입니다.
{: .prompt-info }

### 포스트 설명

기본적으로 포스트의 첫 단어가 홈 페이지의 포스트 목록, _Further Reading_ 섹션 및 RSS 피드의 XML에 표시됩니다. 포스트의 자동 생성된 설명을 표시하지 않으려면 다음과 같이 _Front Matter_의 `description` 필드를 사용하여 커스터마이징할 수 있습니다:

```yaml
---
description: Short summary of the post.
---
```

또한 `description` 텍스트는 포스트 페이지의 포스트 제목 아래에도 표시됩니다.

## 목차

기본적으로 **목**차(TOC)는 포스트의 오른쪽 패널에 표시됩니다. 전역으로 끄려면 `_config.yml`{: .filepath}로 이동하여 `toc` 변수의 값을 `false`로 설정하세요. 특정 포스트에 대해 목차를 끄려면 포스트의 [Front Matter](https://jekyllrb.com/docs/front-matter/)에 다음을 추가하세요:

```yaml
---
toc: false
---
```

## 댓글

댓글에 대한 전역 설정은 `_config.yml`{: .filepath} 파일의 `comments.provider` 옵션으로 정의됩니다. 이 변수에 대해 댓글 시스템이 선택되면 모든 포스트에 대해 댓글이 활성화됩니다.

특정 포스트에 대해 댓글을 닫으려면 포스트의 **Front Matter**에 다음을 추가하세요:

```yaml
---
comments: false
---
```

## 미디어

_Chirpy_에서는 이미지, 오디오 및 비디오를 미디어 리소스라고 합니다.

### URL 접두사

때때로 포스트에서 여러 리소스에 대해 중복된 URL 접두사를 정의해야 하는데, 이는 두 개의 매개변수를 설정하여 피할 수 있는 지루한 작업입니다.

- 미디어 파일을 호스팅하기 위해 CDN을 사용하는 경우 `_config.yml`{: .filepath }에서 `cdn`을 지정할 수 있습니다. 그러면 사이트 아바타 및 포스트의 미디어 리소스 URL 앞에 CDN 도메인 이름이 붙습니다.

  ```yaml
  cdn: https://cdn.com
  ```
  {: file='_config.yml' .nolineno }

- 현재 포스트/페이지 범위에 대한 리소스 경로 접두사를 지정하려면 포스트의 _front matter_에 `media_subpath`를 설정하세요:

  ```yaml
  ---
  media_subpath: /path/to/media/
  ---
  ```
  {: .nolineno }

`site.cdn`과 `page.media_subpath` 옵션은 개별적으로 또는 조합하여 사용하여 최종 리소스 URL을 유연하게 구성할 수 있습니다: `[site.cdn/][page.media_subpath/]file.ext`

### 이미지

#### 캡션

이미지의 다음 줄에 이탤릭체를 추가하면 캡션이 되어 이미지 하단에 나타납니다:

```markdown
![img-description](/path/to/image)
_Image Caption_
```
{: .nolineno}

#### 크기

이미지가 로드될 때 페이지 콘텐츠 레이아웃이 이동하는 것을 방지하려면 각 이미지에 대해 너비와 높이를 설정해야 합니다.

```markdown
![Desktop View](/assets/img/sample/mockup.png){: width="700" height="400" }
```
{: .nolineno}

> SVG의 경우 최소한 _width_를 지정해야 합니다. 그렇지 않으면 렌더링되지 않습니다.
{: .prompt-info }

_Chirpy v5.0.0_부터 `height`와 `width`는 약어를 지원합니다 (`height` → `h`, `width` → `w`). 다음 예제는 위와 동일한 효과를 가집니다:

```markdown
![Desktop View](/assets/img/sample/mockup.png){: w="700" h="400" }
```
{: .nolineno}

#### 위치

기본적으로 이미지는 중앙에 배치되지만 `normal`, `left`, `right` 클래스 중 하나를 사용하여 위치를 지정할 수 있습니다.

> 위치가 지정되면 이미지 캡션을 추가하면 안 됩니다.
{: .prompt-warning }

- **Normal 위치**

  아래 샘플에서 이미지가 왼쪽 정렬됩니다:

  ```markdown
  ![Desktop View](/assets/img/sample/mockup.png){: .normal }
  ```
  {: .nolineno}

- **왼쪽으로 띄우기**

  ```markdown
  ![Desktop View](/assets/img/sample/mockup.png){: .left }
  ```
  {: .nolineno}

- **오른쪽으로 띄우기**

  ```markdown
  ![Desktop View](/assets/img/sample/mockup.png){: .right }
  ```
  {: .nolineno}

#### 다크/라이트 모드

다크/라이트 모드에서 이미지가 테마 기본 설정을 따르도록 할 수 있습니다. 이를 위해서는 두 개의 이미지(다크 모드용 하나, 라이트 모드용 하나)를 준비한 다음 특정 클래스(`dark` 또는 `light`)를 할당해야 합니다:

```markdown
![Light mode only](/path/to/light-mode.png){: .light }
![Dark mode only](/path/to/dark-mode.png){: .dark }
```

#### 그림자

프로그램 창의 스크린샷은 그림자 효과를 표시하는 것으로 간주할 수 있습니다:

```markdown
![Desktop View](/assets/img/sample/mockup.png){: .shadow }
```
{: .nolineno}

#### 미리보기 이미지

포스트 상단에 이미지를 추가하려면 해상도가 `1200 x 630`인 이미지를 제공하세요. 이미지 종횡비가 `1.91 : 1`을 충족하지 않으면 이미지가 확대/축소되고 잘립니다.

이러한 전제 조건을 알고 있으면 이미지 속성을 설정할 수 있습니다:

```yaml
---
image:
  path: /path/to/image
  alt: image alternative text
---
```

[`media_subpath`](#url-접두사)도 미리보기 이미지에 전달될 수 있습니다. 즉, 설정된 경우 `path` 속성에는 이미지 파일 이름만 필요합니다.

간단하게 사용하려면 `image`를 사용하여 경로를 정의할 수도 있습니다.

```yml
---
image: /path/to/image
---
```

#### LQIP

미리보기 이미지의 경우:

```yaml
---
image:
  lqip: /path/to/lqip-file # or base64 URI
---
```

> "[Text and Typography](../text-and-typography/)" 포스트의 미리보기 이미지에서 LQIP를 관찰할 수 있습니다.

일반 이미지의 경우:

```markdown
![Image description](/path/to/image){: lqip="/path/to/lqip-file" }
```
{: .nolineno }

### 소셜 미디어 플랫폼

다음 구문으로 소셜 미디어 플랫폼의 비디오/오디오를 임베드할 수 있습니다:

```liquid
{% include embed/{Platform}.html id='{ID}' %}
```

여기서 `Platform`은 플랫폼 이름의 소문자이고 `ID`는 비디오 ID입니다.

다음 표는 주어진 비디오/오디오 URL에서 필요한 두 매개변수를 가져오는 방법을 보여주며, 현재 지원되는 비디오 플랫폼도 알 수 있습니다.

| Video URL                                                                                                                  | Platform   | ID                       |
| -------------------------------------------------------------------------------------------------------------------------- | ---------- | :----------------------- |
| [https://www.**youtube**.com/watch?v=**H-B46URT4mg**](https://www.youtube.com/watch?v=H-B46URT4mg)                         | `youtube`  | `H-B46URT4mg`            |
| [https://www.**twitch**.tv/videos/**1634779211**](https://www.twitch.tv/videos/1634779211)                                 | `twitch`   | `1634779211`             |
| [https://www.**bilibili**.com/video/**BV1Q44y1B7Wf**](https://www.bilibili.com/video/BV1Q44y1B7Wf)                         | `bilibili` | `BV1Q44y1B7Wf`           |
| [https://www.open.**spotify**.com/track/**3OuMIIFP5TxM8tLXMWYPGV**](https://open.spotify.com/track/3OuMIIFP5TxM8tLXMWYPGV) | `spotify`  | `3OuMIIFP5TxM8tLXMWYPGV` |

Spotify는 몇 가지 추가 매개변수를 지원합니다:

- `compact` - 컴팩트 플레이어 표시 (예: `{% include embed/spotify.html id='3OuMIIFP5TxM8tLXMWYPGV' compact=1 %}`);
- `dark` - 다크 테마 강제 적용 (예: `{% include embed/spotify.html id='3OuMIIFP5TxM8tLXMWYPGV' dark=1 %}`).

### 비디오 파일

비디오 파일을 직접 임베드하려면 다음 구문을 사용하세요:

```liquid
{% include embed/video.html src='{URL}' %}
```

여기서 `URL`은 비디오 파일의 URL입니다. 예: `/path/to/sample/video.mp4`.

임베드된 비디오 파일에 대한 추가 속성을 지정할 수도 있습니다. 다음은 허용되는 속성의 전체 목록입니다.

- `poster='/path/to/poster.png'` — 비디오를 다운로드하는 동안 표시되는 비디오의 포스터 이미지
- `title='Text'` — 비디오 아래에 나타나고 이미지와 동일하게 보이는 비디오 제목
- `autoplay=true` — 비디오가 가능한 한 빨리 자동으로 재생되기 시작합니다
- `loop=true` — 비디오가 끝에 도달하면 자동으로 시작 부분으로 돌아갑니다
- `muted=true` — 오디오가 처음에 음소거됩니다
- `types` — `|`로 구분된 추가 비디오 형식의 확장자를 지정합니다. 이러한 파일이 기본 비디오 파일과 동일한 디렉토리에 있는지 확인하세요.

위의 모든 것을 사용하는 예제를 고려하세요:

```liquid
{%
  include embed/video.html
  src='/path/to/video.mp4'
  types='ogg|mov'
  poster='poster.png'
  title='Demo video'
  autoplay=true
  loop=true
  muted=true
%}
```

### 오디오 파일

오디오 파일을 직접 임베드하려면 다음 구문을 사용하세요:

```liquid
{% include embed/audio.html src='{URL}' %}
```

여기서 `URL`은 오디오 파일의 URL입니다. 예: `/path/to/audio.mp3`.

임베드된 오디오 파일에 대한 추가 속성을 지정할 수도 있습니다. 다음은 허용되는 속성의 전체 목록입니다.

- `title='Text'` — 오디오 아래에 나타나고 이미지와 동일하게 보이는 오디오 제목
- `types` — `|`로 구분된 추가 오디오 형식의 확장자를 지정합니다. 이러한 파일이 기본 오디오 파일과 동일한 디렉토리에 있는지 확인하세요.

위의 모든 것을 사용하는 예제를 고려하세요:

```liquid
{%
  include embed/audio.html
  src='/path/to/audio.mp3'
  types='ogg|wav|aac'
  title='Demo audio'
%}
```

## 고정된 포스트

홈 페이지 상단에 하나 이상의 포스트를 고정할 수 있으며, 고정된 포스트는 게시 날짜에 따라 역순으로 정렬됩니다. 다음과 같이 활성화합니다:

```yaml
---
pin: true
---
```

## 프롬프트

`tip`, `info`, `warning`, `danger` 등 여러 유형의 프롬프트가 있습니다. blockquote에 `prompt-{type}` 클래스를 추가하여 생성할 수 있습니다. 예를 들어 `info` 유형의 프롬프트를 다음과 같이 정의합니다:

```md
> Example line for prompt.
{: .prompt-info }
```
{: .nolineno }

## 문법

### 인라인 코드

```md
`inline code part`
```
{: .nolineno }

### 파일 경로 하이라이트

```md
`/path/to/a/file.extend`{: .filepath}
```
{: .nolineno }

### 코드 블록

마크다운 기호 ```` ``` ````를 사용하면 다음과 같이 코드 블록을 쉽게 만들 수 있습니다:

````md
```
This is a plaintext code snippet.
```
````

#### 언어 지정

```` ```{language} ````를 사용하면 구문 강조가 있는 코드 블록을 얻을 수 있습니다:

````markdown
```yaml
key: value
```
````

> Jekyll 태그 `{% highlight %}`는 이 테마와 호환되지 않습니다.
{: .prompt-danger }

#### 줄 번호

기본적으로 `plaintext`, `console`, `terminal`을 제외한 모든 언어는 줄 번호를 표시합니다. 코드 블록의 줄 번호를 숨기려면 `nolineno` 클래스를 추가하세요:

````markdown
```shell
echo 'No more line numbers!'
```
{: .nolineno }
````

#### 파일 이름 지정

코드 언어가 코드 블록 상단에 표시되는 것을 알 수 있습니다. 파일 이름으로 바꾸려면 `file` 속성을 추가하면 됩니다:

````markdown
```shell
# content
```
{: file="path/to/file" }
````

#### Liquid 코드

**Liquid** 스니펫을 표시하려면 liquid 코드를 `{% raw %}`와 `{% endraw %}`로 둘러싸세요:

````markdown
{% raw %}
```liquid
{% if product.title contains 'Pack' %}
  This product's title contains the word Pack.
{% endif %}
```
{% endraw %}
````

또는 포스트의 YAML 블록에 `render_with_liquid: false`를 추가합니다 (Jekyll 4.0 이상 필요).

## 수학

수학을 생성하기 위해 [**MathJax**][mathjax]를 사용합니다. 웹사이트 성능 이유로 수학 기능은 기본적으로 로드되지 않습니다. 그러나 다음과 같이 활성화할 수 있습니다:

[mathjax]: https://www.mathjax.org/

```yaml
---
math: true
---
```

수학 기능을 활성화한 후 다음 구문으로 수학 방정식을 추가할 수 있습니다:

- **블록 수학**은 `$$ math $$` 앞뒤에 **필수** 빈 줄과 함께 추가해야 합니다
  - **방정식 번호 삽입**은 `$$\begin{equation} math \end{equation}$$`로 추가해야 합니다
  - **방정식 번호 참조**는 방정식 블록에서 `\label{eq:label_name}`, 텍스트와 함께 인라인으로 `\eqref{eq:label_name}`로 수행해야 합니다 (아래 예제 참조)
- **인라인 수학**(줄 내)은 `$$ math $$ ` 앞뒤에 빈 줄 없이 추가해야 합니다
- **인라인 수학**(목록 내)은 `\$$ math $$`로 추가해야 합니다

```markdown
<!-- Block math, keep all blank lines -->

$$
LaTeX_math_expression
$$

<!-- Equation numbering, keep all blank lines  -->

$$
\begin{equation}
  LaTeX_math_expression
  \label{eq:label_name}
\end{equation}
$$

Can be referenced as \eqref{eq:label_name}.

<!-- Inline math in lines, NO blank lines -->

"Lorem ipsum dolor sit amet, $$ LaTeX_math_expression $$ consectetur adipiscing elit."

<!-- Inline math in lists, escape the first `$` -->

1. \$$ LaTeX_math_expression $$
2. \$$ LaTeX_math_expression $$
3. \$$ LaTeX_math_expression $$
```

> `v7.0.0`부터 **MathJax**에 대한 구성 옵션이 `assets/js/data/mathjax.js`{: .filepath } 파일로 이동되었으며, [extensions][mathjax-exts] 추가와 같이 필요에 따라 옵션을 변경할 수 있습니다.
> `chirpy-starter`를 통해 사이트를 빌드하는 경우 gem 설치 디렉토리(`bundle info --path jekyll-theme-chirpy` 명령으로 확인)에서 저장소의 동일한 디렉토리로 해당 파일을 복사하세요.
{: .prompt-tip }

[mathjax-exts]: https://docs.mathjax.org/en/latest/input/tex/extensions/index.html

## Mermaid

[**Mermaid**](https://github.com/mermaid-js/mermaid)는 훌륭한 다이어그램 생성 도구입니다. 포스트에서 활성화하려면 YAML 블록에 다음을 추가하세요:

```yaml
---
mermaid: true
---
```

그런 다음 다른 마크다운 언어처럼 사용할 수 있습니다: 그래프 코드를 ```` ```mermaid ````와 ```` ``` ````로 둘러싸세요.

## 더 알아보기

Jekyll 포스트에 대한 자세한 내용은 [Jekyll Docs: Posts](https://jekyllrb.com/docs/posts/)를 방문하세요.
