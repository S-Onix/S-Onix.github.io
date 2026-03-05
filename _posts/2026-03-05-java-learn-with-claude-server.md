---
title: Tomcat, Netty 내부구조 및 Backpressure
date: 2026-03-05 17:11:06 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web, server]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 이용한 WAS 학습
- 목표 : Tomcat, Netty에 대한 이해

## 📝 본문

## 1. Tomcat 전체 아키텍처

Tomcat은 단순히 "Servlet Container"가 아니라, 내부에 여러 계층 구조를 가지고 있습니다.

```
┌─────────────────────────────────────────────────────┐
│  Server (Tomcat 인스턴스 전체)                         │
│  ┌───────────────────────────────────────────────┐  │
│  │  Service                                       │  │
│  │  ┌─────────────┐  ┌───────────────────────┐   │  │
│  │  │  Connector   │  │      Engine            │   │  │
│  │  │  (HTTP/AJP)  │  │  ┌─────────────────┐  │   │  │
│  │  │              │  │  │     Host          │  │   │  │
│  │  │  - 포트 리스닝 │→│  │  (가상 호스트)     │  │   │  │
│  │  │  - 프로토콜   │  │  │  ┌─────────────┐│  │   │  │
│  │  │    파싱      │  │  │  │   Context    ││  │   │  │
│  │  │  - Thread    │  │  │  │ (웹 애플리케이션)│  │   │  │
│  │  │    Pool 관리  │  │  │  │  ┌────────┐││  │   │  │
│  │  │              │  │  │  │  │Servlet │││  │   │  │
│  │  └─────────────┘  │  │  │  └────────┘││  │   │  │
│  │                    │  │  └─────────────┘│  │   │  │
│  │                    │  └─────────────────┘  │   │  │
│  │                    └───────────────────────┘   │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```



### 각 컴포넌트의 역할

**Server**: Tomcat 인스턴스 전체를 대표합니다. JVM 하나당 하나의 Server가 존재합니다.

**Service**: Connector와 Engine을 묶어주는 단위입니다. 보통 하나만 사용합니다.

**Connector**: 외부 요청을 받아들이는 입구입니다. 포트를 리스닝하고, HTTP 프로토콜을 파싱하며, Thread Pool을 관리합니다.

```
클라이언트 → [Connector (8080 포트)] → 프로토콜 파싱 → Thread Pool에서 스레드 배정
```

Connector에는 두 가지 종류가 있습니다.

```
HTTP Connector (기본): 클라이언트 → Tomcat 직접 연결
AJP Connector:         Apache HTTP Server → Tomcat 연결 (레거시)
```

**Engine**: 요청을 실제로 처리하는 엔진입니다. 어떤 Host로 보낼지 결정합니다.

**Host**: 가상 호스트입니다. 하나의 Tomcat에서 여러 도메인을 서비스할 수 있습니다.

```
api.example.com  → Host A → Context A
www.example.com  → Host B → Context B
```

**Context**: 하나의 웹 애플리케이션을 의미합니다. Spring Boot에서는 보통 하나의 Context만 사용합니다.

**Servlet**: 실제 요청을 처리하는 Java 클래스입니다. Spring MVC에서는 DispatcherServlet이 이 역할을 합니다.

------



## 2. Connector 내부 — 요청이 들어오는 과정

Connector 안에서 요청이 처리되는 과정을 더 깊이 파보면 세 가지 핵심 컴포넌트가 있습니다.

```
클라이언트 요청
    ↓
┌─ Connector ──────────────────────────────────┐
│                                              │
│  ① Acceptor Thread                           │
│     소켓 연결을 수락 (accept)                   │
│     ↓                                        │
│  ② Poller Thread (NIO)                       │
│     소켓에서 데이터가 준비되었는지 감시            │
│     데이터 준비되면 Thread Pool에 전달           │
│     ↓                                        │
│  ③ Worker Thread (Thread Pool)               │
│     실제 요청을 처리 (Servlet 실행)             │
│                                              │
└──────────────────────────────────────────────┘
```

### ① Acceptor Thread

클라이언트의 TCP 연결 요청을 수락(accept)하는 전담 스레드입니다. 보통 1~2개만 있습니다.

