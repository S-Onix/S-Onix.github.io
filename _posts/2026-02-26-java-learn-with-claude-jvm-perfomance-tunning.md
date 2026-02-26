---
title: 자바 JVM 튜닝 방법 알아보기
date: 2026-02-26 17:39:48 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, JVM]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : claude 문답형식을 통한 JVM 튜닝방법 학습
- 목표 : JVM에 대해서 더 깊이 공부한다.

## 📝 JVM 성능 튜닝 정리

## 1. JVM 모니터링 도구

### JDK 내장 도구

| 도구                     | 용도                                    | 주요 명령어                                   |
| ------------------------ | --------------------------------------- | --------------------------------------------- |
| **jps**                  | 실행 중인 Java 프로세스 목록 확인       | `jps -v`                                      |
| **jstat**                | GC 상태, 힙 사용량 실시간 모니터링      | `jstat -gc PID 1000`                          |
| **jmap**                 | Heap Dump 생성                          | `jmap -dump:format=b,file=heapdump.hprof PID` |
| **jstack**               | 스레드 스택 트레이스 출력 (데드락 분석) | `jstack PID`                                  |
| **jconsole / jvisualvm** | GUI 기반 모니터링                       | -                                             |

### jstat 주요 컬럼

- **S0C / S1C / EC / OC**: Survivor0 / Survivor1 / Eden / Old Capacity
- **S0U / S1U / EU / OU**: 각 영역 Used
- **MC / MU**: Metaspace Capacity / Used

### 외부 도구

- **Eclipse MAT**: Heap Dump 분석, 메모리 누수 탐지
- **Arthas**: 운영 중인 JVM 실시간 진단
- **Prometheus + Grafana**: 메트릭 수집 및 대시보드
- **APM 도구**: Pinpoint, Datadog 등

------



## 2. 주요 JVM 옵션

### Heap & Stack 크기

| 옵션   | 설명                |
| ------ | ------------------- |
| `-Xms` | Heap 최소 크기      |
| `-Xmx` | Heap 최대 크기      |
| `-Xss` | 스레드당 Stack 크기 |

> **Tip**: `-Xms`와 `-Xmx`를 같은 값으로 설정하면 런타임 Heap 리사이징 오버헤드를 방지할 수 있다.

### GC 알고리즘 선택

| 옵션                 | 설명                 | 적합한 상황                       |
| -------------------- | -------------------- | --------------------------------- |
| `-XX:+UseG1GC`       | G1 GC (Java 9+ 기본) | 웹/API 서버 (낮은 지연 필요)      |
| `-XX:+UseZGC`        | ZGC (초저지연)       | 실시간 시스템 (STW 1ms 이하 목표) |
| `-XX:+UseParallelGC` | Parallel GC          | 배치 작업 (높은 처리량 필요)      |

### 기타 주요 옵션

| 옵션                   | 설명                                         |
| ---------------------- | -------------------------------------------- |
| `-XX:NewRatio`         | Young : Old 비율 (예: 2이면 Young:Old = 1:2) |
| `-XX:MaxGCPauseMillis` | G1 GC의 목표 STW 시간 (ms)                   |
| `-XX:MetaspaceSize`    | Metaspace 초기 크기                          |
| `-XX:MaxMetaspaceSize` | Metaspace 최대 크기 (무제한 방지)            |

> **MaxMetaspaceSize를 설정하는 이유**: 기본값은 무제한이므로 ClassLoader 누수 시 OS 메모리를 전부 소비할 수 있다. 상한선을 설정하면 누수를 빠르게 감지할 수 있다.

------



## 3. 실전 JVM 옵션 구성 예시

### 조건: Java 11, 서버 메모리 8GB, 웹 API 서버, STW 200ms 이하

bash

```bash
# GC 설정
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200

# Heap 크기 (서버 메모리의 50~60%)
-Xms4g -Xmx4g

# Metaspace
-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=512m

# Stack (웹 서버는 스레드 많으므로 줄이기)
-Xss512k

# GC 로그 (Java 9+ 통합 로깅)
-Xlog:gc*:file=/logs/gc.log:time,level,tags:filecount=10,filesize=100m
```

