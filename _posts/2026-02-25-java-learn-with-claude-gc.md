---
title: 자바 GC 파혜쳐보기
date: 2026-02-25 17:52:52 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, GC]        # 예: [python, tutorial]
image:
  path: /assets/img/posts/2026-02-25-java-learn-with-claude-gc/cover.jpg
  alt: 자바 GC 파혜쳐보기
---

## 📌 소개

- 소개 : 클로드 문답형식을 이용한 GC 학습
- 목표 : GC에 대해서 학습한다

## 📝 본문

## 1. Stop-The-World (STW)

### STW란?

GC가 실행될 때 **모든 애플리케이션 스레드가 정지**되는 현상이다. GC 스레드만 동작하고, 나머지 모든 스레드는 멈춘다.

### 왜 STW가 불가피한가?

GC가 객체의 참조 관계를 분석하는 도중에 다른 스레드가 참조를 변경하면, 정확한 판별이 불가능하다.

```
GC 스레드: 객체 A → Unreachable로 판별 (수거 예정)
App 스레드: (동시에) 객체 A에 새로운 참조 연결!
GC 스레드: 객체 A 수거 → 💥 살아있는 객체를 삭제해버림!
```

GC는 **참조 그래프가 변하지 않는 일관된 스냅샷(Consistent Snapshot)**이 필요하고, 이를 위해 모든 애플리케이션 스레드를 정지시키는 STW가 발생한다.

### STW의 영향

| GC 유형  | STW 시간               | 이유              |
| -------- | ---------------------- | ----------------- |
| Minor GC | 짧음 (수 ms ~ 수십 ms) | Young 영역만 스캔 |
| Full GC  | 길음 (수백 ms ~ 수 초) | 전체 Heap 스캔    |

> GC 알고리즘의 발전 역사는 **STW 시간을 어떻게 줄이느냐**의 역사이다.
>
> 

------

## 2. GC 기본 알고리즘

### 2.1 Mark-Sweep (마크-스윕)

가장 기본적인 GC 알고리즘. 두 단계로 동작한다.

**Mark 단계:** GC Root에서 출발해서 참조를 따라가며 살아있는 객체에 표시(Mark)

**Sweep 단계:** Heap 전체를 스캔하면서 Mark가 안 된 객체를 제거(Sweep)

```
[Mark 전]
Heap: [A] [B] [C] [D] [E] [F]
       (GC Root에서 도달 가능: A, C, E)

[Sweep 후]
Heap: [A] [  ] [C] [  ] [E] [  ]
           ↑        ↑        ↑
         빈 공간   빈 공간   빈 공간  ← 단편화 발생!
```

**문제점:** 메모리 단편화(Fragmentation) — 빈 공간이 듬성듬성 생겨 큰 객체 할당 시 연속 공간 부족

### 2.2 Mark-Compact (마크-컴팩트)

Mark-Sweep의 단편화 문제를 해결. 살아있는 객체를 메모리 한쪽 끝으로 모아서 압축한다.

```
[Mark 후]
Heap: [A] [  ] [C] [  ] [E] [  ]

[Compact 후]
Heap: [A] [C] [E] [         빈 공간         ]
                    ↑
                 연속 공간 확보!
```

**장점:** 단편화 없음, 연속된 빈 공간 확보

**단점:** 객체를 이동시켜야 하므로 비용이 큼 (참조 주소도 전부 업데이트 필요)

### 2.3 Copying (복사)

메모리를 두 개의 영역으로 나누고, 살아있는 객체만 다른 쪽으로 복사하는 방식. **Survivor 영역이 바로 이 알고리즘을 사용한다.**

```
[GC 전]
From: [A] [B] [C] [D]    To: [           ]
       (A, C만 살아있음)

[GC 후 — 살아있는 객체만 To로 복사]
From: [           ]       To: [A] [C]
      (완전히 비워짐)           (연속 배치!)
```

**장점:** 복사하면서 자연스럽게 연속 배치 → 단편화 없음, 매우 빠름

**단점:** 메모리의 절반만 사용 가능

### 알고리즘 비교

| 알고리즘         | 단편화 | 속도             | 메모리 효율        | 사용 위치        |
| ---------------- | ------ | ---------------- | ------------------ | ---------------- |
| **Mark-Sweep**   | ❌ 발생 | 빠름             | 좋음 (전체 사용)   | CMS의 기반       |
| **Mark-Compact** | ✅ 없음 | 느림 (이동 비용) | 좋음 (전체 사용)   | Old Generation   |
| **Copying**      | ✅ 없음 | 매우 빠름        | 나쁨 (절반만 사용) | Young Generation |