비유하면 호텔 현관의 **도어맨**입니다. 손님이 오면 문을 열어주고(연결 수락), 프론트 데스크(Poller)에 안내합니다. 도어맨은 절대 체크인 업무를 직접 하지 않습니다.

```
Acceptor가 하는 일:
  ① 소켓에서 accept() 호출 → TCP 3-way handshake 완료
  ② 수락된 연결(소켓)을 Poller에 등록
  ③ 다시 accept() 대기

Acceptor가 하지 않는 일:
  ❌ HTTP 파싱
  ❌ 비즈니스 로직 실행
  ❌ 응답 전송
```

### ② Poller Thread (NIO)

수락된 소켓 연결들을 감시하다가, 데이터가 준비된 연결만 Worker Thread에 넘기는 스레드입니다.

비유하면 레스토랑의 **웨이터 매니저**입니다. 테이블 100개를 돌아다니면서 "이 테이블 주문 준비됐나?"를 체크하고, 준비된 테이블만 요리사(Worker)에게 알려줍니다.

내부적으로 Java NIO의 `Selector`를 사용합니다.

```java
// Poller의 동작 원리 (개념적 코드)
Selector selector = Selector.open();

// 수천 개의 소켓을 Selector에 등록
socketChannel.register(selector, SelectionKey.OP_READ);

while (true) {
    selector.select();  // 데이터가 준비된 소켓이 있을 때까지 대기 (효율적!)
    
    Set<SelectionKey> readyKeys = selector.selectedKeys();
    for (SelectionKey key : readyKeys) {
        // 데이터가 준비된 소켓만 Worker Thread에 전달
        threadPool.submit(() -> processRequest(key.channel()));
    }
}
```

핵심은 `selector.select()` 입니다. 이 한 줄로 수천 개의 소켓을 동시에 감시할 수 있습니다. 하나씩 체크하는 것이 아니라, OS 커널이 "이 소켓들 중에 준비된 거 있어?"라고 한번에 확인해줍니다.

```
BIO 방식 (구버전):
  소켓 1번 확인... 없음
  소켓 2번 확인... 없음
  소켓 3번 확인... 있다!
  → 하나씩 확인하니까 느림

NIO Selector 방식 (현재):
  "소켓 1~1000번 중 준비된 거 알려줘" → OS가 "3번, 7번, 42번!" 
  → 한번에 확인하니까 빠름
```

### ③ Worker Thread (Thread Pool)

실제 HTTP 요청을 파싱하고 Servlet을 실행하는 스레드입니다. `server.tomcat.threads.max=200`으로 설정하는 것이 바로 이 Worker Thread의 수입니다.

### BIO vs NIO

Tomcat 8.5 이전에는 BIO(Blocking I/O) Connector가 기본이었고, 8.5부터 NIO(Non-blocking I/O) Connector가 기본입니다.

```
BIO (구버전):
  Acceptor가 연결 수락 → 즉시 Worker Thread 배정
  → 데이터가 아직 안 왔어도 스레드가 점유됨
  → 느린 클라이언트에 스레드가 낭비됨

NIO (현재 기본):
  Acceptor가 연결 수락 → Poller가 감시
  → 데이터가 준비되면 그때 Worker Thread 배정
  → 느린 클라이언트에 스레드가 낭비되지 않음
```

중요한 점은, **Tomcat NIO는 Connector 레벨에서만 Non-blocking**이라는 것입니다. Worker Thread가 Servlet을 실행하는 시점부터는 여전히 Blocking입니다. 이것이 Netty의 완전한 Non-blocking과의 차이입니다.

```
Tomcat NIO:   연결 수락/감시는 Non-blocking + Servlet 실행은 Blocking
Netty:        전체가 Non-blocking
```

------



## 3. Tomcat Thread Pool 설정 심화

```yaml
server:
  tomcat:
    threads:
      max: 200           # Worker Thread 최대 수 (기본 200)
      min-spare: 10      # 최소 유지 스레드 수 (기본 10)
    max-connections: 8192 # 동시 연결 수 (Poller가 감시하는 소켓 수)
    accept-count: 100    # max-connections 초과 시 대기열 크기
    connection-timeout: 20000  # 연결 타임아웃 (ms)
```

요청 흐름을 이 설정으로 따라가보면:

```
① 요청 도착 (동시 연결이 8192 이하)
   → Acceptor가 연결 수락
   → Poller에 등록

② 동시 연결이 8192 초과
   → accept-count(100)만큼 OS 레벨 대기열에서 대기
   → 대기열도 가득 차면 → Connection Refused

③ 데이터 준비됨 → Worker Thread 배정
   → Worker Thread 200개 모두 사용 중이면?
   → 요청이 큐에서 대기 (Worker가 반환될 때까지)

④ Worker Thread에서 Servlet 실행
   → DB 조회 (Blocking I/O) → 스레드 대기
   → 응답 반환 → Worker Thread를 Pool에 반환
```

### 실무 튜닝 포인트

**max-connections(8192) > threads.max(200) 인 이유**: NIO Poller가 연결을 효율적으로 감시하므로, 실제로 데이터가 준비된 요청만 Worker Thread에 넘깁니다. 8192개 연결 중 동시에 처리가 필요한 것은 일부뿐입니다.

**threads.max를 무작정 늘리면 안 되는 이유**: 스레드가 많아지면 컨텍스트 스위칭 비용이 증가하고, 메모리도 늘어납니다(스레드당 약 1MB). CPU 코어 수, I/O 대기 비율, 메모리를 고려해서 결정해야 합니다.

------



## 4. Netty 전체 아키텍처

```
┌───────────────────────────────────────────────────────┐
│  Netty                                                │
│                                                       │
│  ┌──────────────────┐                                 │
│  │  Boss Group      │  ← 연결 수락 담당 (1개 스레드)      │
│  │  (EventLoopGroup)│                                 │
│  └────────┬─────────┘                                 │
│           ↓ 수락된 연결을 Worker에게 전달                 │
│  ┌──────────────────┐                                 │
│  │  Worker Group    │  ← 실제 I/O 처리 (CPU 코어 수)     │
│  │  (EventLoopGroup)│                                 │
│  │  ┌────────────┐  │                                 │
│  │  │ EventLoop-1│──→ Channel A, Channel D, Channel G │
│  │  │ EventLoop-2│──→ Channel B, Channel E, Channel H │
│  │  │ EventLoop-3│──→ Channel C, Channel F            │
│  │  │ EventLoop-4│──→ Channel I, Channel J            │
│  │  └────────────┘  │                                 │
│  └──────────────────┘                                 │
│                                                       │
│  ┌──────────────────────────────────────────┐         │
│  │  Channel Pipeline                        │         │
│  │  [Handler1] → [Handler2] → [Handler3]    │         │
│  │  (디코더)     (비즈니스)    (인코더)         │         │
│  └──────────────────────────────────────────┘         │
└───────────────────────────────────────────────────────┘
```

### 핵심 컴포넌트 상세

**Boss Group**: 클라이언트의 연결 요청을 수락하는 역할입니다. Tomcat의 Acceptor Thread와 비슷합니다. 보통 스레드 1개입니다.

**Worker Group**: 수락된 연결에서 실제 데이터를 읽고 쓰는 역할입니다. 보통 CPU 코어 수만큼 EventLoop 스레드를 가집니다.

**EventLoop**: Worker Group의 스레드 하나가 곧 EventLoop 하나입니다. 하나의 EventLoop가 여러 Channel을 담당합니다.

```
EventLoop-1이 담당하는 Channel들:
  Channel A: 클라이언트 1의 연결
  Channel D: 클라이언트 4의 연결
  Channel G: 클라이언트 7의 연결
  
  → 하나의 스레드가 3개 연결을 번갈아 처리
  → Channel A가 I/O 대기 중이면 Channel D를 처리
```

**Channel**: 하나의 네트워크 연결(소켓)을 추상화한 것입니다. 클라이언트 하나당 Channel 하나가 생깁니다.

**중요한 규칙**: 하나의 Channel은 항상 같은 EventLoop에서 처리됩니다. Channel A가 EventLoop-1에 배정되면 끝날 때까지 EventLoop-1이 담당합니다. 이 덕분에 동기화(synchronized)가 필요 없어 성능이 좋습니다.

### EventLoop의 무한 루프

