---
title: OSI 7계층, HTTP 버전, HTTPS/TLS, DNS
date: 2026-03-06 17:11:06 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web, network]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 네트워크 공부
- 목표 : 네트워크를 학습한다

## 📝 본문

## 1. OSI 7계층

네트워크 통신을 7단계로 나눈 표준 모델입니다. 4그룹으로 나누어 이해하면 됩니다.

```
[애플리케이션] 7. Application  (HTTP, DNS)        ← "무엇을 보내나"
              6. Presentation (암호화, 압축)
              5. Session      (세션 관리)
[전송]         4. Transport    (TCP, UDP)          ← "어떻게 보내나"
[네트워크]     3. Network      (IP, 라우팅)         ← "어디로 보내나"
[물리]         2. Data Link    (이더넷, MAC 주소)
              1. Physical     (전기 신호, 케이블)    ← "물리적으로 어떻게"
```

### 캡슐화 / 역캡슐화

보낼 때 각 계층을 지나며 헤더가 추가(캡슐화)되고, 받을 때는 역순으로 헤더를 벗겨냅니다(역캡슐화).

```
보낼 때: 데이터 → [TCP헤더+데이터] → [IP헤더+TCP+데이터] → [이더넷헤더+IP+TCP+데이터]
받을 때: [이더넷헤더 제거] → [IP헤더 제거] → [TCP헤더 제거] → 데이터
```

------



## 2. TCP 심화

### TCP Segment 핵심 필드

```
Sequence Number:       순서 번호 → 순서 보장의 핵심
Acknowledgment Number: "여기까지 받았어" → 신뢰성 보장의 핵심
Flags (SYN, ACK, FIN): 연결 수립/종료 제어
Window Size:           "내 버퍼 여유 공간" → Flow Control의 핵심
```

### TCP 상태 전이 — 실무에서 중요한 상태

**ESTABLISHED**: 정상 연결 상태. 데이터 송수신 가능. **TIME_WAIT**: 연결 종료 후 약 2분간 대기. 많으면 짧은 연결이 빈번하다는 의미 → Keep-Alive 활성화 검토. **CLOSE_WAIT**: 상대방이 FIN을 보냈는데 내가 FIN을 안 보낸 상태. 쌓이면 코드에서 socket.close()를 안 하는 버그.

bash

```bash
# 서버에서 TCP 상태 확인
netstat -an | grep 8080
```

------



## 3. HTTP 버전별 진화

### HTTP/1.0 — 매번 새 연결

요청마다 TCP 연결/종료를 반복. 매번 3-way Handshake 발생.

### HTTP/1.1 — Keep-Alive

하나의 TCP 연결을 여러 HTTP 요청에 재사용. 하지만 응답이 요청 순서대로 와야 하는 Head-of-Line(HOL) Blocking 문제 존재.

### HTTP/2.0 — 멀티플렉싱

하나의 TCP 연결에서 여러 요청/응답을 동시에 병렬 처리. 헤더 압축(HPACK), Server Push, 바이너리 프로토콜 지원. 하지만 TCP 레벨의 HOL Blocking은 여전히 존재.

```
HTTP/1.1: [요청1][응답1][요청2][응답2]  (순차)
HTTP/2.0: [요청1,요청2,요청3] → [응답2,응답3,응답1]  (병렬)
```

### HTTP/3.0 — QUIC (UDP 기반)

TCP 대신 UDP 기반의 QUIC 프로토콜 사용. 스트림별 독립 처리로 HOL Blocking 해결. 0-RTT 연결(이전 연결 정보 재활용), 연결 마이그레이션(WiFi→LTE 전환 시 연결 유지) 지원.

|                  | HTTP/1.0     | HTTP/1.1   | HTTP/2.0      | HTTP/3.0   |
| ---------------- | ------------ | ---------- | ------------- | ---------- |
| **연결**         | 매번 새 연결 | Keep-Alive | 멀티플렉싱    | QUIC (UDP) |
| **전송**         | 텍스트       | 텍스트     | 바이너리      | 바이너리   |
| **HOL Blocking** | 있음         | 있음       | TCP 레벨 있음 | 해결됨     |
| **프로토콜**     | TCP          | TCP        | TCP           | UDP (QUIC) |

------



## 4. HTTPS / TLS

### HTTPS = HTTP + TLS

