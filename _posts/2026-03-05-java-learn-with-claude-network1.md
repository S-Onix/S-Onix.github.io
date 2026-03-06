---
title: Socket, TCP, UDP — 서버는 어떻게 구현되는가
date: 2026-03-05 17:11:06 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web, network]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 네트워크 공부
- 목표 : 네트워크의 기본 요소인 socket, tcp, udp를 학습한다

## 📝 본문

## 1. 큰 그림: 요청이 서버에 도달하는 과정

브라우저에서 `http://example.com/orders`를 입력하면 내부적으로 이런 일이 벌어집니다.

```
① DNS 조회: "example.com의 IP가 뭐야?" → 93.184.216.34
② TCP 연결: 93.184.216.34의 80번 포트에 연결 요청 (3-way handshake)
③ HTTP 요청: 연결된 통로(Socket)를 통해 "GET /orders HTTP/1.1" 전송
④ HTTP 응답: 서버가 "200 OK + 데이터" 반환
⑤ TCP 종료: 연결 해제 (4-way handshake)
```

Tomcat의 Acceptor, Poller, Worker는 ②~④ 과정을 처리하는 것입니다. 이제 그 밑바닥인 Socket, TCP, UDP를 다룹니다.

------



## 2. Socket — 네트워크 통신의 끝점

네트워크에서 두 프로그램이 데이터를 주고받기 위한 **통신 끝점(endpoint)**입니다. OS 커널이 제공하는 네트워크 기능을 애플리케이션에서 사용할 수 있게 추상화한 API입니다.

비유하면 **우체통**입니다. 편지를 쓰면(데이터) 우체통(Socket)에 넣고, 우체국(OS 커널)이 배달(전송)해줍니다.

```
애플리케이션 (Java 코드)
    ↓ Socket API 호출
OS 커널 (TCP/IP 스택)
    ↓ 실제 네트워크 패킷 생성/전송
네트워크 카드 (NIC)
    ↓ 전기 신호로 변환
네트워크 케이블/무선
```

### Socket의 식별: 4-tuple

하나의 TCP 연결은 4가지 조합으로 유일하게 식별됩니다.

```
(출발 IP, 출발 Port, 도착 IP, 도착 Port)

(192.168.1.100, 54321, 93.184.216.34, 8080) → 연결 A
(192.168.1.100, 54322, 93.184.216.34, 8080) → 연결 B (포트가 다름)
(192.168.1.101, 54321, 93.184.216.34, 8080) → 연결 C (IP가 다름)
```

이 때문에 서버 포트가 8080 하나여도 **수만 개의 동시 연결**이 가능합니다. 클라이언트마다 출발 포트가 다르니까요.

```
클라이언트A (54321) → 서버(8080)  → 연결 1
클라이언트A (54322) → 서버(8080)  → 연결 2 (같은 클라이언트, 다른 포트)
클라이언트B (54321) → 서버(8080)  → 연결 3 (다른 클라이언트)
→ 서버 포트는 8080 하나인데 3개의 연결이 동시에 존재!
```

실제 동시 연결 한계는 서버의 메모리, 파일 디스크립터 수, Thread/EventLoop 처리 능력에 의해 결정됩니다.

### 서버 Socket vs 클라이언트 Socket

```java
// 서버 측: 포트에서 대기하다가 연결 수락
ServerSocket serverSocket = new ServerSocket(8080);  // 포트 바인딩
Socket clientSocket = serverSocket.accept();          // 연결 수락 → Tomcat Acceptor가 하는 일

// 클라이언트 측: 서버에 연결 요청
Socket socket = new Socket("93.184.216.34", 8080);   // 서버에 연결 요청
```

### 가장 원시적인 HTTP 서버

```java
// Tomcat, Netty의 원시 형태
ServerSocket serverSocket = new ServerSocket(8080);
System.out.println("서버 시작! 8080 포트에서 대기 중...");

while (true) {
    // 클라이언트 연결 대기 (Blocking!)
    Socket clientSocket = serverSocket.accept();

    // 연결된 소켓에서 데이터 읽기
    InputStream input = clientSocket.getInputStream();
    BufferedReader reader = new BufferedReader(new InputStreamReader(input));
    String requestLine = reader.readLine();   // "GET /orders HTTP/1.1"

    // 응답 보내기
    OutputStream output = clientSocket.getOutputStream();
    output.write("HTTP/1.1 200 OK\r\n\r\nHello World".getBytes());

    clientSocket.close();
}
```