```
EventLoop 하나의 동작:
while (true) {
    ① I/O 이벤트 감지 (Selector.select)
       → Channel A에 데이터 도착!
    
    ② 해당 Channel의 Pipeline 실행
       → [디코더] → [비즈니스 Handler] → [인코더]
    
    ③ 예약된 작업(Task) 실행
       → 타이머 작업, 지연 작업 등
    
    → 다시 ①로 돌아감
}
```

비유하면 카페 바리스타가 주문 확인 → 커피 제조 → 서빙을 한 사람이 빙글빙글 돌면서 하는 것입니다. 커피가 추출되는 동안(I/O 대기) 다른 주문을 처리합니다.

### EventLoop의 황금 규칙: "절대 Blocking 하지 마라"

EventLoop 스레드 안에서 Blocking 작업을 하면 그 EventLoop가 담당하는 모든 Channel이 멈춥니다.

```
EventLoop-1이 Channel A, B, C를 담당하는데...
  Channel A 처리 중 Thread.sleep(5000) 호출!
  → Channel B, C도 5초간 처리 불가!
```

------



## 5. Channel Pipeline — 요청 처리 파이프라인

Channel Pipeline은 하나의 요청이 여러 Handler를 순서대로 거치는 처리 체인입니다.

### 왜 Pipeline으로 나누는가?

한 곳에서 전부 처리하면 코드가 뒤섞입니다.

```java
// 🚫 하나의 Handler에서 전부 처리
public class EverythingHandler {
    public void handle(byte[] rawData) {
        // 바이트를 메시지로 변환하고
        // HTTP로 파싱하고
        // 비즈니스 로직 처리하고
        // 다시 HTTP로 만들고
        // 바이트로 변환해서 전송
    }
}
```

Pipeline으로 나누면 각 Handler가 자기 역할만 합니다.

```java
// ✅ 각 Handler가 자기 역할만 담당
ch.pipeline()
    .addLast(new HttpServerCodec())        // HTTP 인코딩/디코딩만 담당
    .addLast(new HttpObjectAggregator(65536)) // HTTP 메시지 합치기만 담당
    .addLast(new AuthHandler())            // 인증 확인만 담당
    .addLast(new MyBusinessHandler());     // 비즈니스 로직만 담당
```

### 데이터 흐름

```
요청 (Inbound):
  바이트 → [ByteDecoder] → [HttpDecoder] → [비즈니스Handler]
           "바이트를        "메시지를        "HTTP 요청을
            메시지로 변환"    HTTP로 변환"     실제 처리"

응답 (Outbound):
  [비즈니스Handler] → [HttpEncoder] → [ByteEncoder] → 바이트
  "응답 생성"          "HTTP를          "메시지를
                       메시지로 변환"    바이트로 변환"
```

### Handler 종류

```
InboundHandler:  요청이 들어올 때 실행 (디코딩, 비즈니스 로직)
OutboundHandler: 응답이 나갈 때 실행 (인코딩, 압축)
```

### 이전에 배운 것과의 연결

```
Spring MVC:      Filter → DispatcherServlet → Controller
AOP:             Before → 실제 메서드 → After
Netty Pipeline:  Handler1 → Handler2 → Handler3
```

전부 "요청이 여러 처리 단계를 순서대로 거친다"는 같은 패턴입니다. Netty의 Pipeline은 이것을 네트워크 바이트 레벨부터 적용한 것입니다.

```
Spring Filter Chain:  HTTP 요청 → [Filter1] → [Filter2] → [Servlet]
                      이미 HTTP로 파싱된 상태에서 시작

Netty Pipeline:       바이트 → [바이트→HTTP 변환] → [인증] → [비즈니스]
                      바이트 레벨부터 시작 (더 저수준)
```



### Netty 서버 구성 예시

```java
// Netty 서버를 직접 구성하는 코드
EventLoopGroup bossGroup = new NioEventLoopGroup(1);     // Boss: 1개 스레드
EventLoopGroup workerGroup = new NioEventLoopGroup();    // Worker: CPU 코어 수

ServerBootstrap bootstrap = new ServerBootstrap();
bootstrap.group(bossGroup, workerGroup)                  // Boss + Worker 등록
    .channel(NioServerSocketChannel.class)               // NIO 소켓 채널 사용
    .childHandler(new ChannelInitializer<SocketChannel>() {
        @Override
        protected void initChannel(SocketChannel ch) {
            ch.pipeline()                                // Pipeline 구성
                .addLast(new HttpServerCodec())           // HTTP 코덱
                .addLast(new HttpObjectAggregator(65536)) // HTTP 메시지 합치기
                .addLast(new MyBusinessHandler());        // 비즈니스 로직
        }
    });

bootstrap.bind(8080).sync();  // 8080 포트에서 시작
```

