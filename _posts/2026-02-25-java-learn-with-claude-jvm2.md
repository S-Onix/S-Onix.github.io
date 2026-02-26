---
title: 자바 JVM 파헤쳐보기2
date: 2026-02-25 15:04:11 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, JVM]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : Claude 문답형식을 이용한 JVM 학습
- 목표 : JVM를 더 깊게 알아간다.

## 📝 본문

## 1. JVM 메모리 영역 전체 구조

Java 프로그램이 실행되면 JVM은 메모리를 **다섯 가지 영역(Runtime Data Areas)**으로 나누어 관리한다. 이 영역들은 크게 **스레드마다 독립적으로 생성되는 영역**과 **모든 스레드가 공유하는 영역**으로 나뉜다.

```
JVM Runtime Data Areas

[스레드 독립 (Thread-private)]
┌──────────────────────────────────────────────────┐
│ ① JVM Stack         │ 스택 프레임이 쌓이는 곳       │
│ ② PC Register       │ 현재 바이트코드 실행 주소      │
│ ③ Native Method Stack│ 네이티브 메서드의 스택 프레임   │
└──────────────────────────────────────────────────┘

[스레드 공유 (Thread-shared)]
┌──────────────────────────────────────────────────┐
│ ④ Heap              │ 객체, 배열이 저장되는 곳 (GC 대상) │
│ ⑤ Method Area       │ 클래스 메타데이터, 상수 풀 등     │
└──────────────────────────────────────────────────┘
```

**왜 스레드 독립/공유로 나누는가?**

각 스레드는 자기만의 실행 흐름을 가지기 때문에, 스택과 PC가 분리되어야 서로 간섭 없이 동작한다. 반면 객체나 클래스 정보는 여러 스레드가 함께 사용할 수 있어야 하므로 공유 영역에 둔다. 이 공유 영역에서 가시성(visibility), 동시성(concurrency) 문제가 발생하며, volatile이나 synchronized가 필요한 이유이기도 하다.



------

## 2. 스레드 독립 영역 — JVM Stack

JVM Stack은 메서드가 호출될 때마다 **스택 프레임(Stack Frame)**이 생성되어 쌓이는 곳이다.

### 스택 프레임의 구성 요소

| 구성 요소                                 | 설명                                                         |
| ----------------------------------------- | ------------------------------------------------------------ |
| **지역 변수 배열 (Local Variable Array)** | this, 매개변수, 지역 변수 저장. [0]=this, [1]=첫 번째 인자... |
| **오퍼랜드 스택 (Operand Stack)**         | 연산의 중간 결과를 임시 저장하는 작업 공간                   |
| **프레임 데이터 (Frame Data)**            | 리턴 주소, 상수 풀 참조, 예외 테이블                         |

### 스택 구조 예시

```
JVM Stack (Thread A)
┌──────────────────────┐
│  methodC() 스택 프레임  │  ← 현재 실행 중
├──────────────────────┤
│  methodB() 스택 프레임  │
├──────────────────────┤
│  main() 스택 프레임     │  ← 가장 먼저 호출됨
└──────────────────────┘
```

메서드가 리턴되면 해당 스택 프레임이 pop되고 호출자의 프레임으로 돌아간다.

### 참조 변수와 객체의 관계

```
Stack                              Heap
┌─────────────────┐             ┌──────────────────┐
│ s1: 0x1234 ─────┼────────────▶│ Student 객체      │
│ s2: 0x5678 ─────┼──────┐     │  name: ──▶"Kim"   │
│ count: 2        │      │     │  age: 20          │
└─────────────────┘      │     └──────────────────┘
                         │     ┌──────────────────┐
                         └────▶│ Student 객체      │
                               │  name: ──▶"Lee"   │
                               │  age: 22          │
                               └──────────────────┘
```

Stack에는 **참조(주소)**만 저장되고, 실제 객체 데이터는 **Heap**에 있다. 기본형(int, boolean 등)은 값 자체가 스택에 직접 저장된다.



