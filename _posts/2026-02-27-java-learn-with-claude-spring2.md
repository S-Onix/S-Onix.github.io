---
title: Spring 깊이 이해하기 2편 - Servlet과 DispatcherServlet
date: 2026-02-27 16:12:35 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : HTTP 통신을 위한 Servlet 공부

## 📝 본문

## 1. Servlet — HTTP 요청을 처리하는 표준 규격

Servlet이란, Java로 HTTP 요청을 받아서 응답을 만드는 **표준 규격(인터페이스)**입니다. "주문이 들어오면 이런 형식으로 받고, 이런 형식으로 응답해라"라는 약속이죠.

```java
public class MyServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
        // req = 클라이언트의 요청 정보 (URL, 파라미터, 헤더 등)
        // resp = 서버가 보낼 응답 (HTML, JSON 등)
        resp.getWriter().write("Hello!");
    }
}
```

Spring MVC를 쓰면 `@GetMapping` 같은 어노테이션으로 편하게 개발하지만, 그 밑바닥에서는 이 Servlet이 돌아가고 있습니다. Spring은 Servlet을 **감싸서 편하게 만든 것**이지, 대체한 것이 아닙니다.

참고로, 원래 패키지명은 `javax.servlet`이었지만, Java EE가 Eclipse 재단으로 이관되면서 **Jakarta Servlet**(`jakarta.servlet`)으로 변경되었습니다. Spring Boot 3.x부터 Jakarta를 사용합니다.

------



## 2. Servlet Container — 서블릿을 실행하는 런타임 환경

Servlet Container는 서블릿의 생명주기를 관리하는 런타임 환경입니다. 서블릿이 "요리 레시피"라면, 서블릿 컨테이너는 그 레시피를 실행할 수 있는 주방 시설 자체입니다. Tomcat, Jetty, Undertow가 모두 서블릿 컨테이너에 해당합니다.

서블릿 컨테이너가 하는 일은 다음과 같습니다.

- **생명주기 관리**: 서블릿 객체를 생성(`init`)하고, 요청마다 호출(`service`)하고, 종료 시 정리(`destroy`)
- **스레드 관리**: 요청마다 스레드를 할당하여 동시 처리
- **네트워크 통신**: TCP/IP, HTTP 파싱 등 저수준 통신을 처리
- **보안**: SSL, 인증 등의 보안 기능 제공

```
                    Servlet Container (Tomcat)
                  ┌─────────────────────────────┐
HTTP 요청 →       │  Thread Pool                 │
                  │    ├── Thread-1 → Servlet A  │
                  │    ├── Thread-2 → Servlet B  │
                  │    └── Thread-3 → Servlet A  │
                  └─────────────────────────────┘
```

같은 Servlet 코드를 Tomcat에서도, Jetty에서도 실행할 수 있다는 것이 핵심입니다. 표준 규격을 따르기 때문입니다.

------



## 3. DispatcherServlet — Spring MVC의 총괄 셰프

DispatcherServlet은 Spring MVC에서 **모든 요청을 가장 먼저 받는 단 하나의 서블릿**입니다. 중요한 것은, DispatcherServlet도 결국 Servlet 인터페이스를 구현한 하나의 서블릿이라는 점입니다. Servlet Container(Tomcat) 위에서 돌아갑니다.

DispatcherServlet이 요청을 처리하는 흐름은 다음과 같습니다.

```
모든 HTTP 요청
     ↓
DispatcherServlet (단 하나의 진입점)
     ↓
HandlerMapping → "이 URL은 어떤 Controller가 처리하지?"
     ↓
HandlerAdapter → Controller 메서드 실행
     ↓
ViewResolver → 응답 형식 결정 (JSON? HTML?)
     ↓
HTTP 응답
```

전체 요청 처리 경로를 정리하면 다음과 같습니다.

```
HTTP 요청 → Servlet Container(Tomcat) → DispatcherServlet → Controller
```

------



## 4. Front Controller Pattern — 왜 하나의 진입점이 필요한가

