---
title: Spring 깊이 이해하기 5편 - Reverse Proxy의 역할 — SSL, 로드밸런싱, 버퍼링
date: 2026-02-27 16:12:35 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : 프록시에 대해서 제대로 이해하기2.

## 📝 본문

## 1. SSL Termination — 암호화를 앞단에서 끝내기

HTTPS의 암호화/복호화를 Nginx에서 처리하고, 뒤로는 평문 HTTP로 통신하는 방식입니다. "Termination"은 "종료"라는 뜻으로, SSL 암호화를 Nginx에서 종료시킨다는 의미입니다.

```
[클라이언트] ──HTTPS──→ [Nginx: 여기서 암호 해제] ──HTTP──→ [Tomcat]
```

이렇게 하는 이유는 명확합니다. 암호화/복호화는 CPU를 많이 사용하는데, 이를 Tomcat이 직접 하면 비즈니스 로직 처리 성능이 떨어지기 때문입니다. 또한 SSL 인증서를 Nginx 한 곳에서만 관리하면 되어 운영이 편리합니다.

------



## 2. SSL 처리 — 3가지 구성 방식

SSL 처리 능력은 Nginx(Web Server)와 Tomcat(WAS) 둘 다 가지고 있습니다. 하지만 실무에서는 **한 곳에서만 처리**하는 것이 일반적입니다.

### ① SSL Termination (가장 일반적)

```
[클라이언트] ──HTTPS──→ [Nginx: SSL 종료] ──HTTP──→ [Tomcat]
```

Nginx에서 암호화를 풀고, 뒤로는 평문 HTTP로 전달합니다. 실무에서 80~90%는 이 방식을 사용합니다.

### ② SSL Passthrough (특수한 경우)

```
[클라이언트] ──HTTPS──→ [Nginx: 그대로 통과] ──HTTPS──→ [Tomcat: SSL 처리]
```

Nginx가 암호를 풀지 않고 암호화된 채로 그대로 넘깁니다. 금융권이나 의료 시스템처럼 중간자도 데이터를 볼 수 없어야 하는 **End-to-End Encryption** 요건이 있을 때 사용합니다.

### ③ SSL Bridging (이중 암호화)

```
[클라이언트] ──HTTPS──→ [Nginx: 복호화 후 재암호화] ──HTTPS──→ [Tomcat]
```

Nginx에서 한번 풀어서 내용을 확인(로깅, 필터링 등)한 다음, 다시 새로운 SSL로 암호화해서 Tomcat에 보냅니다. 성능 부담이 있어 드물게 사용됩니다.

### 비교 정리

|                     | Nginx에서 SSL 처리 | Tomcat에서 SSL 처리 | 사용 빈도 |
| ------------------- | ------------------ | ------------------- | --------- |
| **SSL Termination** | ✅ 여기서 끝냄      | ❌ 안 함             | 매우 높음 |
| **SSL Passthrough** | ❌ 안 건드림        | ✅ 여기서 처리       | 낮음      |
| **SSL Bridging**    | ✅ 풀고 다시 암호화 | ✅ 다시 처리         | 매우 낮음 |

### Nginx 없이 Tomcat만 쓸 때

Tomcat이 직접 SSL을 처리해야 합니다.

properties

```properties
server.port=8443
server.ssl.key-store=classpath:keystore.p12
server.ssl.key-store-password=changeit
server.ssl.key-store-type=PKCS12
```

개발 환경에서는 이렇게 해도 무방하지만, 운영 환경에서는 앞단에 Nginx나 ALB를 두는 것이 일반적입니다.

### 요즘 실무에서 가장 많이 보는 구성

최근에는 **AWS ALB에서 SSL Termination**하는 경우가 가장 흔합니다.

```
[클라이언트] ──HTTPS──→ [ALB: SSL 종료] ──HTTP──→ [Spring Boot / Tomcat]
```

AWS Certificate Manager(ACM)를 사용하면 무료 인증서 발급과 자동 갱신까지 지원되어 운영이 훨씬 편리합니다.

------



## 3. Load Balancing — 요청을 골고루 분산

들어오는 요청을 여러 서버에 골고루 분산하는 것입니다. 식당에 캐셔가 한 명인데 주방이 3개라면, 캐셔가 주문을 골고루 나눠보내는 것과 같습니다.

주요 전략은 다음과 같습니다.

- **Round Robin**: 서버를 돌아가며 순서대로 분배
- **Least Connections**: 현재 연결이 가장 적은 서버에 분배
- **IP Hash**: 같은 클라이언트 IP는 항상 같은 서버로 분배 (세션 유지에 유리)
- **Weighted**: 성능이 좋은 서버에 더 많은 요청을 분배

------



## 4. Connection Buffering — 느린 클라이언트로부터 Tomcat 보호

느린 클라이언트를 대신해서 Nginx가 응답을 임시 저장해주는 것입니다. 이 기능이 스레드 효율성에 큰 차이를 만듭니다.

Tomcat이 응답을 1초 만에 만들었는데, 클라이언트가 3G 네트워크라서 10초 동안 천천히 받아간다고 가정해 봅시다.