Tomcat은 이것을 Thread Pool, NIO Selector 등으로 고도화한 것이고, Netty는 EventLoop로 고도화한 것입니다.

------



## 3. Port (포트)

하나의 IP 주소에서 여러 프로그램을 구분하기 위한 번호 (0~65535)입니다. IP 주소가 **건물 주소**라면, 포트는 **호실 번호**입니다.

```
93.184.216.34:80    → 이 서버의 80번 방 (웹 서버)
93.184.216.34:443   → 이 서버의 443번 방 (HTTPS 서버)
93.184.216.34:3306  → 이 서버의 3306번 방 (MySQL)
93.184.216.34:8080  → 이 서버의 8080번 방 (Tomcat)
```

### 포트 분류

```
0~1023      잘 알려진 포트 (시스템 예약)
              80 → HTTP, 443 → HTTPS, 22 → SSH
              3306 → MySQL, 5432 → PostgreSQL
              6379 → Redis, 27017 → MongoDB

1024~49151  등록된 포트 (애플리케이션용)
              8080 → Tomcat 기본, 3000 → Node.js 기본

49152~65535 동적 포트 (클라이언트가 임시로 사용)
```

------



## 4. TCP — 신뢰할 수 있는 연결 기반 프로토콜

데이터가 **순서대로, 빠짐없이, 정확하게** 전달되는 것을 보장하는 연결 기반 프로토콜입니다. 비유하면 **등기 우편**입니다. 보낸 순서대로 도착하고, 분실되면 재전송하고, 수신 확인을 받습니다.

### TCP의 3가지 보장

**① 순서 보장 (Ordering)**

각 패킷에 Sequence Number가 붙어서, 뒤섞여 도착해도 원래 순서로 복원합니다.

```
보내는 쪽: 패킷1(seq=1), 패킷2(seq=2), 패킷3(seq=3)

네트워크에서 뒤섞여 도착:
  패킷3(seq=3) 도착
  패킷1(seq=1) 도착
  패킷2(seq=2) 도착

TCP가 순서 번호(seq)를 보고 재정렬:
  패킷1 → 패킷2 → 패킷3  (보낸 순서대로 애플리케이션에 전달!)
```

**② 신뢰성 보장 (Reliability)**

받는 쪽이 패킷을 받으면 ACK(확인 응답)를 보냅니다. ACK가 일정 시간 안에 오지 않으면 재전송합니다.

```
보내는 쪽: 패킷1 전송 → 패킷2 전송 → 패킷3 전송
받는 쪽:   패킷1 ACK!  → (패킷2 유실!) → 패킷3 ACK!

보내는 쪽: "패킷2의 ACK가 안 왔네? 재전송!"
          패킷2 재전송 →
받는 쪽:   패킷2 ACK!
→ 모든 데이터가 빠짐없이 도착!
```

**③ 무결성 보장 (Integrity)**

체크섬으로 데이터 손상을 감지하고, 손상 시 재전송합니다.

```
보내는 쪽: 데이터 + 체크섬 전송
받는 쪽:   데이터로 체크섬 재계산 → 전송된 체크섬과 비교
           일치 → 정상!
           불일치 → 손상됨! → 재전송 요청
```

### TCP Segment 구조

TCP가 전송하는 데이터 단위를 Segment라고 합니다.

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          Source Port          |       Destination Port        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Sequence Number                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Acknowledgment Number                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Data |       |U|A|P|R|S|F|                                   |
| Offset| Rsrvd |R|C|S|S|Y|I|          Window Size              |
|       |       |G|K|H|T|N|N|                                   |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|           Checksum            |         Urgent Pointer        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Options (가변 길이)                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                         Data (Payload)                        |
|                       (실제 전송 데이터)                        |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

면접에서 중요한 필드:

```
Source Port / Destination Port  출발/도착 포트 → Socket 식별
Sequence Number                 이 세그먼트의 순서 번호 → 순서 보장의 핵심
Acknowledgment Number           "여기까지 받았어" → 신뢰성 보장의 핵심
Flags (SYN, ACK, FIN, RST)     연결 수립/종료 제어
Window Size                     "내 버퍼 여유 공간" → Flow Control의 핵심
Checksum                        데이터 무결성 검증
```