------

## 3. 스레드 독립 영역 — PC Register

PC Register(Program Counter Register)는 **현재 실행 중인 바이트코드의 주소**를 저장하는 아주 작은 메모리 영역이다.

### 스레드마다 독립적이어야 하는 이유

멀티스레드 환경에서 **컨텍스트 스위칭(Context Switching)**이 발생할 때, 각 스레드가 어디까지 실행했는지 기억해야 돌아왔을 때 이어서 실행할 수 있다.

```
Thread A: 메서드 X의 3번째 바이트코드 실행 중
    → OS가 Thread A를 일시 정지 (컨텍스트 스위칭)
    → Thread B 실행
    → 다시 Thread A로 돌아옴
    → PC Register를 보고 "3번째 바이트코드부터 이어서 실행"
```

### 네이티브 메서드 실행 시

네이티브 메서드(C/C++)는 JVM 바이트코드가 아니기 때문에, 네이티브 메서드 실행 중에는 PC Register에 **Undefined(정의되지 않음)** 값이 저장된다. 네이티브 코드의 실행 위치는 JVM이 아니라 OS와 CPU가 직접 관리한다. 이는 JVM 스펙에도 명시되어 있다.



------

## 4. 스레드 독립 영역 — Native Method Stack

Native Method Stack은 **네이티브 메서드(C/C++)**의 스택 프레임이 쌓이는 곳이다. JVM Stack은 Java 메서드를 위한 것이고, Native Method Stack은 JNI를 통해 호출된 네이티브 코드를 위한 것이다.

### 네이티브 메서드를 사용하는 이유

- **OS/하드웨어 직접 접근**: 파일 시스템, 네트워크 소켓, 스레드 생성 등 OS 기능 호출 (예: Thread.start() 내부)
- **성능이 극도로 중요한 연산**: 이미지/영상 처리, 암호화 등 C/C++이 훨씬 빠른 경우
- **기존 C/C++ 라이브러리 재사용**: 이미 검증된 네이티브 라이브러리를 Java에서 활용
- **JVM 자체 구현**: System.arraycopy(), Object.hashCode() 등 JVM 핵심 기능

### JNI (Java Native Interface)

Java 코드와 네이티브 코드 사이의 **다리(Bridge)** 역할을 하는 인터페이스이다.

```java
public class Example {
    // native 키워드로 선언 — 구현은 C/C++에 있음
    public native int hardwareAccess();
    
    static {
        System.loadLibrary("mylib");  // C/C++로 컴파일된 .dll/.so 파일 로드
    }
}
Java 코드 ──[JNI]──▶ C/C++ 코드 ──▶ OS/하드웨어
                       │
                       └── Native Method Stack에 스택 프레임 생성
```

------

## 5. 스레드 공유 영역 — Heap

Heap은 **모든 객체 인스턴스와 배열**이 저장되는 영역이다. 모든 스레드가 공유하며, **가비지 컬렉션(GC)**의 대상이 된다.

### Heap에 저장되는 것들

- **객체 인스턴스**: new 키워드로 생성된 모든 객체
- **배열**: 모든 타입의 배열
- **Static 변수** (Java 7 이후): PermGen에서 Heap으로 이동
- **String Constant Pool** (Java 7 이후): PermGen에서 Heap으로 이동



------

## 6. Generational Heap 구조

Heap은 내부적으로 **세대(Generation)**별로 나뉘어 있다. 이를 **Generational Heap**이라 한다.

```
Heap
┌─────────────────────────────────────────────┐
│  Young Generation                            │
│  ┌──────────┬──────────┬──────────┐         │
│  │  Eden    │ Survivor │ Survivor │         │
│  │          │   (S0)   │   (S1)   │         │
│  └──────────┴──────────┴──────────┘         │
├─────────────────────────────────────────────┤
│  Old Generation (Tenured)                    │
│                                              │
└─────────────────────────────────────────────┘
```

