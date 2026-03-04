---
title: Spring 깊이 이해하기 8편 - WebFlux
date: 2026-03-04 15:49:40 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : WebFlux에 대한 전반적인 이해

## 📝 본문

## 1. WebFlux가 필요한 이유

Thread Model 편에서 배운 Thread-per-Request + Blocking I/O의 한계에서 출발합니다.

```
Tomcat (Spring MVC):
  Thread-1: [일][일][DB 대기........][일]     ← 대기 중에도 스레드 점유
  Thread-200: 전부 대기 중 → 201번째 요청은 처리 불가!

해결책:
  방법 1: 스레드를 더 늘린다 → 메모리 한계, 컨텍스트 스위칭 비용
  방법 2: 대기 시간에 스레드를 다른 일에 쓴다 → WebFlux!
```

------



## 2. Spring MVC vs WebFlux

|                 | Spring MVC                | Spring WebFlux                    |
| --------------- | ------------------------- | --------------------------------- |
| **I/O 모델**    | Blocking                  | Non-blocking                      |
| **서버**        | Tomcat (Thread Pool)      | Netty (Event Loop)                |
| **스레드 수**   | 많음 (기본 200)           | 적음 (CPU 코어 수)                |
| **동시 처리**   | 스레드 수에 비례          | 스레드 수와 무관하게 높음         |
| **코드 스타일** | 명령형 (순차적, 익숙함)   | 리액티브 (체이닝, 학습 곡선 높음) |
| **DB**          | JDBC, JPA                 | R2DBC, Reactive MongoDB           |
| **디버깅**      | 쉬움 (스택 트레이스 명확) | 어려움 (비동기 흐름 추적 어려움)  |

Spring MVC는 Servlet 기반으로 Tomcat(Servlet Container) 위에서 동작하고, WebFlux는 Servlet이 아닌 Netty(Event Loop) 위에서 동작합니다.

------



## 3. Blocking vs Non-blocking — 코드 비교

### Spring MVC (Blocking)

```java
@GetMapping("/order/{id}")
public Order getOrder(@PathVariable Long id) {
    Order order = orderRepository.findById(id);  // DB 응답까지 스레드 멈춤
    return order;
}
```

### Spring WebFlux (Non-blocking)

```java
@GetMapping("/order/{id}")
public Mono<Order> getOrder(@PathVariable Long id) {
    return orderRepository.findById(id);  // DB에 요청만 보내고 스레드는 다른 일하러 감
}
```

------



## 4. Mono와 Flux

### Mono — 0개 또는 1개의 데이터를 비동기로 전달

```java
Mono<Order> order = orderRepository.findById(1L);

Mono.just("Hello")              // 값이 이미 있을 때
Mono.empty()                    // 빈 값 (null 대신)
Mono.error(new RuntimeException("에러"))  // 에러 전달
```

### Flux — 0개 이상 여러 개의 데이터를 비동기로 전달

```java
Flux<Order> orders = orderRepository.findAll();

Flux.just("A", "B", "C")
Flux.fromIterable(List.of("A", "B", "C"))
Flux.interval(Duration.ofSeconds(1))     // 1초마다 0, 1, 2, 3...
```

### 핵심 연산자

```java
// map — 단순 변환 (동기)
orderMono.map(order -> order.getTotal())          // Mono<Integer>

// flatMap — 비동기 작업 연결 (안에서 Mono/Flux 반환)
orderMono.flatMap(order -> paymentService.pay(order))  // Mono<Payment>

// filter — 조건 필터링
orderFlux.filter(order -> order.getTotal() > 10000)

// zip — 여러 Mono를 동시에 실행하고 합치기
Mono.zip(orderMono, userMono)
    .map(tuple -> new OrderDetail(tuple.getT1(), tuple.getT2()));
```

**map vs flatMap 규칙**: 변환 결과가 일반 값이면 `map`, Mono나 Flux이면 `flatMap`

### Lazy Evaluation

`subscribe()`를 호출하기 전까지 아무것도 실행되지 않습니다. WebFlux Controller에서는 Mono/Flux를 return하면 Spring이 자동으로 `subscribe()`를 호출해줍니다.

------



## 5. Event Loop — WebFlux의 엔진

```
Spring MVC + Tomcat:
  200개의 스레드가 각각 1개의 요청을 전담

Spring WebFlux + Netty:
  소수의 Event Loop 스레드(보통 CPU 코어 수)
  → 각 스레드가 수천 개의 요청을 번갈아 처리
Event Loop 동작:
  [요청1: DB 요청 보냄] → 대기 등록
  [요청2: DB 요청 보냄] → 대기 등록
  [요청1: DB 응답 도착!] → 콜백으로 나머지 처리 후 응답
  [요청2: DB 응답 도착!] → 콜백으로 나머지 처리 후 응답
```

핵심: 대기 시간에 스레드가 멈추지 않고 다른 요청을 처리합니다.

------



## 6. Event Loop를 막지 마라 — WebFlux의 치명적 규칙