### Packet (패킷) 구조

큰 데이터를 작은 조각(패킷)으로 나눠서 보내고, 받는 쪽에서 다시 합칩니다.

```
┌──────────────┬──────────────┬──────────────────┐
│   IP 헤더     │   TCP 헤더    │      데이터       │
│  (20바이트)   │  (20바이트)   │   (가변 길이)      │
├──────────────┼──────────────┼──────────────────┤
│ 출발/도착 IP  │ 출발/도착 Port │  실제 전송할 내용   │
│ TTL 등       │ Seq, Ack 번호 │                   │
│              │ Window Size  │                   │
└──────────────┴──────────────┴──────────────────┘
원본 데이터: "안녕하세요 반갑습니다 좋은 하루 되세요"

패킷으로 분할:
  패킷1 (seq=1): "안녕하세요 "
  패킷2 (seq=2): "반갑습니다 "
  패킷3 (seq=3): "좋은 하루 되세요"

네트워크 전송 (순서가 뒤바뀔 수 있음):
  패킷3 → 패킷1 → 패킷2

수신 측에서 seq 순서대로 재조립:
  패킷1 + 패킷2 + 패킷3 = "안녕하세요 반갑습니다 좋은 하루 되세요"
```

### 3-way Handshake — 연결 수립

TCP 연결을 맺는 과정입니다. Tomcat의 Acceptor가 `accept()`를 호출하면 이 과정이 완료됩니다.

```
클라이언트                          서버
    │                               │
    │  ① SYN (연결해도 될까?)         │
    │  seq=100                       │
    │──────────────────────────────→│
    │                               │
    │  ② SYN+ACK (그래, 나도 준비됐어) │
    │  seq=300, ack=101              │
    │←──────────────────────────────│
    │                               │
    │  ③ ACK (알겠어, 시작하자!)       │
    │  ack=301                       │
    │──────────────────────────────→│
    │                               │
    │       연결 수립 완료! 🤝         │
```

비유하면 전화 통화입니다.

```
① "여보세요?" (SYN)
② "네, 여보세요!" (SYN + ACK)
③ "잘 들려요, 시작합시다" (ACK)
```

**왜 2번이 아니라 3번인가?** 2번만 하면 서버가 "클라이언트가 내 응답을 실제로 받았는지" 확인할 수 없습니다. 3번째 ACK로 양쪽 모두 상대방의 수신 능력을 검증합니다.

**Tomcat과의 연결**: OS 커널이 3-way Handshake를 처리하고, 완료된 연결을 큐에 넣습니다. Acceptor가 `accept()`를 호출하면 큐에서 완료된 연결을 꺼냅니다. Tomcat의 `accept-count` 설정이 이 큐의 크기입니다.

### 4-way Handshake — 연결 종료

```
클라이언트                          서버
    │                               │
    │  ① FIN (나 끊을게)              │
    │──────────────────────────────→│
    │                               │
    │  ② ACK (알겠어)                │
    │←──────────────────────────────│
    │                               │
    │   (서버가 남은 데이터 마저 전송)    │
    │                               │
    │  ③ FIN (나도 끊을게)            │
    │←──────────────────────────────│
    │                               │
    │  ④ ACK (알겠어, 안녕!)          │
    │──────────────────────────────→│
    │                               │
    │       연결 종료 완료! 👋         │
```

**왜 3번이 아니라 4번인가?** ②와 ③ 사이에 서버가 아직 보낼 데이터가 남아있을 수 있어서, ACK와 FIN이 분리됩니다.

### TIME_WAIT 상태

클라이언트가 마지막 ④ ACK를 보낸 후, 바로 소켓을 닫지 않고 **약 2분간 대기**합니다.

```
이유: ④ ACK가 유실되면 서버가 ③ FIN을 재전송합니다.
      클라이언트 소켓이 이미 닫혀있으면 응답할 수 없으므로,
      TIME_WAIT 동안 대기하여 재전송된 FIN에 응답할 수 있게 합니다.
```

### TCP 상태 전이 — 실무에서 중요한 상태들

```
[연결 수립]
  서버: CLOSED → LISTEN → SYN_RECEIVED → ESTABLISHED
  클라이언트: CLOSED → SYN_SENT → ESTABLISHED

[연결 종료]
  능동 종료 측: ESTABLISHED → FIN_WAIT_1 → FIN_WAIT_2 → TIME_WAIT → CLOSED
  수동 종료 측: ESTABLISHED → CLOSE_WAIT → LAST_ACK → CLOSED
```