| 영역               | 설명                                                         |
| ------------------ | ------------------------------------------------------------ |
| **Eden**           | 새로 생성된 객체가 처음 할당되는 곳                          |
| **Survivor 0, 1**  | Eden에서 GC를 살아남은 객체가 이동하는 곳. 두 개가 번갈아 사용됨 |
| **Old Generation** | Young에서 여러 번 GC를 살아남은 객체가 이동 (Promotion)      |

### 세대별로 나누는 이유 — Weak Generational Hypothesis

이 설계는 경험적 관찰에 기반한다:

- **대부분의 객체는 생성 직후 금방 죽는다** → Young에서 바로 수거
- **오래 살아남은 객체는 계속 오래 산다** → Old로 이동

세대를 나누면 전체 Heap을 매번 스캔할 필요 없이, **Young 영역만 자주, 빠르게 GC**할 수 있어 효율적이다.



------

## 7. Minor GC와 객체 이동 과정

### 단계별 과정

**1단계: 최초 상태** — 새 객체가 Eden에 생성됨

```
Eden: [A] [B] [C] [D]    S0: []    S1: []    Old: []
```

**2단계: 첫 번째 Minor GC**

- GC Root에서 참조 추적 → 살아있는 객체(A, C) 판별
- 살아남은 객체는 **S0으로 이동**, Age = 1
- 죽은 객체(B, D) 제거, Eden 완전히 비워짐

```
Eden: []    S0: [A(1)] [C(1)]    S1: []    Old: []
```

**3단계: 새 객체 생성 후 두 번째 Minor GC**

- Eden의 살아남은 객체 + S0의 살아남은 객체 → 모두 **S1으로 이동**, Age +1
- S0은 완전히 비워짐

```
Eden: []    S0: []    S1: [A(2)] [E(1)]    Old: []
```

**4단계: 세 번째 Minor GC**

- Eden + S1의 살아남은 객체 → **S0으로 이동**, Age +1
- S0과 S1이 **번갈아가며** 사용됨

**5단계: Age가 임계값(기본 15)에 도달**

- Age가 임계값을 넘은 객체는 **Old Generation으로 Promotion**

### Survivor가 두 개인 이유 — 메모리 단편화(Fragmentation) 방지

한쪽 Survivor에서 다른 쪽으로 살아남은 객체만 복사하면, 복사된 쪽은 항상 빈 공간 없이 연속적으로 정렬된다. Survivor가 하나뿐이면 객체를 제거한 자리에 빈 공간이 듬성듬성 생겨 메모리 효율이 떨어진다.

### GC 유형

| GC 유형                | 대상 영역           | 특징                               |
| ---------------------- | ------------------- | ---------------------------------- |
| **Minor GC**           | Young Generation    | 자주 발생, 빠름                    |
| **Major GC (Full GC)** | Old Generation 포함 | 드물게 발생, 느림 (Stop-The-World) |

------

## 8. GC Root와 Reachability Analysis

### GC Root가 될 수 있는 것들

| GC Root                            | 설명                                                      |
| ---------------------------------- | --------------------------------------------------------- |
| **JVM Stack의 지역 변수/매개변수** | 현재 실행 중인 메서드의 스택 프레임에 있는 참조 변수      |
| **Static 변수**                    | Method Area에 저장된 클래스의 static 필드가 참조하는 객체 |
| **활성 스레드 (Active Thread)**    | 실행 중인 스레드 객체 자체                                |
| **JNI 참조**                       | 네이티브 코드(C/C++)에서 참조하고 있는 Java 객체          |
| **synchronized 락 객체**           | 현재 모니터 락을 가지고 있는 객체                         |

### Reachability Analysis 동작 방식

