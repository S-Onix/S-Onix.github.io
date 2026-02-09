---
title: 텍스트와 타이포그래피
description: 텍스트, 타이포그래피, 수학 방정식, 다이어그램, 순서도, 사진, 비디오 등의 예제입니다.
author: cotes
date: 2019-08-08 11:33:00 +0800
categories: [블로깅, 데모]
tags: [typography]
pin: true
math: true
mermaid: true
image:
  path: /commons/devices-mockup.png
  lqip: data:image/webp;base64,UklGRpoAAABXRUJQVlA4WAoAAAAQAAAADwAABwAAQUxQSDIAAAARL0AmbZurmr57yyIiqE8oiG0bejIYEQTgqiDA9vqnsUSI6H+oAERp2HZ65qP/VIAWAFZQOCBCAAAA8AEAnQEqEAAIAAVAfCWkAALp8sF8rgRgAP7o9FDvMCkMde9PK7euH5M1m6VWoDXf2FkP3BqV0ZYbO6NA/VFIAAAA
  alt: 여러 기기에서 Chirpy 테마의 반응형 렌더링.
---

## 제목

<!-- markdownlint-capture -->
<!-- markdownlint-disable -->
# H1 — 제목
{: .mt-4 .mb-0 }

## H2 — 제목
{: data-toc-skip='' .mt-4 .mb-0 }

### H3 — 제목
{: data-toc-skip='' .mt-4 .mb-0 }

#### H4 — 제목
{: data-toc-skip='' .mt-4 }
<!-- markdownlint-restore -->

## 단락

Quisque egestas convallis ipsum, ut sollicitudin risus tincidunt a. Maecenas interdum malesuada egestas. Duis consectetur porta risus, sit amet vulputate urna facilisis ac. Phasellus semper dui non purus ultrices sodales. Aliquam ante lorem, ornare a feugiat ac, finibus nec mauris. Vivamus ut tristique nisi. Sed vel leo vulputate, efficitur risus non, posuere mi. Nullam tincidunt bibendum rutrum. Proin commodo ornare sapien. Vivamus interdum diam sed sapien blandit, sit amet aliquam risus mattis. Nullam arcu turpis, mollis quis laoreet at, placerat id nibh. Suspendisse venenatis eros eros.

## 목록

### 순서가 있는 목록

1. 첫째
2. 둘째
3. 셋째

### 순서가 없는 목록

- 챕터
  - 섹션
    - 단락

### ToDo 목록

- [ ] 작업
  - [x] 단계 1
  - [x] 단계 2
  - [ ] 단계 3

### 설명 목록

태양
: 지구가 공전하는 별

달
: 지구의 자연 위성으로, 태양의 반사광으로 보임

## 인용구

> 이 줄은 _인용구_를 보여줍니다.

## 프롬프트

<!-- markdownlint-capture -->
<!-- markdownlint-disable -->
> `tip` 타입 프롬프트를 보여주는 예제입니다.
{: .prompt-tip }

> `info` 타입 프롬프트를 보여주는 예제입니다.
{: .prompt-info }

> `warning` 타입 프롬프트를 보여주는 예제입니다.
{: .prompt-warning }

> `danger` 타입 프롬프트를 보여주는 예제입니다.
{: .prompt-danger }
<!-- markdownlint-restore -->

## 표

| 회사                          | 담당자           | 국가    |
| :--------------------------- | :--------------- | ------: |
| Alfreds Futterkiste          | Maria Anders     | Germany |
| Island Trading               | Helen Bennett    |      UK |
| Magazzini Alimentari Riuniti | Giovanni Rovelli |   Italy |

## 링크

<http://127.0.0.1:4000>

## 각주

후크를 클릭하면 각주[^footnote]로 이동하며, 여기 다른 각주[^fn-nth-2]도 있습니다.

## 인라인 코드

다음은 `인라인 코드`의 예제입니다.

## 파일 경로

다음은 `/path/to/the/file.extend`{: .filepath}입니다.