실무에서 주의할 상태:

```
ESTABLISHED: 정상 연결 상태. 데이터 송수신 가능.

TIME_WAIT:   연결 종료 후 약 2분간 대기.
             많으면 짧은 연결이 빈번하다는 의미.
             → HTTP Keep-Alive 활성화 또는 Connection Pool 사용 검토

CLOSE_WAIT:  상대방이 FIN을 보냈는데 내가 아직 FIN을 안 보낸 상태.
             쌓이면 코드에서 socket.close()를 안 하는 버그!
             → try-with-resources 또는 finally에서 close() 확인
```

bash

```bash
# 서버에서 TCP 상태 확인
$ netstat -an | grep 8080
tcp  0  0  0.0.0.0:8080       0.0.0.0:*          LISTEN
tcp  0  0  서버:8080           클라이언트A:54321   ESTABLISHED
tcp  0  0  서버:8080           클라이언트B:54322   TIME_WAIT
tcp  0  0  서버:8080           클라이언트C:54323   CLOSE_WAIT    ← 버그 가능성!
```

### Flow Control (흐름 제어)

수신 측이 처리할 수 있는 속도만큼만 송신 측의 전송 속도를 제어합니다. TCP 헤더의 **Window Size** 필드를 사용합니다.

```
수신 측: "Window Size = 64KB" (64KB까지 받을 수 있어)
송신 측: 64KB 전송
수신 측: 32KB 처리 완료 → "Window Size = 32KB" (32KB만 여유)
송신 측: 32KB만 전송
수신 측: 버퍼 가득 참 → "Window Size = 0" (잠깐 멈춰!)
송신 측: 전송 중단, 대기
수신 측: 처리 완료 → "Window Size = 64KB" (다시 보내도 돼!)
```

이것이 WebFlux의 **Backpressure와 같은 원리**입니다.

```
TCP:       Window Size로 "이만큼만 보내"
Reactive:  request(n)으로 "n개만 줘"
→ 둘 다 소비자가 생산 속도를 제어!
```

### Congestion Control (혼잡 제어)

네트워크 자체가 혼잡할 때 전체적인 전송 속도를 줄입니다.

```
Flow Control:      수신자가 "나 느려, 천천히 보내" (수신 측 능력)
Congestion Control: 네트워크가 "길이 막혀, 다들 천천히" (네트워크 상태)
```

**Slow Start**: TCP 연결 시작 시 네트워크 상태를 모르므로 천천히 시작하여 점점 속도를 올립니다.

```
전송량:  1 → 2 → 4 → 8 → 16 → 32 → ...  (지수적 증가)

패킷 유실 감지! (네트워크 혼잡 신호)
  → 전송량을 확 줄임
  → 다시 천천히 증가

이것을 반복하여 최적의 전송 속도를 찾음
```

### Keep-Alive (HTTP/1.1)

하나의 TCP 연결을 여러 HTTP 요청에 재사용합니다.

```
Keep-Alive 없이 (HTTP/1.0):
  요청1: TCP 연결 → HTTP 요청/응답 → TCP 종료
  요청2: TCP 연결 → HTTP 요청/응답 → TCP 종료  (매번 3-way handshake!)
  요청3: TCP 연결 → HTTP 요청/응답 → TCP 종료

Keep-Alive 있으면 (HTTP/1.1 기본):
  TCP 연결 → 요청1/응답1 → 요청2/응답2 → 요청3/응답3 → TCP 종료
  (3-way handshake 1번이면 충분!)
```

Tomcat의 `connection-timeout` 설정이 Keep-Alive 연결을 얼마나 유지할지 결정합니다.

------



## 5. UDP — 빠르지만 보장 없는 비연결 프로토콜

연결 없이 데이터를 **빠르게 전송**하지만, 순서/도착/무결성을 **보장하지 않는** 프로토콜입니다. 비유하면 **일반 우편(엽서)**입니다. 보내고 끝. 도착 확인 없고, 순서 보장 없습니다.

### TCP vs UDP 비교

