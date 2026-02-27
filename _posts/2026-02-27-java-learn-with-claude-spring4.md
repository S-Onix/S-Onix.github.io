---
title: Spring 깊이 이해하기 4편 - Proxy... Forward Proxy와 Reverse Proxy
date: 2026-02-27 16:12:35 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : 프록시에 대해서 제대로 이해하기.

## 📝 본문

## 1. Proxy란?

Proxy는 영어로 **"대리인"**이라는 뜻입니다. 네트워크에서 Proxy는 클라이언트와 서버 사이에 위치하여, 요청과 응답을 대신 전달해주는 중간 서버입니다.

```
Proxy 없이:   [나] ────────────→ [서버]     직접 통신
Proxy 있으면: [나] → [Proxy] → [서버]       Proxy가 대신 전달
```

직접 통신하면 될 것을 왜 중간에 끼워넣을까요? 중간에 위치하기 때문에 가능한 일들이 생기기 때문입니다. 캐싱, 필터링, 로드밸런싱, IP 은닉 등이 그것입니다.

------



## 2. Forward Proxy — 클라이언트의 대리인

Forward Proxy는 **클라이언트 쪽에 서서**, 클라이언트를 대신해 외부 서버에 요청을 보냅니다. 외부 서버 입장에서는 Proxy의 IP만 보이고, 실제 클라이언트가 누구인지 알 수 없습니다.

```
[회사 직원 A] ─┐
[회사 직원 B] ─┼→ [Forward Proxy] ──→ [외부 서버]
[회사 직원 C] ─┘
                   ↑ 외부 서버는 Proxy의 IP만 봄
```

비유하면 비서와 같습니다. 내가 비서에게 "이 편지 저 회사에 보내줘"라고 하면, 받는 쪽은 비서가 보낸 건지 내가 보낸 건지 알 수 없습니다.

실제 사용 사례는 다음과 같습니다.

- **회사/학교 네트워크**: 직원들의 인터넷 접속을 모니터링하거나 특정 사이트를 차단
- **VPN**: 클라이언트의 IP를 숨기고 다른 나라 IP로 접속 (넓은 의미의 Forward Proxy)
- **캐싱**: 직원 100명이 같은 페이지를 보면, Proxy가 한 번만 가져와서 캐싱해두고 나머지에게는 캐시된 응답을 전달

------



## 3. Reverse Proxy — 서버의 대리인

Reverse Proxy는 **서버 쪽에 서서**, 클라이언트의 요청을 대신 받아줍니다. 클라이언트는 Reverse Proxy의 주소만 알고, 뒤에 실제 서버가 몇 대인지, 어디에 있는지 알 수 없습니다.

```
[클라이언트들] ──→ [Reverse Proxy (Nginx)] ──→ [서버 1]
                                           ──→ [서버 2]
                                           ──→ [서버 3]
```

비유하면 호텔 프론트 데스크와 같습니다. 손님은 프론트에만 말하면 되고, 뒤에서 어떤 직원이 방 청소하고 룸서비스를 만드는지 알 필요가 없습니다.

### 의도된 효과와 부수 효과

Reverse Proxy의 **본래 목적은 클라이언트가 서버의 존재를 모르게 하는 것**입니다. 그런데 구조적으로 중간에 Proxy가 끼어들면서, **서버도 클라이언트의 진짜 IP를 직접 알 수 없게 되는 부수 효과**가 발생합니다. 이는 의도한 것이 아니라 구조상 자연스럽게 생기는 현상입니다.

```
[클라이언트 123.456.789.0]
        ↓
[Nginx 10.0.0.1]          ← 클라이언트는 Nginx만 봄 (의도된 효과)
        ↓
[Spring Boot]              ← request.getRemoteAddr() = "10.0.0.1" (부수 효과)
```

------



## 4. Forward Proxy vs Reverse Proxy 비교

|                 | Forward Proxy                      | Reverse Proxy                      |
| --------------- | ---------------------------------- | ---------------------------------- |
| **누구 편?**    | 클라이언트 편                      | 서버 편                            |
| **의도된 효과** | 서버가 클라이언트를 모름           | 클라이언트가 서버를 모름           |
| **부수 효과**   | 클라이언트도 직접 통신 경로를 모름 | 서버도 클라이언트의 진짜 IP를 모름 |
| **설치 위치**   | 클라이언트 네트워크 쪽             | 서버 네트워크 쪽                   |
| **대표 예시**   | 회사 프록시, VPN, Squid            | Nginx, HAProxy, AWS ALB            |

공통점은 둘 다 "중간에 끼어서 대신 전달"해주는 것이 동일하다는 점입니다. 차이는 누구 편에 서 있느냐입니다.

------



## 5. X-Forwarded-For — 클라이언트 원본 정보 전달