## 코드 블록

### 일반

```text
이것은 구문 강조와 줄 번호가 없는 일반 코드 스니펫입니다.
```

### 특정 언어

```bash
if [ $? -ne 0 ]; then
  echo "The command was not successful.";
  #do the needful / exit
fi;
```

### 특정 파일명

```sass
@import
  "colors/light-typography",
  "colors/dark-typography";
```
{: file='_sass/jekyll-theme-chirpy.scss'}

## 수학

[**MathJax**](https://www.mathjax.org/)로 구동되는 수학:

$$
\begin{equation}
  \sum_{n=1}^\infty 1/n^2 = \frac{\pi^2}{6}
  \label{eq:series}
\end{equation}
$$

방정식을 \eqref{eq:series}로 참조할 수 있습니다.

$a \ne 0$일 때, $ax^2 + bx + c = 0$의 두 해는

$$ x = {-b \pm \sqrt{b^2-4ac} \over 2a} $$

## Mermaid SVG

```mermaid
 gantt
  title  mermaid에 GANTT 다이어그램 기능 추가하기
  apple :a, 2017-07-20, 1w
  banana :crit, b, 2017-07-23, 1d
  cherry :active, c, after b a, 1d
```

## 이미지

### 기본 (캡션 포함)

![Desktop View](/posts/20190808/mockup.png){: width="972" height="589" }
_전체 화면 너비 및 중앙 정렬_

### 왼쪽 정렬

![Desktop View](/posts/20190808/mockup.png){: width="972" height="589" .w-75 .normal}

### 왼쪽으로 띄우기

![Desktop View](/posts/20190808/mockup.png){: width="972" height="589" .w-50 .left}
Praesent maximus aliquam sapien. Sed vel neque in dolor pulvinar auctor. Maecenas pharetra, sem sit amet interdum posuere, tellus lacus eleifend magna, ac lobortis felis ipsum id sapien. Proin ornare rutrum metus, ac convallis diam volutpat sit amet. Phasellus volutpat, elit sit amet tincidunt mollis, felis mi scelerisque mauris, ut facilisis leo magna accumsan sapien. In rutrum vehicula nisl eget tempor. Nullam maximus ullamcorper libero non maximus. Integer ultricies velit id convallis varius. Praesent eu nisl eu urna finibus ultrices id nec ex. Mauris ac mattis quam. Fusce aliquam est nec sapien bibendum, vitae malesuada ligula condimentum.

### 오른쪽으로 띄우기

![Desktop View](/posts/20190808/mockup.png){: width="972" height="589" .w-50 .right}
Praesent maximus aliquam sapien. Sed vel neque in dolor pulvinar auctor. Maecenas pharetra, sem sit amet interdum posuere, tellus lacus eleifend magna, ac lobortis felis ipsum id sapien. Proin ornare rutrum metus, ac convallis diam volutpat sit amet. Phasellus volutpat, elit sit amet tincidunt mollis, felis mi scelerisque mauris, ut facilisis leo magna accumsan sapien. In rutrum vehicula nisl eget tempor. Nullam maximus ullamcorper libero non maximus. Integer ultricies velit id convallis varius. Praesent eu nisl eu urna finibus ultrices id nec ex. Mauris ac mattis quam. Fusce aliquam est nec sapien bibendum, vitae malesuada ligula condimentum.

### 다크/라이트 모드 & 그림자

아래 이미지는 테마 기본 설정에 따라 다크/라이트 모드를 전환하며, 그림자가 있습니다.

![light mode only](/posts/20190808/devtools-light.png){: .light .w-75 .shadow .rounded-10 w='1212' h='668' }
![dark mode only](/posts/20190808/devtools-dark.png){: .dark .w-75 .shadow .rounded-10 w='1212' h='668' }

## 비디오

{% include embed/youtube.html id='Balreaj8Yqs' %}

## 역방향 각주

[^footnote]: 각주 소스
[^fn-nth-2]: 2번째 각주 소스