**JVM은 영역별로 알고리즘을 조합하여 사용한다:**

- **Young Generation** → Copying (객체가 대부분 죽으므로 복사할 양이 적어서 효율적)
- **Old Generation** → Mark-Compact (오래 사는 객체가 많아서 메모리를 절반만 쓸 수 없음)



------

## 3. GC 구현체 (Garbage Collectors)

### 3.1 Serial GC

가장 단순한 GC. **싱글 스레드**로 GC를 수행한다.

```
App 스레드들:  ████████████ [STW ■■■■■] ████████████
GC 스레드:                  [GC 수행  ]
                            (스레드 1개)
```

- Young: Copying / Old: Mark-Compact
- **장점:** 오버헤드가 적음, 단순함
- **단점:** STW가 길다
- **적합한 환경:** 메모리가 작고 CPU 코어가 적은 환경 (임베디드 등)
- **옵션:** `-XX:+UseSerialGC`

### 3.2 Parallel GC (Throughput GC)

Serial과 동일한 알고리즘이지만, GC를 **여러 스레드가 병렬로** 수행한다.

```
App 스레드들:  ████████████ [STW ■■] ████████████
GC 스레드 1:                [GC 수행]
GC 스레드 2:                [GC 수행]  (여러 스레드가 병렬)
GC 스레드 3:                [GC 수행]
```

- Young: Copying (병렬) / Old: Mark-Compact (병렬)
- **장점:** Serial보다 STW가 짧음, 처리량(Throughput)이 높음
- **단점:** 여전히 STW가 존재, GC 시 모든 App이 멈춤
- **적합한 환경:** 배치 처리, 높은 처리량이 중요한 서버
- **옵션:** `-XX:+UseParallelGC`
- **Java 8의 기본 GC**

### 3.3 CMS (Concurrent Mark Sweep)

**애플리케이션과 동시에(Concurrent)** GC를 수행하여 STW를 최소화한 GC이다.

```
App 스레드들:  ████ [STW] ██████████████ [STW] ████████
GC 스레드들:       [Init] [Concurrent   ] [Re ]
                   Mark   Marking        mark
                   (짧음)  (앱과 동시!)   (짧음)
```

**4단계로 동작:**

| 단계               | STW 여부 | 설명                                                     |
| ------------------ | -------- | -------------------------------------------------------- |
| ① Initial Mark     | **STW**  | GC Root에서 직접 참조하는 객체만 빠르게 Mark (매우 짧음) |
| ② Concurrent Mark  | 없음     | 참조 체인을 따라가며 Mark (App과 동시 실행)              |
| ③ Remark           | **STW**  | Concurrent Mark 중 변경된 참조를 보정 (짧음)             |
| ④ Concurrent Sweep | 없음     | Unreachable 객체 제거 (App과 동시 실행)                  |

- **장점:** STW가 매우 짧음 (Initial Mark + Remark만)
- **단점:** CPU를 많이 사용, Mark-Sweep 기반이라 메모리 단편화 발생, 단편화가 심해지면 Full GC 발생
- **옵션:** `-XX:+UseConcMarkSweepGC`
- **Java 9에서 Deprecated, Java 14에서 제거**

### 3.4 G1 GC (Garbage First)

CMS의 단점을 해결하기 위해 만들어진 GC. 기존 세대별 고정 영역 개념을 깨뜨린 혁신적인 설계이다.

(상세 내용은 다음 섹션에서 설명)

- **옵션:** `-XX:+UseG1GC`
- **Java 9부터 기본 GC**

### 3.5 ZGC

STW를 극도로 줄이는 것에 초점을 맞춘 최신 GC이다.

- **목표:** STW를 10ms 이하로 유지 (Heap 크기에 관계없이)
- **핵심 기술:** 거의 모든 GC 작업을 App과 동시에(Concurrent) 수행
- **Heap 크기:** 수백 MB부터 수 TB까지 지원
- **옵션:** `-XX:+UseZGC`
- **Java 15에서 정식 도입**



------

## 4. G1 GC 심층 이해

### Region 기반 설계