Front Controller 패턴이란, 모든 요청을 **하나의 진입점**에서 받아 처리하는 디자인 패턴입니다. DispatcherServlet이 바로 이 패턴의 구현체입니다.

이 패턴이 없던 시절에는 URL마다 별도의 서블릿을 만들어야 했습니다.

```
/order    → OrderServlet
/payment  → PaymentServlet
/user     → UserServlet
→ 서블릿마다 인코딩, 인증, 로깅을 각각 처리해야 함
```

Front Controller 패턴을 적용하면 공통 처리가 한 곳으로 모입니다.

```
/order  ─┐
/payment ─┼→ DispatcherServlet → 인코딩, 인증, 로깅 공통 처리 → 각 Controller로 분배
/user   ─┘
```

마치 대형 건물의 정문 보안 데스크와 같습니다. 누가 오든 정문을 거쳐야 하고, 여기서 신분증 확인(인증), 방문 기록(로깅)을 한 번에 처리한 뒤 해당 부서로 안내합니다.

------



## 핵심 키워드

| 키워드                       | 설명                                                         |
| ---------------------------- | ------------------------------------------------------------ |
| **Servlet**                  | Java로 HTTP 요청/응답을 처리하는 표준 인터페이스             |
| **Jakarta Servlet**          | javax.servlet에서 이관된 새 패키지명 (Spring Boot 3.x~)      |
| **Servlet Container**        | 서블릿의 생명주기와 스레드를 관리하는 런타임 환경 (Tomcat, Jetty) |
| **DispatcherServlet**        | Spring MVC의 모든 요청을 받는 단일 진입점 서블릿             |
| **Front Controller Pattern** | 모든 요청을 하나의 진입점에서 받아 처리하는 디자인 패턴      |
| **HandlerMapping**           | URL과 Controller 메서드를 매핑하는 컴포넌트                  |
| **HandlerAdapter**           | Controller 메서드를 실제로 실행하는 컴포넌트                 |
| **ViewResolver**             | 응답 형식(JSON, HTML 등)을 결정하는 컴포넌트                 |



## 🎯 면접 예상 질문

### Q1. Servlet이란 무엇이며, Spring MVC와의 관계를 설명해주세요.

**모범 답안:**

> Servlet은 Java에서 HTTP 요청을 받아 응답을 생성하는 표준 인터페이스입니다. Servlet은 스스로 실행될 수 없고, Servlet Container(Tomcat, Jetty 등)라는 런타임 환경 위에서 실행됩니다. Spring MVC는 이 Servlet을 감싸서 @GetMapping 같은 어노테이션으로 편리하게 사용할 수 있도록 한 것이지, Servlet을 대체한 것은 아닙니다.

### Q2. DispatcherServlet의 역할과 요청 처리 흐름을 설명해주세요.

**모범 답안:**

> DispatcherServlet은 모든 HTTP 요청을 가장 먼저 받는 단일 진입점입니다. 요청이 들어오면 HandlerMapping을 통해 해당 URL을 처리할 Controller를 찾고, HandlerAdapter가 해당 Controller 메서드를 실행하고, ViewResolver가 응답 형식을 결정하여 클라이언트에게 응답을 반환합니다.

### Q3. Front Controller 패턴이 필요한 이유는 무엇인가요?

**모범 답안:**

> Front Controller 패턴이 없으면 URL마다 별도의 서블릿을 만들어야 하고, 인코딩 처리, 인증, 로깅 같은 공통 로직을 각 서블릿에서 중복 구현해야 합니다. DispatcherServlet이라는 하나의 진입점으로 모든 요청을 받으면, 공통 처리를 한 곳에서 관리할 수 있고, 이후 적절한 Controller로 분배하는 일관된 파이프라인을 구성할 수 있습니다.

**주의할 점:**

- 서블릿 객체는 싱글톤으로 하나만 생성되어 여러 스레드가 공유합니다. "스레드 하나에 서블릿 하나가 할당된다"는 틀린 설명입니다.
- Front Controller의 핵심 이유는 스레드/메모리 문제가 아니라, **공통 처리의 중복 제거**와 **일관된 요청 파이프라인 구성**입니다
