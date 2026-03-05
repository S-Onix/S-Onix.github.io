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

```
① DNS 조회: "example.com의 IP가 뭐야?" → 93.184.216.34
② TCP 연결: 93.184.216.34의 80번 포트에 연결 요청 (3-way handshake)
③ HTTP 요청: 연결된 통로(Socket)를 통해 "GET /orders HTTP/1.1" 전송
④ HTTP 응답: 서버가 "200 OK + 데이터" 반환
⑤ TCP 종료: 연결 해제 (4-way handshake)
```

------



## 2. Socket — 네트워크 통신의 끝점

네트워크에서 두 프로그램이 데이터를 주고받기 위한 통신 끝점(endpoint)입니다. OS 커널이 제공하는 네트워크 기능을 애플리케이션에서 사용할 수 있게 추상화한 API입니다.

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

서버 포트가 8080 하나여도, 클라이언트마다 출발 IP와 포트가 다르므로 **수만 개의 동시 연결**이 가능합니다. 실제 한계는 서버의 메모리, 파일 디스크립터 수, Thread/EventLoop 처리 능력에 의해 결정됩니다.

### 서버 Socket vs 클라이언트 Socket

```java
// 서버 측: 포트에서 대기하다가 연결 수락
ServerSocket serverSocket = new ServerSocket(8080);
Socket clientSocket = serverSocket.accept();  // Tomcat Acceptor가 하는 일

// 클라이언트 측: 서버에 연결 요청
Socket socket = new Socket("93.184.216.34", 8080);
```

### 가장 원시적인 HTTP 서버

```java
ServerSocket serverSocket = new ServerSocket(8080);
while (true) {
    Socket client = serverSocket.accept();
    
    BufferedReader reader = new BufferedReader(
        new InputStreamReader(client.getInputStream()));
    String requestLine = reader.readLine();  // "GET /orders HTTP/1.1"
    
    OutputStream output = client.getOutputStream();
    output.write("HTTP/1.1 200 OK\r\n\r\nHello World".getBytes());
    
    client.close();
}
```

Tomcat은 이것을 Thread Pool, NIO Selector 등으로 고도화한 것이고, Netty는 EventLoop로 고도화한 것입니다.

------



## 3. Port (포트)

하나의 IP 주소에서 여러 프로그램을 구분하기 위한 번호 (0~65535)입니다. IP 주소가 건물 주소라면, 포트는 호실 번호입니다.

```
잘 알려진 포트 (0~1023):
  80 → HTTP, 443 → HTTPS, 22 → SSH, 3306 → MySQL, 6379 → Redis

등록된 포트 (1024~49151):
  8080 → Tomcat 기본, 3000 → Node.js 기본

동적 포트 (49152~65535):
  클라이언트가 임시로 사용
```

------



## 4. TCP — 신뢰할 수 있는 연결 기반 프로토콜

데이터가 순서대로, 빠짐없이, 정확하게 전달되는 것을 보장하는 연결 기반 프로토콜입니다.

### TCP의 3가지 보장

**순서 보장**: 각 패킷에 Sequence Number가 붙어서, 뒤섞여 도착해도 원래 순서로 복원 **신뢰성 보장**: 받는 쪽이 ACK(확인 응답)를 보내고, ACK가 안 오면 재전송 **무결성 보장**: 체크섬으로 데이터 손상을 감지하고, 손상 시 재전송



### 3-way Handshake — 연결 수립

```
클라이언트 → SYN ("연결해도 될까?")         → 서버
클라이언트 ← SYN+ACK ("그래, 나도 준비됐어") ← 서버
클라이언트 → ACK ("알겠어, 시작하자!")        → 서버
→ 연결 수립 완료!
```

3번인 이유: 2번만 하면 서버가 "클라이언트가 내 응답을 실제로 받았는지" 확인할 수 없습니다. 3번째 ACK로 양쪽 모두 상대방의 수신 능력을 검증합니다.

Tomcat의 Acceptor가 accept()를 호출하면, OS 커널이 처리한 3-way Handshake가 완료된 연결을 꺼내옵니다. Tomcat의 `accept-count` 설정이 이 완료된 연결의 대기열 크기입니다.



### 4-way Handshake — 연결 종료

```
클라이언트 → FIN ("나 끊을게")     → 서버
클라이언트 ← ACK ("알겠어")       ← 서버
          (서버가 남은 데이터 전송...)
클라이언트 ← FIN ("나도 끊을게")   ← 서버
클라이언트 → ACK ("알겠어, 안녕!")  → 서버
→ 연결 종료 완료!
```

4번인 이유: ②와 ③ 사이에 서버가 아직 보낼 데이터가 남아있을 수 있어서 분리됩니다.

마지막 ACK 이후 클라이언트는 TIME_WAIT 상태로 약 2분간 대기합니다. 마지막 ACK가 유실되었을 때 서버의 FIN 재전송에 응답하기 위해서입니다.



### Flow Control (흐름 제어)