HTTP 평문을 TLS로 암호화하여 전송합니다. TCP 3-way Handshake 이후에 TLS Handshake가 진행됩니다.

### TLS Handshake 과정

```
[TCP 3-way Handshake 완료]
    ↓
① Client Hello: 클라이언트가 지원 가능한 암호화 방식 목록 전달
② Server Hello + 인증서: 서버가 암호화 방식 선택 + SSL 인증서 전달
③ 인증서 검증: 클라이언트가 CA(인증기관)를 통해 인증서가 진짜인지 확인
④ 대칭키 교환: 비대칭키 방식으로 대칭키를 안전하게 교환
⑤ 암호화 통신 시작: 이후 모든 데이터는 대칭키로 암호화
```

### 대칭키 + 비대칭키 조합

```
비대칭키 (RSA): 안전하지만 느림 → ④에서 대칭키를 안전하게 교환하는 데 사용
대칭키 (AES):   빠르지만 키 공유가 문제 → ⑤부터 실제 데이터 암복호화에 사용
→ 비대칭키의 안전한 키 교환 + 대칭키의 빠른 암복호화 = 두 장점 조합
```

### Nginx SSL Termination과의 연결

앞서 배운 Reverse Proxy의 SSL Termination이 바로 이 TLS Handshake와 암복호화를 Nginx가 대신 처리하는 것입니다.

------



## 5. DNS 심화

도메인 이름(example.com)을 IP 주소(93.184.216.34)로 변환하는 시스템입니다.

### DNS 조회 과정

```
① 브라우저 캐시 확인
② OS 캐시 확인
③ 로컬 DNS 서버에 질의
④ Root DNS → "com 관리자 알려줌"
⑤ TLD DNS (.com) → "example.com 관리자 알려줌"
⑥ Authoritative DNS → "IP는 93.184.216.34!"
⑦ 결과를 캐시에 저장 (TTL 시간만큼)
```

### DNS가 UDP를 사용하는 이유

DNS 질의/응답은 매우 짧은 데이터입니다. TCP는 9번의 패킷(3-way + 질의 + 응답 + 4-way)이 필요하지만, UDP는 2번(질의 + 응답)이면 충분합니다. 응답이 512바이트를 초과하면 TCP로 전환합니다.

------



## 6. 네트워크 실무 디버깅

### Connection Timeout vs Read Timeout

**Connection Timeout**: TCP 3-way Handshake가 완료되지 않을 때. 서버가 꺼져있거나 방화벽이 막은 경우. "서버에 연결 자체가 안 됨"

**Read Timeout**: 연결은 됐는데 응답이 안 올 때. DB 조회가 느리거나 외부 API가 오래 걸리는 경우. "연결은 됐는데 응답을 기다리다 포기"

### Connection Refused vs Connection Timeout

**Connection Refused**: 서버에 도달했지만 해당 포트에서 Listen하는 프로세스가 없음. **Connection Timeout**: 서버에 도달 자체가 안 됨. IP가 틀렸거나 네트워크 단절.

### 디버깅 명령어

bash

```bash
telnet example.com 8080      # 포트 열려있는지 확인
netstat -an | grep 8080      # TCP 연결 상태 확인
nslookup example.com         # DNS 조회 확인
traceroute example.com       # 네트워크 경로 추적
curl -v http://example.com   # HTTP 요청 테스트
```

------



## 7. 전체 연결 — 브라우저에서 서버까지

```
① DNS 조회 (UDP) → IP 확인
② TCP 3-way Handshake → 연결 수립
③ TLS Handshake → 암호화 준비
④ HTTP 요청 전송 (암호화)
⑤ Nginx가 SSL 복호화 (SSL Termination) → Tomcat에 HTTP 전달
⑥ Tomcat: Acceptor → Poller → Worker → DispatcherServlet → Controller → Service → Repository → DB
⑦ 응답 역순 → Nginx가 SSL 암호화 → 클라이언트
⑧ Keep-Alive로 연결 유지 또는 4-way Handshake로 종료
```

------

## 핵심 키워드