Event Loop 스레드는 소수(보통 4~8개)뿐입니다. 이 스레드가 Blocking되면 전체 시스템이 멈춥니다.

java

```java
// 🚫 절대 하면 안 되는 코드
@GetMapping("/order/{id}")
public Mono<Order> getOrder(@PathVariable Long id) {
    Order order = jdbcTemplate.queryForObject("SELECT ...");  // Event Loop 멈춤!
    return Mono.just(order);
}
Event Loop 4개 중 1개 Blocking → 전체 요청의 25% 마비
4개 전부 Blocking → 서버 전체 마비!
```

| 라이브러리          | Blocking (사용 불가) | Non-blocking (사용 가능) |
| ------------------- | -------------------- | ------------------------ |
| **DB 접근**         | JDBC, JPA/Hibernate  | R2DBC, Reactive MongoDB  |
| **HTTP 클라이언트** | RestTemplate         | WebClient                |
| **Redis**           | Jedis                | Lettuce (Reactive)       |

Blocking 코드를 꼭 써야 하면 `Schedulers.boundedElastic()`으로 격리합니다.

```java
public Mono<Order> getOrder(Long id) {
    return Mono.fromCallable(() -> jdbcTemplate.queryForObject("SELECT ..."))
               .subscribeOn(Schedulers.boundedElastic());
    // Blocking은 별도 스레드 풀에서, Event Loop는 안전
}
```

------



## 7. WebClient — Non-blocking HTTP 클라이언트

```java
// RestTemplate (Blocking) — Spring MVC
User user = restTemplate.getForObject("/api/users/1", User.class);

// WebClient (Non-blocking) — WebFlux
Mono<User> userMono = webClient.get()
    .uri("/api/users/{id}", 1)
    .retrieve()
    .bodyToMono(User.class);
```



### 여러 API 동시 호출 — WebFlux의 진짜 강점

```java
// Spring MVC (순차 실행) — 총 3초
User user = restTemplate.getForObject("/users/1");       // 1초
Order order = restTemplate.getForObject("/orders/1");    // 1초
Payment payment = restTemplate.getForObject("/payments/1"); // 1초

// WebFlux (동시 실행) — 총 1초!
Mono.zip(userMono, orderMono, paymentMono)
    .map(tuple -> new OrderDetail(tuple.getT1(), tuple.getT2(), tuple.getT3()));
```

------



## 8. Scheduler — 스레드 제어

| Scheduler                       | 용도              |
| ------------------------------- | ----------------- |
| **Schedulers.parallel()**       | CPU 집약적 작업   |
| **Schedulers.boundedElastic()** | Blocking I/O 격리 |
| **Schedulers.single()**         | 순서 보장 필요 시 |

------



## 9. 에러 처리

| 연산자            | 역할                       |
| ----------------- | -------------------------- |
| **onErrorReturn** | 에러 시 기본값 반환        |
| **onErrorResume** | 에러 시 대체 로직 실행     |
| **doOnError**     | 에러 로깅 (흐름 변경 없음) |
| **retry(n)**      | 에러 시 n번 재시도         |
| **switchIfEmpty** | 빈 값일 때 대체 동작       |

------



## 10. 언제 뭘 쓸까?

**Spring MVC가 적합한 경우:**

- CRUD 중심의 일반적인 웹 서비스
- JPA/JDBC 생태계가 필요한 경우
- 팀원 대부분이 명령형 코드에 익숙한 경우
- 디버깅 편의성이 중요한 경우

**WebFlux가 적합한 경우:**

- 마이크로서비스 간 대량 비동기 통신
- 실시간 스트리밍 (SSE, WebSocket)
- 적은 리소스로 높은 동시 처리가 필요한 경우
- Non-blocking 생태계가 이미 갖춰진 팀

------



## 11. Virtual Thread (Java 21+) — 제3의 선택지

```
Platform Thread (기존):  1개 ≈ 1MB 메모리, OS 커널 등록 → 수천 개가 한계
Virtual Thread (새로운): 1개 ≈ 수 KB 메모리, JVM이 관리 → 수백만 개 가능
```

|                 | Spring MVC     | MVC + Virtual Thread | Spring WebFlux       |
| --------------- | -------------- | -------------------- | -------------------- |
| **코드 스타일** | 명령형 (익숙)  | 명령형 (익숙)        | 리액티브 (학습 곡선) |
| **I/O**         | Blocking       | Blocking (자동 양보) | Non-blocking         |
| **동시성**      | 스레드 수 제한 | 매우 높음            | 매우 높음            |
| **DB**          | JDBC, JPA      | JDBC, JPA            | R2DBC                |
| **디버깅**      | 쉬움           | 쉬움                 | 어려움               |
| **스트리밍**    | 불가           | 불가                 | SSE, WebSocket 우수  |

WebFlux는 "대기 시간에 스레드가 다른 일을 한다" (Non-blocking), Virtual Thread는 "대기해도 괜찮다, 스레드가 가벼우니까" (Blocking이지만 저비용).