수신 측이 처리할 수 있는 속도만큼만 송신 측의 전송 속도를 제어합니다. TCP 헤더의 Window Size 필드로 수신 측이 "내 버퍼에 이만큼 여유가 있어"라고 알려줍니다.

```
TCP:       Window Size로 "이만큼만 보내"
Reactive:  request(n)으로 "n개만 줘"
→ 둘 다 소비자가 생산 속도를 제어하는 같은 원리!
```



### Congestion Control (혼잡 제어)

네트워크 자체가 혼잡할 때 전체적인 전송 속도를 줄입니다. Slow Start로 천천히 시작하여 점점 속도를 올리고, 패킷 유실(혼잡 신호) 감지 시 속도를 확 줄입니다.

```
Flow Control:      수신자가 "나 느려, 천천히 보내" (수신 측 능력)
Congestion Control: 네트워크가 "길이 막혀, 다들 천천히" (네트워크 상태)
```



### Keep-Alive (HTTP/1.1)

하나의 TCP 연결을 여러 HTTP 요청에 재사용합니다. 매번 3-way/4-way Handshake를 하지 않아 효율적입니다.

```
Keep-Alive 없이: 요청마다 TCP 연결/종료 반복
Keep-Alive 있으면: TCP 연결 1번 → 요청1/응답1 → 요청2/응답2 → ... → TCP 종료
```

------



## 5. UDP — 빠르지만 보장 없는 비연결 프로토콜

연결 없이 데이터를 빠르게 전송하지만, 순서/도착/무결성을 보장하지 않는 프로토콜입니다.

|               | TCP                         | UDP                        |
| ------------- | --------------------------- | -------------------------- |
| **연결**      | 연결 기반 (3-way handshake) | 비연결 (보내고 끝)         |
| **순서 보장** | ✅                           | ❌                          |
| **신뢰성**    | ✅ (재전송)                  | ❌ (유실 가능)              |
| **속도**      | 상대적으로 느림             | 빠름 (오버헤드 적음)       |
| **헤더 크기** | 20바이트                    | 8바이트                    |
| **용도**      | HTTP, FTP, 이메일, 채팅     | 실시간 스트리밍, DNS, 게임 |



### UDP를 쓰는 이유

TCP의 신뢰성 보장(handshake, 재전송, 순서 정렬)에는 비용이 있습니다. 실시간성이 신뢰성보다 중요한 경우 UDP를 씁니다.

```
영상 통화:
  TCP: 패킷 유실 → 재전송 대기 → 딜레이 → 대화 끊김
  UDP: 패킷 유실 → 무시 → 약간 깨지지만 대화는 계속

온라인 게임:
  TCP: 패킷 유실 → 재전송 대기 → 캐릭터 멈춤
  UDP: 패킷 유실 → 최신 위치만 반영 → 게임은 계속
```



### Java에서 UDP 통신

```java
// UDP 서버 — 연결 과정 없이 바로 receive
DatagramSocket serverSocket = new DatagramSocket(9090);
byte[] buffer = new byte[1024];
DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
serverSocket.receive(packet);

// UDP 클라이언트 — 연결 과정 없이 바로 send
DatagramSocket clientSocket = new DatagramSocket();
byte[] data = "Hello".getBytes();
DatagramPacket packet = new DatagramPacket(
    data, data.length, InetAddress.getByName("localhost"), 9090);
clientSocket.send(packet);
```

------



## 6. Socket, TCP, UDP의 관계

```
Socket = 네트워크 통신의 끝점 (API)
TCP/UDP = 통신 방식 (프로토콜)

TCP Socket:  new Socket() / new ServerSocket()       → 연결 기반
UDP Socket:  new DatagramSocket()                     → 비연결
```

------



## 7. 서버 구현 방식의 진화

```
싱글 스레드     → 한 번에 1명만
멀티 스레드     → 연결마다 스레드 생성 (스레드 폭증)
Thread Pool    → 스레드 수 제한, 재사용 (Tomcat BIO)
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
```

------



## 핵심 키워드

| 카테고리     | 키워드                                                       |
| ------------ | ------------------------------------------------------------ |
| **Socket**   | 통신 끝점, IP:Port, 4-tuple, ServerSocket, DatagramSocket    |
| **Port**     | Well-known Port(80, 443), 동적 포트, 호실 번호               |
| **TCP**      | 연결 기반, 순서 보장, 신뢰성, Sequence Number, ACK           |
| **TCP 연결** | 3-way Handshake(SYN/SYN+ACK/ACK), 4-way Handshake(FIN/ACK)   |
| **TCP 제어** | Flow Control(Window Size), Congestion Control(Slow Start)    |
| **UDP**      | 비연결, 빠름, 순서/신뢰성 없음, 헤더 8바이트                 |
| **HTTP**     | Keep-Alive, TIME_WAIT                                        |
| **연결**     | Backpressure ≈ Flow Control, accept-count = Handshake 대기열 |

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