```
TCP (등기 우편):
  ① 연결 수립 (3-way handshake)
  ② 데이터 전송 (순서 보장, 유실 시 재전송)
  ③ 연결 종료 (4-way handshake)
  → 느리지만 신뢰성 높음

UDP (엽서):
  ① 그냥 보냄 (연결 과정 없음)
  → 빠르지만 신뢰성 없음
```

|               | TCP                         | UDP                        |
| ------------- | --------------------------- | -------------------------- |
| **연결**      | 연결 기반 (3-way handshake) | 비연결 (보내고 끝)         |
| **순서 보장** | ✅                           | ❌                          |
| **신뢰성**    | ✅ (재전송)                  | ❌ (유실 가능)              |
| **속도**      | 상대적으로 느림             | 빠름 (오버헤드 적음)       |
| **헤더 크기** | 20바이트                    | 8바이트                    |
| **용도**      | HTTP, FTP, 이메일, 채팅     | 실시간 스트리밍, DNS, 게임 |

### 왜 UDP를 쓰는가?

TCP의 신뢰성 보장(handshake, 재전송, 순서 정렬)에는 비용이 있습니다. 실시간성이 신뢰성보다 중요한 경우 UDP를 씁니다.

```
영상 통화 중:
  TCP: 패킷 유실 → 재전송 대기 → 0.5초 딜레이 → 대화가 끊김
  UDP: 패킷 유실 → 무시하고 다음 프레임 표시 → 약간 깨지지만 대화는 계속

온라인 게임:
  TCP: 패킷 유실 → 재전송 대기 → 캐릭터가 0.5초 멈춤
  UDP: 패킷 유실 → 최신 위치만 반영 → 약간 워프되지만 게임은 계속
```

### UDP 사용 사례

```
실시간 스트리밍:  영상 통화 (Zoom, Google Meet), 라이브 방송
온라인 게임:      위치 동기화, 액션 전달
DNS:             도메인 → IP 조회 (작은 데이터, 빠른 응답 필요)
IoT 센서:        온도, 습도 데이터 전송 (일부 유실되어도 괜찮음)
```

### Java에서 UDP 통신

```java
// UDP 서버 — 연결 과정 없이 바로 receive
DatagramSocket serverSocket = new DatagramSocket(9090);
byte[] buffer = new byte[1024];
DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
serverSocket.receive(packet);  // 데이터 수신 (연결 과정 없이!)
String message = new String(packet.getData(), 0, packet.getLength());

// UDP 클라이언트 — 연결 과정 없이 바로 send
DatagramSocket clientSocket = new DatagramSocket();
byte[] data = "Hello".getBytes();
DatagramPacket packet = new DatagramPacket(
    data, data.length, InetAddress.getByName("localhost"), 9090);
clientSocket.send(packet);  // 그냥 보냄! 연결 수립 없이!
```

TCP와 달리 `accept()`, `connect()` 같은 연결 과정이 없습니다.

------



## 6. Socket, TCP, UDP의 관계

```
Socket = 네트워크 통신의 끝점 (API)
TCP/UDP = 통신 방식 (프로토콜)

Socket은 TCP로도, UDP로도 사용 가능합니다.

TCP Socket:  new Socket()         / new ServerSocket()     → 연결 기반
UDP Socket:  new DatagramSocket() / new DatagramSocket()   → 비연결
```

비유하면, Socket은 **전화기**이고, TCP는 **일반 통화**(연결 후 대화), UDP는 **무전기**(그냥 말하고 끝)입니다.

------



## 7. 서버 구현 방식의 진화

### Stage 1: 싱글 스레드 서버

```java
ServerSocket serverSocket = new ServerSocket(8080);
while (true) {
    Socket client = serverSocket.accept();
    handleRequest(client);                   // 이 동안 다른 연결 못 받음!
    client.close();
}
```

문제: 한 번에 하나의 클라이언트만 처리 가능

### Stage 2: 멀티 스레드 서버 (Thread-per-Connection)

```java
ServerSocket serverSocket = new ServerSocket(8080);
while (true) {
    Socket client = serverSocket.accept();
    new Thread(() -> {                       // 연결마다 새 스레드 생성
        handleRequest(client);
        client.close();
    }).start();
}
```

문제: 연결마다 스레드 생성 → 스레드 폭증 → 메모리 부족

### Stage 3: Thread Pool 서버 (Tomcat BIO 방식)