------



## 6. Tomcat vs Netty 내부 구조 비교

```
                    Tomcat                          Netty
연결 수락          Acceptor Thread (1~2개)          Boss EventLoop (1개)
연결 감시          Poller Thread (NIO Selector)     Worker EventLoop (Selector)
요청 처리          Worker Thread Pool (200개)       Worker EventLoop (CPU 코어 수)
처리 모델          Thread-per-Request               Event Loop (다수 Channel 담당)
Servlet 실행       Blocking                         해당 없음 (Handler 기반)
I/O 대기 시        스레드 점유됨                      다른 Channel 처리하러 감
파이프라인          Filter → Servlet                 Handler Pipeline
```



### Tomcat과 Netty를 매핑하면

```
Tomcat                    Netty
Acceptor Thread       =   Boss Group
Poller Thread         =   Worker Group (감시 역할)
Worker Thread Pool    =   Worker Group (처리 역할)
                          ↑ Netty는 감시와 처리를 같은 스레드에서!
```

핵심 차이를 한마디로: Tomcat은 요청당 스레드를 배정하고 I/O 대기 시 스레드가 멈추지만, Netty는 하나의 스레드가 여러 연결을 돌아가며 처리하고 I/O 대기 시 다른 연결을 처리합니다.

------



## 7. Backpressure — 리액티브의 핵심 흐름 제어

### 문제 상황: 생산자가 소비자보다 빠르면?

```java
Flux.interval(Duration.ofMillis(1))   // 1ms마다 데이터 생성 (초당 1000개)
    .subscribe(data -> {
        heavyProcess(data);            // 처리에 100ms 걸림 (초당 10개)
    });

생산 속도: 초당 1000개
소비 속도: 초당 10개
→ 매초 990개가 쌓임 → 메모리 폭발!
```

비유하면, 수도꼭지에서 물이 콸콸 쏟아지는데 컵이 작아서 넘치는 상황입니다. Backpressure는 "컵 크기만큼만 물을 줘"라고 수도꼭지에게 요청하는 것입니다.



### Backpressure란?

데이터를 받는 쪽(Subscriber)이 처리할 수 있는 속도만큼만 데이터를 요청하는 흐름 제어 메커니즘입니다.

```
Backpressure 없이:
  생산자: 데이터 1000개/초 발사!
  소비자: 10개/초밖에 못 처리... → 메모리 폭발!

Backpressure 있으면:
  소비자: "10개만 줘" (request(10))
  생산자: 10개만 보냄
  소비자: "다 처리했어, 10개 더 줘" (request(10))
  생산자: 10개 더 보냄
  → 안정적!
```



### Reactive Streams의 Backpressure 프로토콜

```
Publisher (생산자)          Subscriber (소비자)
     │                          │
     │  ①  subscribe()          │
     │←─────────────────────────│  "구독할게"
     │                          │
     │  ②  onSubscribe(subscription)
     │─────────────────────────→│  "구독 받았어, Subscription 줄게"
     │                          │
     │  ③  request(n)           │
     │←─────────────────────────│  "n개만 줘" ← 이것이 Backpressure!
     │                          │
     │  ④  onNext(data) × n     │
     │─────────────────────────→│  "요청한 n개 보내줄게"
     │                          │
     │  ⑤  request(n)           │
     │←─────────────────────────│  "다 처리했어, n개 더 줘"
     │                          │
     │  ⑥  onComplete()         │
     │─────────────────────────→│  "다 보냈어, 끝!"
```

핵심은 ③ request(n)입니다. Subscriber가 "나는 n개만 처리할 수 있어"라고 Publisher에게 알려줍니다.



### Backpressure 전략

Subscriber가 처리 속도를 따라가지 못할 때 어떻게 할지 결정하는 전략입니다.