```
GC Root들
  │
  ├──▶ 객체 A ──▶ 객체 B ──▶ 객체 C    → A, B, C 모두 Reachable (살아있음)
  │
  └──▶ 객체 D                          → D Reachable (살아있음)
  
       객체 E ──▶ 객체 F               → E, F 모두 Unreachable (수거 대상)
       (어떤 GC Root에서도 도달 불가)
```

**핵심 포인트:** 객체끼리 서로 참조하고 있더라도(E ↔ F 순환 참조) GC Root에서 도달할 수 없으면 수거 대상이다. 이것이 과거 C++의 Reference Counting 방식과의 핵심 차이점이다.



------

## 9. 스레드 공유 영역 — Method Area

Method Area는 **클래스 수준의 메타데이터**가 저장되는 공유 영역이다.

### 저장되는 데이터

- **클래스 메타데이터**: 클래스 구조, 필드 정보, 메서드 정보
- **메서드 바이트코드**: 각 메서드의 실행 코드
- **Runtime Constant Pool**: .class 파일의 Constant Pool이 런타임에 로드된 것
- **필드/메서드의 접근 제어 정보**
- 

------

## 10. PermGen vs Metaspace (Java 7 → 8 변화)

### Java 7 이전: PermGen (Permanent Generation)

Method Area의 구현체가 PermGen이었으며, **Heap 메모리의 일부**로 관리되었다.

```
Heap
┌─────────────────────────┐
│  Young Generation        │
├─────────────────────────┤
│  Old Generation          │
├─────────────────────────┤
│  PermGen                 │  ← Method Area 구현체
│  (클래스 메타데이터,       │
│   static 변수, 상수 풀)   │
└─────────────────────────┘
```

**PermGen의 문제점:**

- **고정 크기**: JVM 시작 시 `-XX:MaxPermSize`로 크기를 지정해야 했음 (기본 64~256MB)
- **OutOfMemoryError: PermGen space**: 클래스를 많이 로드하는 애플리케이션(Spring, Hibernate 등)에서 빈번하게 발생
- **크기 예측 어려움**: 얼마나 많은 클래스가 로드될지 미리 알기 어려워서 적절한 크기 설정이 힘들었음

### Java 8 이후: Metaspace

PermGen이 제거되고 Metaspace로 대체되었다. 핵심 변화는 **Heap이 아닌 Native Memory(OS가 관리하는 메모리)**를 사용한다는 점이다.

```
Heap                          Native Memory
┌─────────────────────┐      ┌──────────────────┐
│  Young Generation    │      │  Metaspace        │  ← Method Area 구현체
├─────────────────────┤      │  (클래스 메타데이터) │
│  Old Generation      │      └──────────────────┘
└─────────────────────┘
```

**Metaspace의 개선점:**

- **자동 확장**: Native Memory를 사용하므로 OS가 허용하는 만큼 자동으로 늘어남
- **PermGen OOM 해결**: 고정 크기 제한이 사라져서 PermGen space 에러가 없어짐
- **`-XX:MaxMetaspaceSize`**: 필요하면 제한을 걸 수 있지만, 기본적으로는 제한 없음

### 데이터 이동 정리

| 항목                 | Java 7 이전 | Java 7            | Java 8 이후               |
| -------------------- | ----------- | ----------------- | ------------------------- |
| 클래스 메타데이터    | PermGen     | PermGen           | Metaspace (Native Memory) |
| Static 변수          | PermGen     | **Heap으로 이동** | Heap                      |
| String Constant Pool | PermGen     | **Heap으로 이동** | Heap                      |

**String Constant Pool이 Heap으로 이동한 이유:** PermGen에 있으면 Full GC 때만 수거 가능했지만, Heap에 있으면 일반 GC로도 수거할 수 있어 메모리 관리가 효율적이다.



------

## 11. 메모리 영역별 데이터 저장 위치

### 코드 예시

java

