---
layout: post
title:  "Jekyll에 오신 것을 환영합니다!"
date:   2026-02-09 23:08:32 +0900
categories: [Jekyll, 업데이트]
---
이 포스트는 `_posts` 디렉토리에서 찾을 수 있습니다. 편집한 후 사이트를 다시 빌드하면 변경 사항을 확인할 수 있습니다. 사이트를 다시 빌드하는 방법은 여러 가지가 있지만, 가장 일반적인 방법은 `jekyll serve`를 실행하는 것입니다. 이 명령은 웹 서버를 시작하고 파일이 업데이트될 때 자동으로 사이트를 재생성합니다.

Jekyll은 블로그 포스트 파일 이름이 다음 형식을 따라야 합니다:

`YEAR-MONTH-DAY-title.MARKUP`

여기서 `YEAR`는 4자리 숫자, `MONTH`와 `DAY`는 2자리 숫자, `MARKUP`은 파일에서 사용되는 형식을 나타내는 파일 확장자입니다. 그런 다음 필요한 front matter를 포함합니다. 이 포스트의 소스를 보고 작동 방식에 대한 아이디어를 얻으세요.

Jekyll은 코드 스니펫에 대한 강력한 지원도 제공합니다:

{% highlight ruby %}
def print_hi(name)
  puts "Hi, #{name}"
end
print_hi('Tom')
#=> prints 'Hi, Tom' to STDOUT.
{% endhighlight %}

Jekyll을 최대한 활용하는 방법에 대한 자세한 내용은 [Jekyll 문서][jekyll-docs]를 확인하세요. 모든 버그/기능 요청은 [Jekyll의 GitHub 저장소][jekyll-gh]에 제출하세요. 질문이 있으면 [Jekyll Talk][jekyll-talk]에서 물어볼 수 있습니다.

[jekyll-docs]: https://jekyllrb.com/docs/home
[jekyll-gh]:   https://github.com/jekyll/jekyll
[jekyll-talk]: https://talk.jekyllrb.com/