```java
ServerSocket serverSocket = new ServerSocket(8080);
ExecutorService pool = Executors.newFixedThreadPool(200);
while (true) {
    Socket client = serverSocket.accept();
    pool.submit(() -> {                      // Thread Pool에서 스레드 배정
        handleRequest(client);
        client.close();
    });
}
```

개선: 스레드 수 제한, 재사용 문제: 200개 스레드가 전부 I/O 대기하면 추가 요청 처리 불가

### Stage 4: NIO Selector 서버 (Tomcat NIO 방식)

```java
Selector selector = Selector.open();
ServerSocketChannel serverChannel = ServerSocketChannel.open();
serverChannel.bind(new InetSocketAddress(8080));
serverChannel.configureBlocking(false);
serverChannel.register(selector, SelectionKey.OP_ACCEPT);

while (true) {
    selector.select();                       // 이벤트 대기 (효율적!)
    Set<SelectionKey> keys = selector.selectedKeys();
    for (SelectionKey key : keys) {
        if (key.isAcceptable()) {
            SocketChannel client = serverChannel.accept();
            client.configureBlocking(false);
            client.register(selector, SelectionKey.OP_READ);
        }
        if (key.isReadable()) {
            SocketChannel client = (SocketChannel) key.channel();
            ByteBuffer buffer = ByteBuffer.allocate(1024);
            client.read(buffer);
            // 처리 로직...
        }
    }
}
```

개선: 하나의 스레드로 수천 개 연결 감시 문제: 코드가 복잡, 직접 구현 어려움

### Stage 5: Netty (Event Loop 프레임워크)

```java
EventLoopGroup bossGroup = new NioEventLoopGroup(1);
EventLoopGroup workerGroup = new NioEventLoopGroup();

ServerBootstrap bootstrap = new ServerBootstrap();
bootstrap.group(bossGroup, workerGroup)
    .channel(NioServerSocketChannel.class)
    .childHandler(new ChannelInitializer<SocketChannel>() {
        @Override
        protected void initChannel(SocketChannel ch) {
            ch.pipeline()
                .addLast(new HttpServerCodec())
                .addLast(new MyBusinessHandler());
        }
    });

bootstrap.bind(8080).sync();
```

개선: NIO의 복잡함을 추상화, Pipeline으로 깔끔한 처리

### 진화 정리

```
싱글 스레드     → 한 번에 1명만 (1:1)
멀티 스레드     → 연결마다 스레드 (스레드 폭증)
Thread Pool    → 스레드 수 제한 (Tomcat BIO)
NIO Selector   → 하나의 스레드로 다수 감시 (Tomcat NIO)
Netty          → NIO를 프레임워크로 추상화 (Event Loop + Pipeline)
```

------



## 8. 앞서 배운 내용과의 연결

```
Socket        → Tomcat/Netty가 내부적으로 사용하는 네트워크 통신 끝점
TCP           → HTTP가 사용하는 프로토콜 (3-way handshake = Acceptor의 accept())
UDP           → DNS 조회, 실시간 스트리밍에서 사용
NIO Selector  → Tomcat Poller와 Netty EventLoop의 핵심 기술
Flow Control  → TCP의 Window Size = Backpressure의 네트워크 버전
Keep-Alive    → TCP 연결 재사용 = Tomcat connection-timeout 설정
accept-count  → 3-way Handshake 완료된 연결의 대기열 크기
TIME_WAIT     → HTTP Keep-Alive로 줄일 수 있음
```

------



## 핵심 키워드

| 카테고리        | 키워드                                                       |
| --------------- | ------------------------------------------------------------ |
| **Socket**      | 통신 끝점, IP:Port, 4-tuple, ServerSocket, DatagramSocket    |
| **Port**        | Well-known Port(80, 443), 동적 포트, 호실 번호               |
| **TCP**         | 연결 기반, 순서 보장, 신뢰성, Sequence Number, ACK           |
| **TCP Segment** | Source/Dest Port, Seq, Ack, Flags, Window Size, Checksum     |
| **TCP 연결**    | 3-way Handshake(SYN/SYN+ACK/ACK), 4-way Handshake(FIN/ACK)   |
| **TCP 상태**    | ESTABLISHED, TIME_WAIT, CLOSE_WAIT, LISTEN                   |
| **TCP 제어**    | Flow Control(Window Size), Congestion Control(Slow Start)    |
| **UDP**         | 비연결, 빠름, 순서/신뢰성 없음, 헤더 8바이트                 |
| **HTTP**        | Keep-Alive, TIME_WAIT, Connection Pool                       |
| **연결**        | Backpressure ≈ Flow Control, accept-count = Handshake 대기열 |
| **서버 진화**   | 싱글 → 멀티 → Thread Pool → NIO Selector → Netty             |