```java
// ① BUFFER — 처리 못한 데이터를 버퍼에 쌓아둠 (기본값)
Flux.interval(Duration.ofMillis(1))
    .onBackpressureBuffer(1000)     // 최대 1000개까지 버퍼링
    .subscribe(this::process);
// 사용 사례: 데이터 유실이 불가능한 경우, 일시적 속도 차이

// ② DROP — 처리 못한 데이터를 버림
Flux.interval(Duration.ofMillis(1))
    .onBackpressureDrop(dropped -> log.warn("버림: {}", dropped))
    .subscribe(this::process);
// 사용 사례: 센서 데이터, 실시간 모니터링 (옛날 데이터보다 새 데이터가 중요)

// ③ LATEST — 가장 최신 데이터만 유지하고 나머지 버림
Flux.interval(Duration.ofMillis(1))
    .onBackpressureLatest()
    .subscribe(this::process);
// 사용 사례: 주가 화면, 실시간 위치 추적 (항상 최신 값만 필요)

// ④ ERROR — 처리 못하면 에러 발생
Flux.interval(Duration.ofMillis(1))
    .onBackpressureError()
    .subscribe(this::process);
// 사용 사례: 모든 데이터가 중요한 경우 (에러로 알림 후 대응)
```

| 전략       | 동작              | 비유                  | 사용 사례             |
| ---------- | ----------------- | --------------------- | --------------------- |
| **BUFFER** | 버퍼에 쌓아둠     | 접시를 여러 개 준비   | 데이터 유실 불가      |
| **DROP**   | 처리 못한 것 버림 | 넘치면 바닥에 버려    | 센서, 실시간 모니터링 |
| **LATEST** | 최신 것만 유지    | 가장 최신 접시만 남겨 | 주가, 실시간 위치     |
| **ERROR**  | 에러 발생         | 넘치면 알람!          | 모든 데이터가 중요    |



### 실무에서의 Backpressure

WebFlux에서 Controller가 Flux를 반환하면, Spring이 자동으로 Backpressure를 처리합니다.

```java
@GetMapping(value = "/orders/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public Flux<Order> streamOrders() {
    return orderRepository.findAll();
    // 클라이언트가 받을 수 있는 속도에 맞춰 데이터 전송
    // Spring + Netty가 Backpressure를 자동 처리
}
```

개발자가 직접 Backpressure 전략을 지정해야 하는 경우는 주로 다음과 같습니다.

- Kafka 등에서 대량 메시지를 소비할 때
- 외부 API에서 대량 데이터를 스트리밍으로 받을 때
- 실시간 센서 데이터처럼 생산 속도를 제어할 수 없을 때

------



## 8. Reactive Streams 스펙 — 4가지 인터페이스

Backpressure를 포함한 리액티브의 표준 스펙입니다. Mono와 Flux가 이 스펙의 구현체입니다.

```java
// ① Publisher — 데이터를 생산하는 쪽 (Mono, Flux가 이것의 구현체)
public interface Publisher<T> {
    void subscribe(Subscriber<T> subscriber);
}

// ② Subscriber — 데이터를 소비하는 쪽
public interface Subscriber<T> {
    void onSubscribe(Subscription s);   // 구독 시작
    void onNext(T item);               // 데이터 하나 도착
    void onError(Throwable t);         // 에러 발생
    void onComplete();                 // 완료
}

// ③ Subscription — Publisher와 Subscriber를 연결하는 다리
public interface Subscription {
    void request(long n);   // "n개 줘" ← Backpressure의 핵심!
    void cancel();          // 구독 취소
}

// ④ Processor — Publisher이면서 동시에 Subscriber (중간 처리자)
public interface Processor<T, R> extends Subscriber<T>, Publisher<R> { }
```

이 4개 인터페이스가 Java 9에서 `java.util.concurrent.Flow`로 표준 라이브러리에 포함되었습니다. Spring WebFlux의 Reactor, RxJava, Akka Streams 등이 모두 이 스펙을 구현합니다.

------



## 핵심 키워드