기존처럼 Young/Old를 물리적으로 고정 분할하지 않고, Heap을 **동일한 크기의 Region(1~32MB)**으로 나누어, 각 Region에 역할을 **동적으로 부여**한다.

```
기존 방식:
[    Young (고정)    |        Old (고정)          ]

G1 방식:
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│ E │ S │ O │ O │ E │ H │ O │ E │ S │   │
└───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
 E=Eden  S=Survivor  O=Old  H=Humongous  (빈)=Free

 → 각 Region의 역할이 GC마다 동적으로 바뀜!
```

**Humongous Region:** Region 크기의 50%를 초과하는 큰 객체를 위한 특별한 영역

### 동작 방식

G1은 **"Garbage First"** 라는 이름처럼, 가비지가 가장 많은 Region을 우선적으로 수거한다.

| GC 유형      | 설명                                                         |
| ------------ | ------------------------------------------------------------ |
| **Young GC** | Eden Region이 가득 차면 살아있는 객체를 Survivor Region으로 복사 |
| **Mixed GC** | Young + 가비지가 많은 Old Region을 함께 수거                 |
| **Full GC**  | 최후의 수단으로 전체 Heap 정리 (가능한 발생하지 않도록 설계됨) |

### 예측 가능한 STW — G1의 핵심 장점

```
-XX:MaxGCPauseMillis=200  (목표 STW 시간: 200ms)
```

G1은 사용자가 목표 STW 시간을 설정하면, 그 시간 내에 수거할 수 있는 만큼의 Region만 선택적으로 수거한다. 전체를 한꺼번에 정리하지 않고, **예산(시간) 내에서 가장 효율적인 Region만 골라서 수거**하는 것이다.

### Region 기반이 기존 고정 분할보다 유리한 이유

- **유연한 메모리 할당:** 상황에 따라 Young/Old 비율을 동적으로 조절 가능
- **부분 수거(Partial Collection):** 가비지가 많은 Region만 선택적으로 수거 가능
- **단편화 자동 해소:** Region 내에서 Copying 알고리즘을 사용하여 단편화 방지
- **대용량 Heap에서 유리:** Region 단위로 처리하므로 Heap 크기가 커져도 STW를 일정 수준으로 유지



------

## 5. Parallel vs Concurrent

GC 맥락에서 Parallel과 Concurrent는 다른 의미를 가진다.

### Parallel (병렬)

**GC 스레드끼리** 여러 개가 동시에 작업하지만, **App 스레드는 멈춰있음** (STW 상태)

```
App 스레드들:  [        멈춤 (STW)        ]
GC 스레드 1:   [■■■■■■■■■■]
GC 스레드 2:   [■■■■■■■■■■]  ← GC끼리 병렬
GC 스레드 3:   [■■■■■■■■■■]
```

### Concurrent (동시)

**GC 스레드와 App 스레드가 동시에** 실행. App이 멈추지 않는다.

```
App 스레드들:  [████████████████████████]  ← 계속 실행 중!
GC 스레드 1:   [■■■■■■■■■■]
GC 스레드 2:   [■■■■■■■■■■]  ← App과 동시 실행
```

### 비교

| 용어           | 의미                 | App 스레드 상태 | STW              |
| -------------- | -------------------- | --------------- | ---------------- |
| **Parallel**   | GC 스레드끼리 병렬   | ❌ 멈춤          | 있음             |
| **Concurrent** | GC와 App이 동시 실행 | ✅ 실행 중       | 없거나 매우 짧음 |

G1 GC는 **둘 다** 사용한다 — 일부 단계는 Parallel(STW), 일부 단계는 Concurrent(App과 동시)로 동작한다.



------

## 6. Throughput vs Latency 트레이드오프

### 트레이드오프란?

**하나를 얻으면 다른 하나를 잃는 관계**이다. 양립할 수 없는 두 가지 사이에서 균형을 찾아야 하는 상황이다.

### GC에서의 트레이드오프

**Throughput (처리량):** 전체 시간 중 App이 실제로 일한 비율 (예: 100초 중 GC 5초 → 95%)

**Latency (지연):** 개별 GC의 STW 시간 (예: GC 한 번에 200ms)

### Parallel GC — Throughput 우선

```
App: ██████████████████ [STW ■■■■■] ██████████████████
     (오래 일하고)       (한번에 많이)  (다시 오래 일함)
```