## 🎯 면접 예상 질문

### Q1. Socket이란 무엇인가요?

**모범 답안:**

> Socket은 네트워크에서 두 프로그램이 데이터를 주고받기 위한 통신 끝점(endpoint)입니다. OS 커널이 제공하는 네트워크 기능을 애플리케이션에서 사용할 수 있게 추상화한 API이며, IP 주소 + 포트 번호의 조합으로 식별됩니다. 하나의 TCP 연결은 (출발 IP, 출발 Port, 도착 IP, 도착 Port) 4가지 조합으로 유일하게 식별됩니다.

**암기:** "통신 끝점 + IP:Port + 4-tuple"

### Q2. TCP의 3-way Handshake를 설명해주세요. 왜 2번이 아니라 3번인가요?

**모범 답안:**

> TCP 3-way Handshake는 연결 수립을 위해 3번 패킷을 주고받는 과정입니다. 클라이언트가 SYN을 보내 연결을 요청하고, 서버가 SYN+ACK로 수락 응답을 보내고, 클라이언트가 ACK를 보내 연결이 완료됩니다. 2번이 아니라 3번인 이유는, 2번만 하면 서버가 "클라이언트가 내 응답을 실제로 받았는지" 확인할 수 없기 때문입니다. 3번째 ACK로 양쪽 모두 상대방의 수신 능력을 검증할 수 있습니다.

**암기:** "SYN → SYN+ACK → ACK, 3번인 이유: 양쪽 수신 능력 검증"

### Q3. TCP와 UDP의 차이를 설명하고, 각각 언제 사용하나요?

**모범 답안:**

> TCP는 데이터가 순서대로, 빠짐없이, 정확하게 전달되는 것을 보장하는 연결 기반 프로토콜입니다. 3-way Handshake로 연결을 수립하고, 유실 시 재전송합니다. HTTP, 채팅 등 데이터 유실이 허용되지 않는 환경에서 사용합니다. UDP는 연결 과정 없이 데이터를 바로 전송하는 비연결 프로토콜입니다. 순서 보장과 재전송이 없어 오버헤드가 적고 빠릅니다. 영상 스트리밍, 온라인 게임, DNS처럼 실시간성이 신뢰성보다 중요한 환경에서 사용합니다.

### Q4. TCP의 Flow Control이란 무엇이며, 리액티브에서 비슷한 개념은?

**모범 답안:**

> TCP의 Flow Control은 수신 측이 처리할 수 있는 속도만큼만 송신 측의 전송 속도를 제어하는 메커니즘입니다. TCP 헤더의 Window Size 필드로 수신 측이 "내 버퍼에 이만큼 여유가 있어"라고 알려줍니다. 리액티브의 Backpressure와 같은 원리입니다. TCP에서는 Window Size로 "이만큼만 보내", Reactive에서는 request(n)으로 "n개만 줘"라고 제어합니다. 둘 다 소비자가 생산 속도를 제어합니다.

**암기:** "TCP = Window Size, Reactive = request(n), 둘 다 소비자가 속도 제어"

### Q5. 서버 소켓의 포트가 8080 하나인데, 어떻게 수만 개의 동시 연결이 가능한가요?

**모범 답안:**

> TCP 연결은 포트 번호 하나로 식별되는 것이 아니라, (출발 IP, 출발 Port, 도착 IP, 도착 Port) 4가지 조합으로 유일하게 식별됩니다. 서버 포트가 8080 하나여도 클라이언트마다 출발 IP와 출발 Port가 다르기 때문에 각각 다른 연결로 인식됩니다. 이론적으로 수만~수십만 개의 동시 연결이 가능하며, 실제 한계는 서버의 메모리, 파일 디스크립터 수, Thread/EventLoop 처리 능력에 의해 결정됩니다.

**암기:** "4-tuple(출발IP, 출발Port, 도착IP, 도착Port)로 식별 → 포트 하나로 수만 연결 가능"