```java
public class Student {
    private static int totalCount = 0;       // ② static 변수
    private String name;
    private int age;
    
    public Student(String name, int age) {   // ① 클래스 메타데이터
        this.name = name;
        this.age = age;
        totalCount++;
    }
}

public class Main {
    public static void main(String[] args) {
        Student s1 = new Student("Kim", 20); // ③ 객체, ④ 참조변수, ⑤ 문자열
        int count = Student.getTotalCount();  // ⑥ 기본형 지역변수
    }
}
```

### 저장 위치 매핑

| 항목                          | 저장 위치                       | 이유                                                         |
| ----------------------------- | ------------------------------- | ------------------------------------------------------------ |
| ① Student 클래스 메타데이터   | **Method Area (Metaspace)**     | 클래스 구조, 메서드 바이트코드, 필드 정보                    |
| ② totalCount (static 변수)    | **Heap**                        | Java 7 이후 static 변수는 Heap에 저장                        |
| ③ new Student("Kim", 20) 객체 | **Heap**                        | 모든 객체 인스턴스는 Heap에 생성                             |
| ④ s1 (참조 변수)              | **Stack**                       | main() 스택 프레임의 지역 변수 배열. Heap 객체의 주소를 가짐 |
| ⑤ "Kim" (문자열 리터럴)       | **Heap (String Constant Pool)** | Java 7 이후 String Pool은 Heap에 위치                        |
| ⑥ count (기본형 지역변수)     | **Stack**                       | int 기본형은 값 자체가 스택에 직접 저장                      |



------

## 12. 메모리 관련 에러

| 에러                                  | 관련 메모리 영역        | 발생 상황                                                    |
| ------------------------------------- | ----------------------- | ------------------------------------------------------------ |
| **StackOverflowError**                | JVM Stack               | 무한 재귀 호출, 너무 깊은 메서드 호출로 스택 프레임이 Stack 용량 초과 |
| **OutOfMemoryError: Java heap space** | Heap                    | 메모리 누수로 GC가 수거하지 못하는 객체가 계속 쌓이거나, 대용량 컬렉션에 데이터를 과도하게 적재 |
| **OutOfMemoryError: Metaspace**       | Method Area (Metaspace) | 동적 프록시/클래스를 과도하게 생성, ClassLoader 누수, JSP가 매우 많은 경우 |

### Metaspace OOM 발생 예시

java

```java
// 동적 프록시를 무한히 생성
while (true) {
    Proxy.newProxyInstance(
        classLoader,
        new Class[]{MyInterface.class},
        handler
    );  // 매번 새로운 클래스가 Metaspace에 로드됨
}
→ OutOfMemoryError: Metaspace
```

**참고:** Java 7 이전이었다면 같은 상황에서 `OutOfMemoryError: PermGen space`가 발생했을 것이다.



------

## 13. JNI와 Native Method

### JNI (Java Native Interface) 구조

```
Java 코드 ──[JNI]──▶ C/C++ 코드 ──▶ OS/하드웨어
                       │
                       └── Native Method Stack에 스택 프레임 생성
```

### JNI 코드 예시

java

```java
public class Example {
    // native 키워드로 선언 — 구현은 C/C++에 있음
    public native int hardwareAccess();
    
    static {
        System.loadLibrary("mylib");  // C/C++로 컴파일된 .dll/.so 로드
    }
}
```

### 네이티브 메서드 사용 이유

- **OS/하드웨어 직접 접근**: 파일 시스템, 네트워크, 스레드 생성 등
- **성능 극대화**: C/C++이 훨씬 빠른 연산
- **기존 네이티브 라이브러리 재사용**
- **JVM 내부 구현**: System.arraycopy(), Object.hashCode() 등
- 

------

## 14. 전체 구조 종합 정리