Reverse Proxy를 거치면 서버가 클라이언트의 진짜 IP를 알 수 없게 됩니다. 이를 해결하기 위해 Nginx가 **X-Forwarded-For** 헤더에 원래 클라이언트 정보를 기록해줍니다. 이는 Proxy가 일부러 메모를 남겨주는 것이지, Proxy를 안 거쳤을 때처럼 자연스럽게 아는 것이 아닙니다.

nginx

```nginx
# Nginx 설정
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;   # 원래 HTTP인지 HTTPS인지
proxy_set_header X-Forwarded-Host $host;      # 원래 호스트명
```

properties

```properties
# Spring Boot 설정 — 이 헤더들을 신뢰하겠다고 명시
server.forward-headers-strategy=native
```

이 설정이 없으면 로그에 찍히는 IP가 전부 Nginx IP이고, HTTPS인데 Spring이 HTTP로 인식하는 등의 문제가 발생합니다.

------



## 6. 코드에서도 쓰이는 Proxy 패턴

"대신해준다"는 개념은 네트워크만의 것이 아닙니다. Spring AOP가 바로 **Proxy 패턴**으로 동작합니다.

java

```java
@Transactional
public void createOrder() {
    // 이 메서드를 직접 호출하는 게 아니라,
    // Spring이 만든 Proxy 객체가 대신 받아서
    // 트랜잭션 시작 → 원래 메서드 실행 → 커밋/롤백을 해줌
}
호출자 → [Proxy 객체] → 트랜잭션 시작 → [진짜 OrderService.createOrder()] → 트랜잭션 커밋
         ↑ Spring이 자동 생성한 대리인
```

이 내용은 AOP 편에서 더 깊이 다룹니다.

------



## 핵심 키워드

| 키워드                       | 설명                                                        |
| ---------------------------- | ----------------------------------------------------------- |
| **Proxy**                    | 클라이언트와 서버 사이에서 요청/응답을 대신 전달하는 중간자 |
| **Forward Proxy**            | 클라이언트 쪽에 서서 클라이언트를 대리하는 프록시           |
| **Reverse Proxy**            | 서버 쪽에 서서 서버를 대리하는 프록시                       |
| **X-Forwarded-For**          | 원래 클라이언트 IP를 전달하는 HTTP 헤더                     |
| **X-Forwarded-Proto**        | 원래 프로토콜(HTTP/HTTPS)을 전달하는 헤더                   |
| **X-Forwarded-Host**         | 원래 호스트명을 전달하는 헤더                               |
| **forward-headers-strategy** | Spring Boot에서 프록시 헤더를 신뢰하도록 설정하는 옵션      |



## 🎯 면접 예상 질문

### Q1. Forward Proxy와 Reverse Proxy의 차이를 설명해주세요.

**모범 답안:**

> Forward Proxy는 클라이언트 쪽에 위치하여 클라이언트를 대리합니다. 서버는 Proxy의 IP만 보이므로 실제 클라이언트가 누구인지 알 수 없습니다. 회사 프록시나 VPN이 대표적입니다. Reverse Proxy는 서버 쪽에 위치하여 서버를 대리합니다. 클라이언트는 Reverse Proxy의 주소만 알고, 뒤에 실제 서버가 몇 대인지, 어떤 구조인지 알 수 없습니다. Nginx가 대표적입니다.

### Q2. Reverse Proxy를 사용할 때, Spring Boot에서 클라이언트의 실제 IP를 얻으려면 어떻게 해야 하나요?

**모범 답안:**

> Reverse Proxy를 거치면 `request.getRemoteAddr()`에 Nginx의 IP가 찍힙니다. 클라이언트의 실제 IP를 얻으려면 Nginx에서 `X-Forwarded-For` 헤더에 원본 IP를 기록하도록 설정하고, Spring Boot에서 `server.forward-headers-strategy=native`로 해당 헤더를 신뢰하도록 설정해야 합니다.

### Q3. 실무에서 Nginx를 Reverse Proxy로 두는 이유를 3가지 이상 설명해주세요.

**모범 답안:**

> 첫째, **SSL Termination**입니다. HTTPS 암복호화를 Nginx가 처리하여 Tomcat의 CPU 부담을 줄입니다. 둘째, **Load Balancing**입니다. 여러 대의 WAS에 요청을 분산하여 부하를 나눕니다. 셋째, **Connection Buffering**입니다. 느린 클라이언트의 응답 전달을 Nginx가 대신하여, Tomcat 스레드가 빠르게 해방됩니다. 넷째, **정적 파일 서빙**입니다. JS, CSS, 이미지 같은 정적 리소스를 Nginx가 직접 처리하여 WAS까지 요청이 가지 않게 합니다.

**암기 팁:** "SSL, 분산, 버퍼, 정적" 네 단어로 기억