| 카테고리         | 키워드                                                       |
| ---------------- | ------------------------------------------------------------ |
| **OSI 7계층**    | Application(7), Transport(4), Network(3), 캡슐화/역캡슐화    |
| **TCP 심화**     | Sequence Number, ACK, Segment, 상태 전이, TIME_WAIT, CLOSE_WAIT |
| **HTTP 버전**    | 1.0(매번 연결), 1.1(Keep-Alive), 2.0(멀티플렉싱), 3.0(QUIC/UDP) |
| **HOL Blocking** | HTTP/1.1(응답 순서 대기), HTTP/2.0(TCP 레벨), HTTP/3.0(해결) |
| **HTTPS/TLS**    | TLS Handshake, 대칭키+비대칭키, CA 인증서, SSL Termination   |
| **DNS**          | UDP 53번, Root→TLD→Authoritative, 캐시, TTL                  |
| **실무**         | Connection Timeout, Read Timeout, Connection Refused, netstat |



## 🎯 면접 예상 질문

### Q1. OSI 7계층을 간단히 설명해주세요.

**모범 답안:**

> OSI 7계층은 네트워크 통신을 7단계로 나눈 표준 모델입니다. 크게 4그룹으로 나눌 수 있습니다. 애플리케이션(7,6,5계층)은 HTTP, DNS 등 "무엇을 보내나"를, 전송(4계층)은 TCP, UDP 등 "어떻게 보내나"를, 네트워크(3계층)는 IP, 라우팅 등 "어디로 보내나"를, 물리(2,1계층)는 이더넷, WiFi 등 물리적 전송을 다룹니다. HTTP는 7계층(Application), TCP는 4계층(Transport)에서 동작합니다.

### Q2. HTTP/1.1, HTTP/2.0, HTTP/3.0의 차이를 설명해주세요.

**모범 답안:**

> HTTP/1.1에서 Keep-Alive가 도입되어 하나의 연결을 재사용할 수 있게 되었지만, 응답이 요청 순서대로 와야 하는 HOL Blocking 문제가 있었습니다. HTTP/2.0에서는 멀티플렉싱으로 하나의 TCP 연결에서 여러 요청/응답을 병렬 처리할 수 있게 되었지만, TCP 레벨의 HOL Blocking은 여전히 존재했습니다. HTTP/3.0은 TCP 대신 UDP 기반의 QUIC 프로토콜을 사용하여, 스트림별로 독립 처리되므로 HOL Blocking이 완전히 해결되었습니다.

**주의할 점:**

- HTTP/1.1 = Keep-Alive, HTTP/2.0 = 멀티플렉싱. 이 매핑을 혼동하지 말 것

### Q3. HTTPS는 어떻게 동작하며, TLS Handshake를 설명해주세요.

**모범 답안:**

> HTTPS는 HTTP에 TLS 암호화를 더한 것입니다. TCP 3-way Handshake 이후 TLS Handshake가 진행됩니다. 클라이언트가 Client Hello로 지원 가능한 암호화 방식을 알리면, 서버가 Server Hello + 인증서로 응답합니다. 클라이언트가 인증서를 CA를 통해 검증한 후, 비대칭키 방식으로 대칭키를 안전하게 교환합니다. 이후 모든 통신은 교환된 대칭키로 암호화됩니다. 비대칭키의 안전한 키 교환과 대칭키의 빠른 암복호화, 두 장점을 조합한 방식입니다.

### Q4. DNS는 왜 UDP를 사용하나요?

**모범 답안:**

> DNS 질의/응답은 매우 짧은 데이터이기 때문입니다. TCP를 쓰면 3-way Handshake + 질의 + 응답 + 4-way Handshake로 9번의 패킷이 필요하지만, UDP를 쓰면 질의 + 응답 2번이면 충분합니다. 다만 응답이 512바이트를 초과하면 TCP로 전환합니다.

### Q5. Connection Timeout과 Read Timeout의 차이는 무엇인가요?

**모범 답안:**

> Connection Timeout은 TCP 3-way Handshake가 일정 시간 내에 완료되지 않을 때 발생합니다. 서버가 꺼져있거나 방화벽이 막은 경우입니다. Read Timeout은 연결은 성공했지만 서버의 응답이 일정 시간 내에 오지 않을 때 발생합니다. DB 조회가 느리거나 외부 API 호출이 오래 걸리는 경우입니다. 쉽게 말하면 Connection Timeout은 "서버에 연결 자체가 안 됨", Read Timeout은 "연결은 됐는데 응답을 기다리다 포기"입니다.