```
JVM Runtime Data Areas

[스레드 독립 (Thread-private)] ─── 각 스레드마다 독립 생성
┌─────────────────────────────────────────────────────┐
│ ① JVM Stack          │ 스택 프레임 (지역변수, 참조변수,  │
│                       │ 오퍼랜드 스택, 프레임 데이터)     │
│ ② PC Register        │ 현재 실행 중인 바이트코드 주소    │
│                       │ (네이티브 실행 시 Undefined)     │
│ ③ Native Method Stack│ 네이티브(C/C++) 메서드 스택 프레임 │
└─────────────────────────────────────────────────────┘

[스레드 공유 (Thread-shared)] ─── 모든 스레드가 공유
┌─────────────────────────────────────────────────────┐
│ ④ Heap                                               │
│   ┌───────────────────────────────────────┐          │
│   │ Young Gen                              │          │
│   │   Eden │ Survivor 0 │ Survivor 1      │          │
│   ├───────────────────────────────────────┤          │
│   │ Old Gen (Tenured)                      │          │
│   ├───────────────────────────────────────┤          │
│   │ String Constant Pool (Java 7~)         │          │
│   │ Static 변수 (Java 7~)                  │          │
│   └───────────────────────────────────────┘          │
├─────────────────────────────────────────────────────┤
│ ⑤ Method Area                                        │
│   → Java 7 이전: PermGen (Heap 내부, 고정 크기)        │
│   → Java 8 이후: Metaspace (Native Memory, 자동 확장)  │
│   저장: 클래스 메타데이터, 메서드 바이트코드,             │
│         필드 정보, Runtime Constant Pool               │
└─────────────────────────────────────────────────────┘
```



## 🎯 면접 예상 질문

---

