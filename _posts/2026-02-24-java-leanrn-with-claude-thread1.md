---
title: 자바 쓰레드 파헤쳐보기
date: 2026-02-24 17:35:57 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 쓰레드]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : Claude 문답형식을 이용한 Thread 학습
- 목표 : Multi-Thread 환경에서 발생될 문제에 대해서 학습한다.

## 📝 본문

#  volatile, happens-before, 가시성



##  volatile과 가시성

### 가시성(Visibility) 문제란?

각 스레드는 CPU 캐시(레지스터, L1/L2 캐시 등)에 변수의 값을 로컬로 캐싱할 수 있다. 한 스레드가 변수를 변경하더라도, 그 값이 메인 메모리에 즉시 반영(flush)되지 않거나, 다른 스레드가 자신의 캐시에서 이전 값을 계속 읽을 수 있다.

### 문제 코드 예시

```java
public class SharedFlag {
    private boolean running = true;

    public void stop() {
        running = false;
    }

    public void run() {
        while (running) {
            // do work
        }
        System.out.println("Stopped!");
    }
}
```

Thread A가 `run()`을 실행 중이고, Thread B가 `stop()`을 호출해도 Thread A의 while 루프가 영원히 종료되지 않을 수 있다. Thread B가 `running = false`로 변경해도 Thread A는 자신의 CPU 캐시에서 계속 `true`를 읽기 때문이다.

### volatile의 메커니즘

`volatile`은 "스레드에게 알려주는 것"이 아니라 **메모리 접근 규칙을 강제**하는 것이다.

**volatile 쓰기(write) 시:**

- 해당 변수의 값을 CPU 캐시에만 남기지 않고 **메인 메모리로 flush(반영)**
- volatile 쓰기 **이전의 모든 변수 변경도 함께** 메인 메모리에 반영

**volatile 읽기(read) 시:**

- CPU 캐시의 값을 무시하고 **메인 메모리에서 최신 값을 읽음 (invalidate)**
- volatile 읽기 **이후의 모든 변수 읽기도** 메인 메모리에서 가져옴

하드웨어 수준에서 JVM이 **메모리 배리어(memory barrier/fence)** 를 삽입한다:

- volatile 쓰기 → **StoreStore + StoreLoad 배리어**
- volatile 읽기 → **LoadLoad + LoadStore 배리어**



##  happens-before 관계

### 핵심 개념

happens-before는 JMM(Java Memory Model)에서 정의하는 **메모리 가시성 보장 규칙**이다. A happens-before B이면, A의 결과가 B에게 반드시 보인다.

### volatile을 통한 happens-before 전파

```java
volatile boolean ready = false;
int value = 0;

// Thread A
value = 42;
ready = true;    // volatile 쓰기

// Thread B
if (ready) {         // volatile 읽기
    System.out.println(value);  // 반드시 42 출력
}
```

`value`는 volatile이 아님에도, Thread B에서 `ready == true`를 읽었다면 `value`가 **반드시 42로 보인다.**

**이유:**

1. `value = 42` → `ready = true` (volatile 쓰기) : **프로그램 순서 규칙**
2. `ready = true` (volatile 쓰기) → `if (ready)` (volatile 읽기) : **volatile 규칙**
3. 1번 + 2번 = **이행성(transitivity)**

> volatile 변수를 통해 **간접적으로 happens-before 관계가 전파**되어, 해당 변수뿐만 아니라 **그 이전의 모든 쓰기까지 가시성이 보장**된다.

### happens-before를 성립시키는 주요 규칙

| 규칙                      | 설명                                                  |
| ------------------------- | ----------------------------------------------------- |
| **프로그램 순서 규칙**    | 같은 스레드 내에서 코드 순서대로 happens-before       |
| **Monitor Lock 규칙**     | synchronized의 unlock → 같은 락의 다음 lock           |
| **volatile 규칙**         | volatile 쓰기 → 같은 변수의 volatile 읽기             |
| **Thread Start 규칙**     | thread.start() → 해당 스레드 내의 모든 액션           |
| **Thread Join 규칙**      | 스레드의 모든 액션 → 다른 스레드의 thread.join() 반환 |
| **이행성 (Transitivity)** | A → B이고 B → C이면, A → C                            |

### final 필드의 보장

`final`은 happens-before와 별도의 보장이다. 생성자에서 final 필드에 값을 쓰면, 생성자 완료 후 그 객체의 참조를 얻는 모든 스레드에게 final 필드 값이 보인다. 단, **this가 생성자에서 누출되지 않아야** 한다.





##  원자성과 volatile의 한계

### volatile은 원자성을 보장하지 않는다

```java
public class Counter {
    private volatile int count = 0;

    public void increment() {
        count++;  // 이것은 스레드 안전하지 않다!
    }
}
```

두 스레드가 `increment()`를 1000번씩 호출해도 최종 `count`가 2000이 **보장되지 않는다.**

`count++`은 세 단계로 나뉜다:

1. **Read**: 메인 메모리에서 count 값을 읽음 (예: 5)
2. **Modify**: 읽은 값에 1을 더함 (5 → 6)
3. **Write**: 결과를 다시 메인 메모리에 씀

이 세 단계가 **원자적(atomic)이지 않기 때문에** 다음과 같은 상황이 발생한다:

```
Thread A: read(5) → modify(6)
Thread B: read(5) → modify(6) → write(6)
Thread A: write(6)
// 2번 증가했지만 결과는 1만 증가 → Lost Update (갱신 손실)
```





##  CAS (Compare-And-Swap)

### 개념

CAS는 **락 없이 원자적 연산을 수행하는 기법**이다.

> "내가 마지막으로 읽은 값이 아직 그대로라면, 새 값으로 바꿔줘. 아니면 실패!"

세 가지 인자:

- **기대값 (expected)**: 내가 읽었던 값
- **새 값 (new)**: 바꾸고 싶은 값
- **메모리 위치**: 실제 변수

### 동작 예시

```
count = 5인 상태

Thread A: CAS(기대값=5, 새값=6) → 메모리 확인: 5 맞네? → 성공! count=6
Thread B: CAS(기대값=5, 새값=6) → 메모리 확인: 6이네? 5 아님 → 실패!
Thread B: (재시도) 다시 읽기 → CAS(기대값=6, 새값=7) → 성공!
```

### AtomicInteger 내부 로직 (간소화)

```java
do {
    int expected = current;        // 현재 값 읽기
    int newValue = expected + 1;   // 새 값 계산
} while (!CAS(expected, newValue)); // 실패하면 반복 (spin)
```

### synchronized vs CAS 비교

| 항목         | synchronized                       | CAS (AtomicInteger 등)            |
| ------------ | ---------------------------------- | --------------------------------- |
| 방식         | 락을 잡고 다른 스레드를 **블로킹** | 락 없이 **재시도 (non-blocking)** |
| 경합 낮을 때 | 락 획득/해제 오버헤드 있음         | 매우 빠름                         |
| 경합 높을 때 | 대기하지만 안정적                  | 계속 실패+재시도 → CPU 낭비 가능  |
| 복잡한 연산  | 여러 변수를 한번에 보호 가능       | 단일 변수에 대한 연산에 적합      |





##  volatile 적합/부적합 케이스

### 적합한 경우 — 단순 읽기/쓰기 (원자적 연산)

- `flag = true` (boolean 상태 플래그)
- `a = 10` → `a = 12` (단순 대입)
- 한 스레드만 쓰고, 나머지는 읽기만 하는 패턴

### 적합하지 않은 경우 — 복합 연산 (비원자적)

- `count++` (read-modify-write)
- `if (a == 0) a = 1` (check-then-act)

### 보충: long과 double

Java에서 `long`과 `double`은 64비트인데, 32비트 환경에서 단순 대입도 원자적이지 않을 수 있다 (두 번의 32비트 쓰기로 나뉠 수 있음). `volatile long`, `volatile double`을 쓰면 단순 대입의 원자성까지 보장받는다.





##  DCL 패턴과 재정렬

### Double-Checked Locking (DCL) 패턴

```java
public class Singleton {
    private static Singleton instance;  // volatile 없음 → 문제!

    public static Singleton getInstance() {
        if (instance == null) {                    // (1)
            synchronized (Singleton.class) {
                if (instance == null) {             // (2)
                    instance = new Singleton();     // (3)
                }
            }
        }
        return instance;
    }
}
```

### 문제: instance = new Singleton()의 재정렬

이 한 줄은 실제로 세 단계로 나뉜다:

1. **메모리 할당** — 힙에 Singleton 크기만큼 공간 확보
2. **생성자 실행** — 그 메모리 공간에 객체를 초기화
3. **참조 대입** — instance 변수가 그 메모리 주소를 가리킴

JIT/CPU의 재정렬로 1 → **3** → **2** 순서가 되면:

```
Thread A: 메모리 할당 → instance에 주소 대입 → (아직 생성자 실행 안 됨)
Thread B: if (instance == null) ← (1)번 체크에서 null이 아님!
          → synchronized 블록 진입 안 하고 바로 return instance
```

Thread B가 받은 instance는 **메모리는 할당됐지만 생성자가 실행되지 않은 불완전한 객체**다. NPE가 발생하거나 필드가 기본값(0, null)인 상태로 사용될 수 있다.

### 해결: volatile 추가

```java
private static volatile Singleton instance;
```

volatile을 붙이면 재정렬이 방지되어 1 → 2 → 3 순서가 보장되고, happens-before 관계가 성립해서 다른 스레드가 완전히 초기화된 객체를 보게 된다.



##  가시성 · 원자성 · 순서 보장 종합 비교

### 세 가지 핵심 개념