GC를 한꺼번에 몰아서 하므로 전체 GC 시간은 짧음 → Throughput 높음. 하지만 한 번의 STW가 길다 → Latency 나쁨.

### CMS / G1 — Latency 우선

```
App: ████ [■] ████ [■] ████ [■] ████ [■] ████
     (조금) (짧음) (조금) (짧음) (조금) (짧음)
```

GC를 자주, 조금씩 하므로 한 번의 STW가 짧음 → Latency 좋음. 하지만 GC가 자주 발생하고 CPU를 나눠 써야 함 → Throughput 감소.

### 애플리케이션별 선택

| 전략               | Throughput | Latency | 대표 GC      | 적합한 환경       |
| ------------------ | ---------- | ------- | ------------ | ----------------- |
| GC를 한번에 몰아서 | ✅ 높음     | ❌ 길다  | Parallel GC  | 배치 처리 서버    |
| GC를 자주 조금씩   | ❌ 낮음     | ✅ 짧다  | CMS, G1, ZGC | 웹 서버, API 서버 |

------

## 7. Java에서의 메모리 누수

GC가 있는 Java에서도 메모리 누수는 발생할 수 있다. 핵심은 **GC Root에서 도달 가능한 상태로 불필요한 객체가 남아있는 것**이다.

### 7.1 ThreadLocal 누수

스레드풀의 스레드는 GC Root이며 죽지 않고 재사용된다. ThreadLocal의 Entry는 WeakReference Key를 사용하므로 Key는 GC 수거 가능하지만, **Value는 Strong Reference**라서 Key가 수거되어도 Value는 살아남는다.

```
Thread (GC Root, 스레드풀에서 재사용)
  └── ThreadLocalMap
        └── Entry [key=null (GC 수거됨)] [value=거대한 객체 ← 누수!]
```

**해결:** `ThreadLocal.remove()`를 반드시 호출한다.

### 7.2 HashSet/HashMap에서 hashCode 변경

java

```java
Set<MutableObject> set = new HashSet<>();
MutableObject obj = new MutableObject("A");
set.add(obj);           // hashCode 기준으로 버킷에 저장
obj.setName("B");       // 객체 내부 값 변경 → hashCode 변경!
set.remove(obj);        // 새로운 hashCode로 찾으려 하지만 실패 → 제거 안 됨!
```

Set이 내부적으로 참조를 유지하고 있어 GC 수거가 안 되지만, `remove()`나 `contains()`로 접근이 불가능해 영원히 Heap에 남는다.

### 7.3 기타 메모리 누수 패턴

| 패턴                          | 설명                                                         |
| ----------------------------- | ------------------------------------------------------------ |
| **static 컬렉션에 계속 추가** | static List에 add만 하고 제거하지 않으면, static은 GC Root이므로 모든 객체가 Reachable |
| **리스너/콜백 미해제**        | 이벤트 리스너를 등록하고 해제하지 않으면 리스너가 참조하는 객체가 수거되지 않음 |
| **커넥션/스트림 미종료**      | DB 커넥션, InputStream 등을 close() 하지 않으면 관련 객체가 남아있음 |



------

## 8. GC 관련 JVM 옵션

### 주요 옵션 정리

| 옵션                   | 설명                                             |
| ---------------------- | ------------------------------------------------ |
| `-Xms`                 | Heap 초기(최소) 크기                             |
| `-Xmx`                 | Heap 최대 크기                                   |
| `-XX:NewRatio`         | Old:Young 비율 (기본 2 → Old:Young = 2:1)        |
| `-XX:SurvivorRatio`    | Eden:Survivor 비율 (기본 8 → Eden:S0:S1 = 8:1:1) |
| `-XX:MaxGCPauseMillis` | G1의 목표 STW 시간 (ms)                          |
| `-XX:+UseG1GC`         | G1 GC 사용                                       |
| `-XX:+UseZGC`          | ZGC 사용                                         |
| `-XX:+UseParallelGC`   | Parallel GC 사용                                 |
| `-XX:MaxMetaspaceSize` | Metaspace 최대 크기                              |
| `-Xss`                 | 스레드당 Stack 크기                              |
| `-XX:+PrintGCDetails`  | GC 로그 상세 출력                                |

### 실무 권장사항

**-Xms와 -Xmx를 같은 값으로 설정:** Heap 크기가 동적으로 늘어날 때 리사이징 오버헤드가 발생하므로, 같은 값으로 설정하여 방지한다.