- **Q1. JVM 메모리 영역을 설명해주세요.**

  > JVM Runtime Data Areas는 다섯 가지 영역으로 나뉩니다. 스레드마다 독립적인 JVM Stack, PC Register, Native Method Stack이 있고, 모든 스레드가 공유하는 Heap과 Method Area가 있습니다. Stack에는 메서드의 스택 프레임(지역변수, 오퍼랜드 스택)이, Heap에는 객체와 배열이, Method Area에는 클래스 메타데이터가 저장됩니다.

  ------

  **Q2. Stack과 Heap의 차이는?**

  > Stack은 스레드마다 독립적이며 메서드의 지역 변수, 참조 변수, 기본형 값이 저장됩니다. LIFO 구조로 메서드 호출/리턴 시 자동으로 할당/해제됩니다. Heap은 모든 스레드가 공유하며 객체 인스턴스와 배열이 저장됩니다. GC에 의해 관리되며, 참조 변수는 Stack에 있지만 실제 객체는 Heap에 있어 참조로 연결됩니다.

  ------

  **Q3. Heap이 세대별로 나뉘는 이유는?**

  > Weak Generational Hypothesis에 기반합니다. 대부분의 객체는 생성 직후 금방 죽고, 오래 살아남은 객체는 계속 오래 삽니다. Young Generation과 Old Generation으로 나누면 전체 Heap을 매번 스캔할 필요 없이 Young 영역만 자주, 빠르게 GC할 수 있어 효율적입니다.

  ------

  **Q4. Minor GC에서 객체가 이동하는 과정을 설명해주세요.**

  > 새 객체는 Eden에 생성됩니다. Minor GC 발생 시 GC Root에서 참조 추적으로 살아있는 객체를 판별하고, Eden의 살아남은 객체를 Survivor 영역으로 이동시키며 Age를 1 증가시킵니다. 다음 Minor GC 때는 Eden과 현재 Survivor의 살아남은 객체를 다른 Survivor로 복사하고, 이전 Survivor를 비웁니다. 이 과정을 반복하다 Age가 임계값(기본 15)에 도달하면 Old Generation으로 Promotion됩니다.

  ------

  **Q5. Survivor가 왜 두 개인가요?**

  > 메모리 단편화(Fragmentation) 방지를 위해서입니다. 한쪽 Survivor에서 다른 쪽으로 살아남은 객체만 복사하면, 복사된 쪽은 항상 빈 공간 없이 연속적으로 정렬됩니다. Survivor가 하나뿐이면 객체 제거 후 빈 공간이 듬성듬성 생겨 메모리 효율이 떨어집니다.

  ------

  **Q6. GC Root가 될 수 있는 것은?**

  > JVM Stack의 지역 변수/매개변수, static 변수, 활성 스레드 객체, JNI 참조, synchronized로 락이 걸린 객체가 GC Root가 됩니다. GC는 이 Root들에서 참조 체인을 따라가며 도달 가능한 객체를 살아있는 것으로 판별하고, 도달 불가능한 객체를 수거합니다. 순환 참조가 있더라도 GC Root에서 도달할 수 없으면 수거 대상입니다.

  ------

  **Q7. PermGen과 Metaspace의 차이는?**

  > Java 7 이전의 PermGen은 Heap 내부에 위치하며 고정 크기였습니다. 클래스를 많이 로드하면 OutOfMemoryError: PermGen space가 빈번했습니다. Java 8에서 Metaspace로 대체되었으며, 핵심 변화는 Heap이 아닌 Native Memory(OS가 관리하는 메모리)를 사용한다는 점입니다. 자동 확장이 가능해져서 PermGen의 고정 크기 문제가 해결되었습니다.

  ------

  **Q8. Java 7에서 8로 넘어오면서 변경된 메모리 구조는?**

  > PermGen이 제거되고 Metaspace가 도입되어 클래스 메타데이터가 Native Memory에 저장됩니다. Static 변수와 String Constant Pool은 Java 7부터 이미 Heap으로 이동했습니다. String Pool이 Heap으로 옮겨진 이유는 PermGen에서는 Full GC 때만 수거 가능했지만, Heap에서는 일반 GC로도 수거할 수 있어 효율적이기 때문입니다.

  ------

  **Q9. StackOverflowError와 OutOfMemoryError의 차이는?**

  > StackOverflowError는 JVM Stack에서 발생하며, 무한 재귀나 너무 깊은 메서드 호출로 스택 프레임이 Stack 용량을 초과할 때 발생합니다. OutOfMemoryError: Java heap space는 Heap에서 발생하며, 메모리 누수나 대용량 데이터로 Heap이 가득 찰 때 발생합니다. OutOfMemoryError: Metaspace는 동적 클래스를 과도하게 생성하거나 ClassLoader 누수가 있을 때 발생합니다.

  ------

  **Q10. PC Register가 스레드마다 독립적이어야 하는 이유는?**

  > 멀티스레드 환경에서 각 스레드는 서로 다른 위치의 코드를 실행합니다. 컨텍스트 스위칭이 발생할 때 각 스레드가 어디까지 실행했는지 기억해야 돌아왔을 때 이어서 실행할 수 있습니다. 네이티브 메서드 실행 중에는 JVM 바이트코드가 아니므로 PC Register에 Undefined 값이 저장되며, 네이티브 코드의 실행 위치는 OS가 직접 관리합니다.

  ------

  **Q11. 객체의 참조 변수와 실제 객체는 각각 어디에 저장되나요?**

  > 참조 변수(s1, s2 등)는 Stack의 지역 변수 배열에 저장되며, 실제 객체 데이터는 Heap에 저장됩니다. 참조 변수에는 Heap에 있는 객체의 메모리 주소가 담겨 있어 이를 통해 객체에 접근합니다. 기본형(int, boolean 등)은 값 자체가 Stack에 직접 저장됩니다.

  ------

  **Q12. JNI(Java Native Interface)란 무엇이고, 왜 필요한가요?**

  > JNI는 Java 코드와 네이티브 코드(C/C++) 사이의 다리 역할을 하는 인터페이스입니다. OS/하드웨어 직접 접근, 성능이 극도로 중요한 연산, 기존 C/C++ 라이브러리 재사용, JVM 내부 구현 등을 위해 필요합니다. JNI를 통해 호출된 네이티브 메서드의 스택 프레임은 JVM Stack이 아닌 Native Method Stack에 쌓입니다.