| 카테고리             | 키워드                                                       |
| -------------------- | ------------------------------------------------------------ |
| **Tomcat 구조**      | Server, Service, Connector, Engine, Host, Context, Servlet   |
| **Tomcat Connector** | Acceptor Thread, Poller Thread, Worker Thread, NIO Selector  |
| **Tomcat 설정**      | threads.max, max-connections, accept-count, BIO vs NIO       |
| **Netty 구조**       | Boss Group, Worker Group, EventLoop, Channel                 |
| **Netty Pipeline**   | Channel Pipeline, Handler, InboundHandler, OutboundHandler   |
| **비교**             | Tomcat NIO(Connector만 Non-blocking) vs Netty(전체 Non-blocking) |
| **Backpressure**     | request(n), BUFFER, DROP, LATEST, ERROR                      |
| **Reactive Streams** | Publisher, Subscriber, Subscription, Processor               |



## 🎯 면접 예상 질문

### Q1. Tomcat의 요청 처리 흐름을 설명해주세요.

**모범 답안:**

> Tomcat에 요청이 들어오면 먼저 Acceptor Thread가 클라이언트의 TCP 연결을 수락합니다. 수락된 연결은 Poller Thread에 등록됩니다. Poller는 Java NIO Selector를 사용하여 수천 개의 소켓을 하나의 스레드로 동시에 감시하며, 데이터가 준비된 소켓만 Worker Thread에 넘깁니다. Worker Thread가 실제 HTTP 파싱과 Servlet 실행을 담당합니다. 이 구조 덕분에 연결은 수천 개를 유지하면서도, Worker Thread는 실제 처리가 필요한 요청에만 배정됩니다.

### Q2. Tomcat NIO에서 Poller가 하는 역할은 무엇이며, 왜 효율적인가요?

**모범 답안:**

> Poller는 Java NIO Selector를 사용하여 수천 개의 소켓을 하나의 스레드로 동시에 감시합니다. BIO 방식에서는 소켓 하나당 스레드 하나가 Blocking 대기해야 했지만, Selector는 하나의 스레드가 OS 커널에 "준비된 소켓이 있나?" 한번만 물어보면 준비된 소켓 목록을 한꺼번에 받을 수 있기 때문에 효율적입니다. 덕분에 연결 수천 개를 유지하면서도 Worker Thread는 실제 데이터가 준비된 요청에만 배정됩니다.

### Q3. Netty의 EventLoop란 무엇이며, Tomcat의 Worker Thread와 어떻게 다른가요?

**모범 답안:**

> Netty의 EventLoop는 하나의 스레드가 여러 Channel(연결)의 I/O 이벤트를 무한 루프로 감시하고 처리하는 구조입니다. Tomcat의 Poller(감시) + Worker(처리) 역할을 하나의 스레드에서 동시에 수행합니다. Tomcat의 Worker Thread는 요청당 하나가 배정되어 I/O 대기 시 스레드가 멈추지만, EventLoop는 I/O 대기가 발생하면 다른 Channel을 처리하러 가서 절대 멈추지 않습니다. 덕분에 CPU 코어 수만큼의 소수 스레드로 수만 개의 동시 연결을 처리할 수 있습니다.

### Q4. Netty의 Channel Pipeline이란 무엇인가요?

**모범 답안:**

> Channel Pipeline은 Netty에서 하나의 요청이 여러 Handler를 순서대로 거치는 처리 체인입니다. 요청이 들어오면 ByteDecoder → HttpDecoder → 비즈니스 Handler 순으로 통과하며, 응답은 역순으로 Encoder를 거쳐 바이트로 변환됩니다. Spring의 Filter Chain과 비슷하지만, 바이트 레벨부터 HTTP 레벨까지 각 단계를 명시적으로 구성할 수 있습니다.

**주의할 점:**

- Channel Pipeline은 "요청이 여러 단계를 거치는 처리 체인"이지, EventLoop의 Non-blocking 동작과는 다른 개념

### Q5. Backpressure란 무엇이며, 왜 필요한가요?

**모범 답안:**

> Backpressure는 데이터를 받는 쪽(Subscriber)이 처리할 수 있는 속도만큼만 데이터를 요청하는 흐름 제어 메커니즘입니다. Publisher의 생산 속도가 Subscriber의 소비 속도보다 빠르면 처리되지 못한 데이터가 쌓여 메모리 부족이 발생할 수 있습니다. Subscriber가 request(n)으로 "n개만 줘"라고 요청하여 생산 속도를 제어합니다. 전략으로는 BUFFER(버퍼에 쌓기), DROP(버리기), LATEST(최신만 유지), ERROR(에러 발생) 등이 있습니다.