**NewRatio 설정에 따른 영향:**

- Young을 크게 하면 → Minor GC 빈도 감소, 하지만 한 번의 Minor GC 시간 증가
- Old를 크게 하면 → Full GC 빈도 감소, 하지만 한 번의 Full GC 시간 증가



------

## 9. GC 동작 실전 예시

### 단명 객체 대량 생성

java

```java
public void process() {
    for (int i = 0; i < 1_000_000; i++) {
        String temp = new String("data-" + i);
        // temp를 사용하고 바로 버림
    }
}
```

**동작 과정:**

```
[i=0] temp → "data-0" 객체 생성 (Eden에 할당)
[i=1] temp → "data-1" 객체 생성 (Eden에 할당)
       └── "data-0"은 이제 참조 없음 → Unreachable

  ... Eden에 객체가 계속 쌓임 ...

[i=50000쯤] Eden이 가득 참 → Minor GC 발생!
   └── 현재 temp가 가리키는 "data-50000"만 Reachable
   └── 나머지 49,999개는 전부 수거됨

[i=50001~] 다시 Eden에 객체 할당 시작
   ... Eden 가득 참 → 또 Minor GC ...
   (이 과정이 반복)
```

**핵심 포인트:**

- **temp는 Stack에 한 번만 생성**되고, 매 반복마다 참조만 새 객체로 갈아끼운다. 100만 개 쌓이지 않는다.
- **GC는 for문 도중에 발생**한다. 메서드 종료를 기다리지 않는다. Eden이 가득 차면 JVM이 자동으로 Minor GC를 트리거한다.
- **Weak Generational Hypothesis의 완벽한 예시**이다. 생성 직후 바로 참조가 끊기는 단명 객체이므로, Eden에서 생성되고 다음 Minor GC에서 바로 수거된다.



------

## 10. GC 발전 역사 종합

| GC           | STW               | 핵심 특징                     | Java 기본 GC              |
| ------------ | ----------------- | ----------------------------- | ------------------------- |
| **Serial**   | 길다              | 싱글 스레드, 단순             | -                         |
| **Parallel** | 보통              | 멀티 스레드 병렬, 높은 처리량 | Java 8 기본               |
| **CMS**      | 짧다              | Concurrent, 단편화 문제       | Deprecated (Java 14 제거) |
| **G1**       | 예측 가능         | Region 기반, 목표 STW 설정    | Java 9~ 기본              |
| **ZGC**      | 매우 짧다 (≤10ms) | 초저지연, 대용량 Heap         | Java 15 정식 도입         |

**발전 방향:**

```
싱글 → 병렬 → 동시실행 → Region 기반 → 초저지연
(Serial) (Parallel) (CMS)     (G1)       (ZGC)

핵심은 항상 STW를 줄이는 것!
```



## 🎯 면접 예상 질문

---

**Q1. Stop-The-World(STW)란 무엇이고, 왜 발생하나요?**

> GC 실행 시 모든 애플리케이션 스레드가 정지되는 현상입니다. GC가 객체의 참조 관계를 분석하는 동안 다른 스레드가 참조를 변경하면 정확한 판별이 불가능하기 때문에, 참조 그래프가 변하지 않는 일관된 스냅샷을 위해 STW가 발생합니다.

------

**Q2. Mark-Sweep, Mark-Compact, Copying 알고리즘의 차이는?**

> Mark-Sweep은 살아있는 객체를 표시하고 나머지를 제거하는 방식으로, 단편화가 발생합니다. Mark-Compact는 제거 후 살아있는 객체를 한쪽으로 모아 단편화를 해소하지만 이동 비용이 큽니다. Copying은 살아있는 객체를 다른 영역으로 복사하여 단편화 없이 빠르지만 메모리 절반만 사용 가능합니다. JVM은 Young에서는 Copying을, Old에서는 Mark-Compact를 사용합니다.

------

**Q3. GC의 종류와 특징을 설명해주세요.**

> Serial은 싱글 스레드로 단순하지만 STW가 깁니다. Parallel은 GC 스레드를 여러 개 사용하여 병렬 수거하며 Java 8의 기본 GC입니다. CMS는 App과 동시에 GC를 수행하여 STW를 줄이지만 단편화 문제로 Deprecated 되었습니다. G1은 Region 기반으로 예측 가능한 STW를 제공하며 Java 9부터 기본 GC입니다. ZGC는 STW를 10ms 이하로 유지하는 초저지연 GC로 Java 15에서 정식 도입되었습니다.