```
Buffering 없이: Tomcat Thread ████░░░░░░░░░░░░░░ (10초간 스레드 점유)
                                    ↑ 느린 클라이언트가 받아가는 동안 대기

Buffering 있으면: Tomcat Thread ████ (1초 만에 Nginx에게 넘기고 해방!)
                  Nginx Buffer      ████░░░░░░░░░░ (Nginx가 천천히 전달)
```

Tomcat 입장에서는 항상 빠른 로컬 네트워크(Nginx)와만 통신하니까 스레드 해방이 빨라집니다. 스레드 200개로 처리할 수 있는 요청량이 크게 달라지는 지점입니다.

------



## 5. Event-driven Architecture — Nginx의 작동 원리

Nginx가 이 많은 일을 소수의 프로세스로 처리할 수 있는 비결은 **Event-driven Architecture**에 있습니다. 스레드를 여러 개 쓰는 대신, 이벤트 루프 하나가 발생하는 이벤트들을 빠르게 전환하며 처리합니다.

```
Thread 모델 (Tomcat):
  Thread-1: [요청1 처리중............]
  Thread-2: [요청2 처리중............]
  → 스레드 수 = 동시 처리 수

Event-driven 모델 (Nginx):
  Event Loop: [요청1 일부][요청3 일부][요청2 일부][요청1 나머지]...
  → 1개 루프로 수천 개 동시 처리
```

Tomcat은 스레드 200개로 동시에 200개 요청을 처리하지만, Nginx는 이벤트 루프 하나로 수천 개의 동시 연결을 처리할 수 있습니다. Node.js나 Spring WebFlux(Netty 기반)도 같은 원리로 작동합니다.

------



## 핵심 키워드

| 키워드                        | 설명                                                         |
| ----------------------------- | ------------------------------------------------------------ |
| **SSL Termination**           | Nginx에서 SSL을 풀고 뒤로는 평문 HTTP로 통신하는 방식        |
| **SSL Passthrough**           | Nginx가 SSL을 건드리지 않고 그대로 백엔드에 전달하는 방식    |
| **SSL Bridging**              | Nginx에서 복호화 후 다시 암호화하여 전달하는 방식            |
| **End-to-End Encryption**     | 중간자도 데이터를 볼 수 없는 종단간 암호화                   |
| **ACM**                       | AWS Certificate Manager, 무료 SSL 인증서 발급 및 자동 갱신 서비스 |
| **Load Balancing**            | 요청을 여러 서버에 골고루 분산하는 것                        |
| **Round Robin**               | 서버를 순서대로 돌아가며 분배하는 로드밸런싱 전략            |
| **Least Connections**         | 연결이 가장 적은 서버에 분배하는 전략                        |
| **IP Hash**                   | 같은 IP를 항상 같은 서버로 분배하는 전략                     |
| **Connection Buffering**      | Nginx가 응답을 임시 저장해 느린 클라이언트를 대신 처리하는 것 |
| **Event-driven Architecture** | 이벤트 루프 기반으로 소수 스레드가 다수 연결을 처리하는 구조 |



## 🎯 면접 예상 질문

### Q1. SSL Termination이란 무엇이며, 왜 WAS가 아닌 앞단에서 SSL을 처리하나요?

**모범 답안:**

> SSL Termination은 HTTPS의 암복호화를 Nginx나 ALB 같은 앞단에서 처리하고, 이후 WAS까지는 평문 HTTP로 통신하는 방식입니다. WAS 앞단에서 처리하는 이유는 첫째, 암복호화가 CPU 집약적인 작업이라 WAS가 비즈니스 로직에 집중할 수 있고, 둘째, SSL 인증서를 한 곳에서만 관리하면 되어 운영이 편리하기 때문입니다.

### Q2. SSL Termination, SSL Passthrough, SSL Bridging의 차이를 설명해주세요.

**모범 답안:**

> **SSL Termination**은 Nginx에서 SSL을 풀고 뒤로는 평문 HTTP로 전달합니다. 가장 일반적인 방식이고, 대부분의 웹 서비스에서 사용합니다.
>
> **SSL Passthrough**는 Nginx가 SSL을 건드리지 않고 암호화된 채로 WAS에 전달합니다. 금융이나 의료 시스템처럼 중간자도 데이터를 볼 수 없어야 하는 End-to-End Encryption 요건이 있을 때 사용합니다.
>
> **SSL Bridging**은 Nginx에서 한번 복호화하여 내용을 확인한 뒤, 다시 새로운 SSL로 암호화하여 WAS에 전달합니다. 내부 구간까지 암호화하면서 중간에서 로깅이나 필터링도 해야 할 때 사용하지만, 성능 부담으로 드물게 쓰입니다.

**암기 팁:** "끝내기 / 통과시키기 / 다시 걸기"

### Q3. Nginx의 Event-driven 모델과 Tomcat의 Thread 모델의 차이를 설명해주세요.

**모범 답안:**

> Tomcat은 Thread 모델로, 요청 하나당 스레드 하나를 배정하여 I/O 대기 중에도 스레드가 점유됩니다. 동시 처리 수가 스레드 수에 제한됩니다. Nginx는 Event-driven 모델로, 이벤트 루프가 I/O 대기가 발생하면 다른 요청을 먼저 처리하고, 결과가 돌아오면 그때 이어서 처리합니다. 소수의 프로세스로 수천 개의 동시 연결을 처리할 수 있습니다. Spring WebFlux도 Netty 기반의 동일한 Event-driven 모델을 사용합니다.