### 서버 메모리 배분 (8GB 기준)

| 영역                                  | 크기          |
| ------------------------------------- | ------------- |
| Heap                                  | ~4GB (50~60%) |
| Metaspace                             | ~512MB        |
| Native Memory (JNI, 스레드, NIO 버퍼) | ~1GB          |
| OS + 기타                             | ~2.5GB        |

> **주의**: 서버 메모리 전부를 Heap에 할당하면 안 된다. OS, Metaspace, Native Memory도 필요하다.

------



## 4. GC 튜닝이 필요한 위험 신호

| 위험 신호           | 의미                                                        |
| ------------------- | ----------------------------------------------------------- |
| Full GC 빈도 높음   | 짧은 간격으로 반복 발생                                     |
| GC 후 메모리 미감소 | GC 후에도 사용량이 거의 안 줄어듦 → 메모리 누수 의심        |
| STW 시간 과다       | 웹/API: 100~200ms 이하, 실시간: 10ms 이하, 배치: 수 초 허용 |
| Minor GC 빈도 과다  | 0.5초마다 발생 → Eden 너무 작음                             |
| Heap 우상향 패턴    | 톱니(/\/\/) 대신 우상향(/‾/‾) → 메모리 누수                 |

------



## 5. 메모리 누수 진단 프로세스

### 1단계: jstat으로 실시간 확인

bash

```bash
$ jstat -gc PID 1000
```

- Old 사용량(OU)이 GC 후에도 계속 증가하는지 확인
- Full GC 횟수 증가 추이 확인

### 2단계: jmap으로 Heap Dump 생성 (두 번!)

bash

```bash
$ jmap -dump:format=b,file=dump1.hprof PID    # 1차
# 10~20분 후
$ jmap -dump:format=b,file=dump2.hprof PID    # 2차
```

### 3단계: Eclipse MAT로 분석

- **Dominator Tree**: 메모리를 가장 많이 차지하는 객체 확인
- **Leak Suspects Report**: 자동으로 누수 의심 객체 찾기
- **GC Root 참조 체인**: 어떤 GC Root가 해당 객체를 참조하는지 추적

```
GC Root → Thread → ThreadLocalMap → Entry → 거대한 객체
→ "ThreadLocal에서 remove() 안 했구나!"
```

### 4단계: 원인별 해결

| 원인                    | 해결                        |
| ----------------------- | --------------------------- |
| ThreadLocal 미해제      | `ThreadLocal.remove()` 추가 |
| static 컬렉션 계속 추가 | 크기 제한 또는 주기적 정리  |
| 리스너/콜백 미해제      | 해제 로직 추가              |
| 커넥션 미종료           | `try-with-resources` 사용   |

### 5단계: jstat으로 재모니터링

- 수정 전: 우상향 /‾/‾/‾ (비정상)
- 수정 후: 톱니 /\/\/\ (정상)

> **참고**: jstack은 데드락/스레드 블로킹 진단용이다. 메모리 누수는 jmap + MAT 조합이 핵심.

------



## 6. 실전 사례: 웹 API 서버 간헐적 지연

### 문제

평소 빠르지만 가끔 500ms 이상 지연 발생

### 원인

Full GC로 인한 STW. Parallel GC(배치용)를 웹 서버에 사용 중.

### 해결

bash

```bash
# 1단계: GC 로그 활성화
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/path/gc.log

# 2단계: GC 알고리즘 변경 (Parallel → G1)
-XX:+UseG1GC -XX:MaxGCPauseMillis=200

# 3단계: Heap 크기 조정
-Xms4g -Xmx4g
```

------



## 7. 실전 사례: OOM Metaspace (ClassLoader 누수)

### 문제

Spring Boot 배포 후 며칠 지나면 응답 느려지고 OutOfMemoryError: Metaspace 발생. 재시작하면 정상.

### 원인

ClassLoader 누수. 핫 리로드 시 이전 ClassLoader가 GC되지 않아 Metaspace 메타데이터가 계속 쌓임.