------

**Q4. G1 GC의 Region 기반 설계가 기존 방식보다 유리한 이유는?**

> 기존 방식은 Young/Old를 물리적으로 고정 분할하여 유연성이 떨어졌습니다. G1은 Heap을 동일 크기의 Region으로 나누고 역할을 동적으로 부여하여 상황에 맞게 비율을 조절할 수 있습니다. 가비지가 가장 많은 Region만 선택적으로 수거(Partial Collection)하여 목표 STW 시간 내에 처리 가능하고, Region 내에서 Copying 알고리즘을 사용하여 단편화도 방지합니다.

------

**Q5. Parallel과 Concurrent의 차이는?**

> Parallel은 GC 스레드끼리 여러 개가 동시에 작업하지만 App 스레드는 멈춰있는 것(STW)이고, Concurrent는 GC 스레드와 App 스레드가 동시에 실행되는 것입니다. Parallel은 STW가 있고, Concurrent는 STW가 없거나 매우 짧습니다. G1 GC는 일부 단계에서 Parallel을, 다른 단계에서 Concurrent를 함께 사용합니다.

------

**Q6. Throughput과 Latency의 트레이드오프를 설명해주세요.**

> Throughput은 전체 시간 중 App이 실제로 일한 비율이고, Latency는 개별 GC의 STW 시간입니다. GC를 한꺼번에 몰아서 하면 Throughput이 높지만 Latency가 길고(Parallel GC), GC를 자주 조금씩 하면 Latency가 짧지만 Throughput이 감소합니다(CMS, G1). 배치 처리 서버는 Throughput 우선, 웹/API 서버는 Latency 우선으로 GC를 선택합니다.

------

**Q7. Java에서 메모리 누수가 발생하는 경우는?**

> GC Root에서 도달 가능한 상태로 불필요한 객체가 남아있는 경우입니다. 대표적으로 ThreadLocal에서 remove()를 호출하지 않아 스레드풀의 스레드(GC Root)가 Value를 계속 참조하는 경우, static 컬렉션에 add만 하고 제거하지 않는 경우, HashMap의 Key 객체 hashCode가 변경되어 remove가 실패하는 경우, 리스너/콜백 미해제, 커넥션/스트림 미종료 등이 있습니다.

------

**Q8. GC 관련 주요 JVM 옵션을 설명해주세요.**

> -Xms/-Xmx는 Heap의 초기/최대 크기이며, 같은 값으로 설정하여 리사이징 오버헤드를 방지하는 것이 권장됩니다. -XX:NewRatio는 Old:Young 비율을 설정합니다(기본 2). -XX:MaxGCPauseMillis는 G1의 목표 STW 시간을 설정합니다. -XX:+UseG1GC/-XX:+UseZGC 등으로 GC 종류를 지정할 수 있습니다.

------

**Q9. GC에 대해 전체적으로 설명해주세요. (종합)**

> GC는 사용하지 않는 객체를 자동으로 수거하여 메모리를 관리하는 기능입니다. GC Root(Stack의 지역변수, static 변수, 활성 스레드 등)에서 참조 체인을 따라 도달할 수 없는 객체를 수거 대상으로 판별하며, 이를 Reachability Analysis라고 합니다.
>
> Heap은 Young과 Old Generation으로 나뉩니다. 대부분의 객체는 생성 직후 금방 죽고, 오래 살아남은 객체는 계속 오래 사는 경향이 있기 때문입니다(Weak Generational Hypothesis).
>
> 기본 알고리즘으로는 Mark-Sweep(단편화 발생), Mark-Compact(압축으로 단편화 해소), Copying(복사로 빠르지만 메모리 절반 사용)이 있으며, JVM은 영역별로 조합하여 사용합니다.
>
> GC 구현체로는 싱글 스레드의 Serial, 멀티 스레드 병렬의 Parallel(Java 8 기본), App과 동시 수행하는 CMS(Deprecated), Region 기반 예측 가능 STW의 G1(Java 9~ 기본), 초저지연의 ZGC가 있습니다.
>
> GC의 발전 역사는 STW를 줄이는 역사이며, 싱글 → 병렬 → 동시실행 → Region 기반 → 초저지연 방향으로 발전해왔습니다.