------



## 핵심 키워드

| 카테고리              | 키워드                                              |
| --------------------- | --------------------------------------------------- |
| **핵심 개념**         | WebFlux, Non-blocking I/O, Reactive, Event-driven   |
| **서버**              | Netty, Event Loop, Tomcat과의 차이                  |
| **데이터 타입**       | Mono, Flux, Publisher, Lazy Evaluation, subscribe() |
| **연산자**            | map, flatMap, filter, zip, switchIfEmpty            |
| **에러 처리**         | onErrorReturn, onErrorResume, retry                 |
| **주의사항**          | Event Loop Blocking 금지, JDBC 사용 불가            |
| **Non-blocking 도구** | R2DBC, WebClient, Reactive MongoDB, Lettuce         |
| **스레드 제어**       | Schedulers, boundedElastic, parallel                |
| **비교**              | Spring MVC vs WebFlux vs Virtual Thread             |



## 🎯 면접 예상 질문

### Q1. Spring MVC와 Spring WebFlux의 차이를 설명해주세요.

**모범 답안:**

> Spring MVC는 Blocking I/O 기반으로 Tomcat 위에서 동작하며, 요청 하나당 스레드 하나를 배정하는 Thread-per-Request 모델입니다. 기본 스레드 200개가 전부 I/O 대기 상태에 빠지면 이후 요청을 처리할 수 없습니다. Spring WebFlux는 Non-blocking I/O 기반으로 Netty 위에서 동작하며, 소수의 Event Loop 스레드(보통 CPU 코어 수)가 I/O 대기 시간에 다른 요청을 처리하여 수만 개의 동시 요청을 처리할 수 있습니다.

**주의할 점:**

- Spring MVC는 Servlet 기반, WebFlux는 Servlet이 아님. "서블릿 요청"이 아니라 "HTTP 요청"이라고 표현할 것

### Q2. Mono와 Flux는 무엇이며, 차이는 무엇인가요?

**모범 답안:**

> Mono와 Flux는 리액티브 스트림의 Publisher이며, subscribe()되기 전까지 실행되지 않는 Lazy한 파이프라인입니다. Mono는 0개 또는 1개의 데이터를 비동기로 전달하고, Flux는 0개 이상 여러 개의 데이터를 비동기로 전달합니다.

### Q3. WebFlux에서 JDBC를 직접 사용하면 안 되는 이유는 무엇인가요?

**모범 답안:**

> JDBC는 Blocking I/O이기 때문입니다. WebFlux는 소수의 Event Loop 스레드(보통 CPU 코어 수)로 수만 개의 요청을 처리하는데, JDBC를 직접 호출하면 Event Loop 스레드가 DB 응답을 기다리며 멈춥니다. Event Loop 스레드가 4개뿐인데 전부 Blocking되면 서버 전체가 마비됩니다. 그래서 WebFlux에서는 R2DBC 같은 Non-blocking DB 드라이버를 사용해야 합니다.

**암기:** "Event Loop 소수 → 하나만 멈춰도 치명적 → R2DBC 사용"

### Q4. WebFlux가 적합한 상황과 Spring MVC가 적합한 상황을 각각 설명해주세요.

**모범 답안:**

> Spring MVC는 CRUD 중심의 일반적인 웹 서비스에 적합합니다. JPA/JDBC 생태계가 잘 갖춰져 있고, 명령형 코드 스타일이 팀원 대부분에게 익숙하며, 디버깅이 쉽기 때문입니다. WebFlux는 마이크로서비스 간 대량 비동기 통신이나 실시간 스트리밍(SSE, WebSocket)에 적합합니다. 여러 외부 서비스를 동시에 호출할 때 Non-blocking의 이점이 극대화되고, 소수의 스레드로 높은 동시성을 확보할 수 있기 때문입니다.

### Q5. Virtual Thread(Java 21)와 WebFlux의 차이를 설명해주세요.

**모범 답안:**

> 둘 다 높은 동시 처리 성능을 목표로 하지만 접근 방식이 다릅니다. Virtual Thread는 JVM이 관리하는 경량 스레드로, 1개당 수 KB만 차지하여 수백만 개를 생성할 수 있습니다. Blocking I/O가 발생하면 자동으로 양보하여 다른 Virtual Thread가 실행되므로, 기존 Spring MVC의 명령형 코드 스타일을 그대로 유지하면서 높은 동시성을 얻습니다. WebFlux는 Non-blocking I/O 기반으로 소수의 Event Loop 스레드가 대기 시간에 다른 요청을 처리하는 방식입니다. 리액티브 코드 스타일의 학습 곡선이 있지만, 실시간 스트리밍에는 WebFlux가 여전히 유리합니다.

**주의할 점:**

- Platform Thread(기존): OS 커널에 등록, 1개 ≈ 1MB → 수천 개 한계
- Virtual Thread: JVM이 관리, 1개 ≈ 수 KB → 수백만 개 가능
- 이 둘의 메모리 차이를 혼동하지 말 것