### 진단

1. `jstat -gc`로 MU(Metaspace Used) 우상향 확인
2. `jmap`으로 Heap Dump 두 번 생성 → 비교
3. Eclipse MAT에서 ClassLoader별 그룹핑 → 이전 ClassLoader 잔존 확인
4. GC Root 참조 체인 추적 → 누수 원인 파악

### 해결

bash

```bash
# JVM 옵션
-XX:MaxMetaspaceSize=512m
-XX:+TraceClassLoading
-XX:+TraceClassUnloading
```

코드 수정: ThreadLocal.remove(), DriverManager.deregisterDriver() 등

------



## 8. Escape Analysis (탈출 분석)

JIT 컴파일러가 "이 객체가 메서드 밖으로 탈출하는가?"를 분석하여 최적화하는 기법.

### 객체가 탈출하지 않으면 적용되는 최적화

| 최적화                               | 설명                                                         |
| ------------------------------------ | ------------------------------------------------------------ |
| **스칼라 치환 (Scalar Replacement)** | 객체를 만들지 않고 필드를 개별 변수로 분해. Heap 할당 자체가 사라짐 |
| **스택 할당 (Stack Allocation)**     | Heap 대신 Stack에 할당. 메서드 종료 시 자동 해제, GC 불필요  |
| **동기화 제거 (Lock Elision)**       | 탈출하지 않는 객체의 synchronized 제거                       |

### 예시

java

```java
public int calculate() {
    Point p = new Point(3, 5);  // 메서드 밖으로 안 나감
    return p.getX() + p.getY();
}

// JIT 최적화 후 (스칼라 치환)
int x = 3;
int y = 5;
return x + y;  // Heap 할당 없음!
```

### GC 부담 감소 원리

100만 번 호출 시 Heap 할당 0개 → GC 할 일 자체가 없어짐.

### 인라이닝과의 관계

**인라이닝 → Escape Analysis → 스칼라 치환** 순서로 연쇄적 최적화가 일어남.

------



## 9. 튜닝의 제1원칙: "측정 먼저!" (Measure First!)

> "섣부른 최적화는 모든 악의 근원이다" — Donald Knuth

### 잘못된 접근 ❌

```
"G1 GC가 좋다던데 일단 바꿔야지"
"Heap을 최대한 크게 잡으면 좋겠지"
→ 근거 없는 추측 → 오히려 성능 악화 가능
```

### 올바른 접근 ✅

```
문제 발생 → 측정(모니터링) → 병목 분석 → 최소 변경 → 재측정 → 반복
```

### 핵심 원칙

1. **측정 먼저**: 추측하지 말고 데이터로 확인
2. **한 번에 하나만 변경**: 여러 옵션 동시 변경 시 어떤 게 효과인지 알 수 없음
3. **변경 전후 비교**: 실제로 개선됐는지 반드시 확인

### "서버가 느리다" 진단 프로세스

```
1. 먼저 측정!
   ├── jstat -gc PID 1000       → GC 문제인지?
   ├── jstack PID               → 스레드 문제인지? (데드락, 블로킹)
   ├── jstat -gc (MC/MU 추이)   → Metaspace 문제인지?
   └── top -p PID               → CPU/메모리 문제인지?

2. 병목 지점 판단 후 대응
   ├── GC 원인       → Heap 크기 조정, GC 알고리즘 변경
   ├── 스레드 원인    → jstack 분석, 데드락 해결
   ├── 메모리 누수    → jmap + MAT로 추적
   └── JVM 외부 원인  → DB 쿼리, 네트워크, 디스크 I/O 확인
```

------



## 10. 튜닝 체크리스트

-  GC 알고리즘 선택 (G1 / ZGC)
-  Heap 크기 설정 (Xms = Xmx, 서버 메모리의 50~60%)
-  Metaspace 상한선 설정
-  Stack 크기 조정 (웹 서버는 스레드 많으므로 줄이기)
-  GC 로그 항상 활성화
-  MaxGCPauseMillis 목표 설정 (G1)
-  모니터링 체계 구축 (Prometheus + Grafana 등)