| 개념                     | 정의                                           |
| ------------------------ | ---------------------------------------------- |
| **가시성 (Visibility)**  | 한 스레드의 쓰기가 다른 스레드에게 보이는가    |
| **원자성 (Atomicity)**   | 연산이 중간 상태 없이 하나의 단위로 실행되는가 |
| **순서 보장 (Ordering)** | 코드의 실행 순서가 재정렬되지 않고 보장되는가  |

### 보장 범위 비교

| 개념      | volatile | synchronized | Atomic (CAS) |
| --------- | -------- | ------------ | ------------ |
| 가시성    | ✅ 보장   | ✅ 보장       | ✅ 보장       |
| 원자성    | ❌ 미보장 | ✅ 보장       | ✅ 보장       |
| 순서 보장 | ✅ 보장   | ✅ 보장       | ✅ 보장       |





## 🎯 면접 예상 질문

###  volatile, happens-before, 가시성

---

**Q1. volatile이 없는 변수를 멀티스레드에서 공유하면 어떤 문제가 생기나요?**

> 가시성(visibility) 문제가 발생합니다. 각 스레드는 CPU 캐시에 변수의 값을 로컬로 캐싱하므로, 한 스레드가 변수를 변경하더라도 다른 스레드가 자신의 캐시에서 이전 값을 계속 읽을 수 있습니다. 예를 들어, boolean 플래그를 사용한 while 루프가 영원히 종료되지 않을 수 있습니다.

---

**Q2. volatile은 정확히 어떻게 가시성을 보장하나요?**

> volatile 쓰기 시 해당 변수의 값을 메인 메모리로 flush하고, volatile 읽기 시 CPU 캐시를 무시하고 메인 메모리에서 최신 값을 읽습니다. 하드웨어 수준에서는 JVM이 메모리 배리어(memory barrier)를 삽입하여 이를 보장합니다. volatile 쓰기에는 StoreStore + StoreLoad 배리어가, volatile 읽기에는 LoadLoad + LoadStore 배리어가 삽입됩니다.

---

**Q3. happens-before란 무엇인가요? volatile과 어떤 관계인가요?**

> happens-before는 JMM에서 정의하는 메모리 가시성 보장 규칙입니다. A happens-before B이면, A의 결과가 B에게 반드시 보입니다. volatile의 경우, volatile 쓰기는 같은 변수의 이후 volatile 읽기보다 happens-before 관계를 가집니다. 중요한 점은 이행성(transitivity)에 의해 volatile 쓰기 이전의 모든 변수 변경까지 volatile 읽기 이후에 보인다는 것입니다.

---

**Q4. volatile은 원자성을 보장하나요?**

> 아닙니다. volatile은 가시성과 순서 보장만 제공하고, 원자성은 보장하지 않습니다. `count++`같은 read-modify-write 복합 연산은 세 단계로 나뉘기 때문에 Lost Update가 발생할 수 있습니다. 원자성이 필요하면 synchronized나 AtomicInteger(CAS 기반)를 사용해야 합니다.

---

**Q5. CAS(Compare-And-Swap)란 무엇인가요?**

> 락 없이 원자적 연산을 수행하는 기법입니다. "내가 마지막으로 읽은 값(기대값)이 아직 그대로라면 새 값으로 바꾸고, 아니면 실패"하는 방식으로 동작합니다. 실패하면 현재 값을 다시 읽고 재시도합니다(spin). 경합이 적을 때는 synchronized보다 빠르지만, 경합이 심하면 계속 재시도하면서 CPU를 낭비할 수 있습니다.

---

**Q6. volatile은 언제 쓰기 적합하고, 언제 부적합한가요?**

> 단순 읽기/쓰기(원자적 연산)에 적합합니다. 예를 들어 boolean 상태 플래그, 단순 대입(a = 10 → a = 12), 한 스레드만 쓰고 나머지는 읽기만 하는 패턴 등입니다. count++같은 복합 연산(read-modify-write)이나 check-then-act 패턴에는 부적합합니다.

---

**Q7. DCL(Double-Checked Locking) 패턴에서 volatile이 필요한 이유는?**

> `instance = new Singleton()`은 메모리 할당 → 생성자 실행 → 참조 대입의 세 단계로 나뉩니다. JIT/CPU의 재정렬로 메모리 할당 → 참조 대입 → 생성자 실행 순서가 될 수 있으며, 이 경우 다른 스레드가 초기화되지 않은 불완전한 객체를 사용하게 됩니다. volatile을 붙이면 재정렬이 방지되고 happens-before 관계가 성립하여 완전히 초기화된 객체가 보장됩니다.

---

**Q8. 가시성, 원자성, 순서 보장의 차이는? volatile은 어떤 것을 보장하나요?**

> 가시성은 한 스레드의 쓰기가 다른 스레드에게 보이는지, 원자성은 연산이 중간 상태 없이 하나의 단위로 실행되는지, 순서 보장은 코드 실행 순서가 재정렬되지 않는지입니다. volatile은 가시성과 순서 보장은 제공하지만, 원자성은 보장하지 않습니다.
