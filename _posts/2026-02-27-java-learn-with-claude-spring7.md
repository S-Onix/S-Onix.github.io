---
title: Spring 깊이 이해하기 7편 - AOP (Aspect-Oriented Programming)
date: 2026-03-04 17:28:23 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : AOP 이해하기

## 📝 본문

## 1. 횡단 관심사(Cross-Cutting Concerns) — AOP가 필요한 이유

비즈니스 로직을 개발하다 보면, 핵심 기능과 상관없는 코드가 여러 클래스에 반복됩니다.

```java
@Service
public class OrderService {
    public void createOrder(OrderRequest request) {
        long start = System.currentTimeMillis();     // 🔁 성능 측정
        log.info("createOrder 시작");                  // 🔁 로깅
        checkAuth();                                   // 🔁 인증 확인

        Order order = Order.from(request);             // ✅ 진짜 비즈니스 로직
        orderRepository.save(order);                   // ✅ 진짜 비즈니스 로직

        log.info("createOrder 끝");                    // 🔁 로깅
        long end = System.currentTimeMillis();         // 🔁 성능 측정
    }
}
```

`PaymentService`, `UserService`에도 똑같은 로깅, 성능 측정, 인증 코드가 반복됩니다. 이렇게 여러 클래스를 가로질러 나타나는 관심사를 **Cross-Cutting Concerns(횡단 관심사)**라고 합니다.

```
             OrderService   PaymentService   UserService
로깅           🔁              🔁               🔁      ← 횡단 관심사
성능 측정       🔁              🔁               🔁      ← 횡단 관심사
트랜잭션        🔁              🔁               🔁      ← 횡단 관심사
비즈니스 로직   주문 생성        결제 처리         회원 가입  ← 핵심 관심사
```

------



## 2. AOP란?

횡단 관심사를 비즈니스 로직에서 **분리하여 모듈화**하는 프로그래밍 패러다임입니다.

피자 가게로 비유하면, 요리사 10명 모두에게 "요리 전에 손 씻고, 시간 기록하세요"라고 하는 대신, **주방 관리자를 한 명 고용**해서 자동으로 처리하게 하는 것입니다. 요리사들은 요리(비즈니스 로직)에만 집중하면 됩니다.

AOP를 적용하면 코드가 이렇게 분리됩니다.

```java
// 비즈니스 로직 — 핵심만 남음
@Service
public class OrderService {
    public void createOrder(OrderRequest request) {
        Order order = Order.from(request);
        orderRepository.save(order);
    }
}

// 횡단 관심사 — 별도로 분리
@Aspect
@Component
public class LoggingAspect {
    @Around("execution(* com.example.service.*.*(..))")
    public Object log(ProceedingJoinPoint joinPoint) throws Throwable {
        log.info("{} 시작", joinPoint.getSignature());
        Object result = joinPoint.proceed();
        log.info("{} 끝", joinPoint.getSignature());
        return result;
    }
}
```

------



## 3. AOP 핵심 용어 5가지

### ① Aspect — 주방 관리자

횡단 관심사를 모듈화한 클래스입니다. "무엇을(Advice)" "어디에(Pointcut)" 적용할지를 하나로 묶은 단위입니다.

```java
@Aspect      // "나는 횡단 관심사를 모듈화한 클래스야"
@Component   // Spring Bean으로도 등록해야 동작함
public class LoggingAspect { ... }
```



### ② Advice — 관리자가 하는 실제 행동

횡단 관심사의 실제 실행 코드입니다. 실행 시점에 따라 5종류가 있습니다.

| Advice 종류         | 실행 시점                       | 피자 가게 비유                          |
| ------------------- | ------------------------------- | --------------------------------------- |
| **@Before**         | 메서드 실행 전                  | 요리 시작 전에 손 씻기                  |
| **@After**          | 메서드 실행 후 (성공/실패 무관) | 요리 끝나고 주방 정리 (항상)            |
| **@AfterReturning** | 메서드 정상 완료 후             | 요리 성공 시 완성 사진 찍기             |
| **@AfterThrowing**  | 메서드 예외 발생 후             | 요리 실패 시 사고 보고서 작성           |
| **@Around**         | 메서드 실행 전후 모두           | 가장 강력. 위의 모든 것을 다 할 수 있음 |

```java
@Before("execution(* com.example.service.*.*(..))")
public void before(JoinPoint joinPoint) {
    log.info("시작: {}", joinPoint.getSignature());
}

@AfterReturning(pointcut = "execution(* com.example.service.*.*(..))", returning = "result")
public void afterReturn(JoinPoint joinPoint, Object result) {
    log.info("성공: {} → 결과: {}", joinPoint.getSignature(), result);
}

@AfterThrowing(pointcut = "execution(* com.example.service.*.*(..))", throwing = "ex")
public void afterThrow(JoinPoint joinPoint, Exception ex) {
    log.error("실패: {} → {}", joinPoint.getSignature(), ex.getMessage());
}

@After("execution(* com.example.service.*.*(..))")
public void after(JoinPoint joinPoint) {
    log.info("완료(항상): {}", joinPoint.getSignature());
}

@Around("execution(* com.example.service.*.*(..))")
public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
    log.info("전");
    Object result = joinPoint.proceed();   // 원래 메서드 실행
    log.info("후");
    return result;
}
```

**Advice 실행 순서:**

```
@Around (시작 부분)
  → @Before
    → [실제 메서드 실행]
  → @AfterReturning (성공 시) 또는 @AfterThrowing (실패 시)
  → @After (항상)
@Around (끝 부분)
```



### ③ Pointcut — 어디에 CCTV를 설치할 것인가

Advice를 어디에 적용할지 정의하는 표현식입니다.

**execution 방식 (패키지/클래스/메서드 기준)**

```java
execution(접근제어자? 반환타입 패키지.클래스.메서드(파라미터))

execution(* com.example.service.*.*(..))             // service 패키지의 모든 메서드
execution(* com.example.service.OrderService.*(..))  // OrderService의 모든 메서드
execution(* *Service.create*(..))                    // create로 시작하는 메서드
```

**@annotation 방식 (어노테이션 기준, 실무에서 더 자주 사용)**

```java
@Around("@annotation(LogExecutionTime)")                          // 값 접근 불필요 시
@Around("@annotation(com.example.annotation.LogExecutionTime)")   // 풀네임도 가능
@Around("@annotation(retry)")                                     // 파라미터 바인딩 (값 접근 필요 시)
```

`@annotation(retry)`에서 `retry`는 Advice 메서드의 **파라미터 이름**과 매칭되는 바인딩 변수입니다.

```java
@Around("@annotation(retry)")            // ← "retry"라는 이름의 파라미터를 찾아
public Object doRetry(
    ProceedingJoinPoint joinPoint,
    Retry retry                          // ← 이 파라미터와 매칭. 타입이 Retry → @Retry 적용
) throws Throwable {
    int max = retry.maxAttempts();       // 어노테이션에 설정된 값 사용 가능!
}
```



### ④ JoinPoint — Advice가 끼어드는 실행 지점

Spring AOP에서 JoinPoint는 항상 **메서드 실행 시점**입니다. JoinPoint 객체를 통해 실행 중인 메서드의 정보를 얻을 수 있습니다.

java

```java
joinPoint.getSignature()   // 메서드 시그니처 (이름, 파라미터 타입)
joinPoint.getArgs()        // 전달된 인자값들
joinPoint.getTarget()      // 실제 대상 객체
joinPoint.getThis()        // 프록시 객체
```

`@Around`에서만 사용하는 `ProceedingJoinPoint`는 JoinPoint를 상속하며, `proceed()` 메서드가 추가되어 있습니다.

```
JoinPoint                → getSignature(), getArgs(), getTarget()
  └── ProceedingJoinPoint → 위의 모든 것 + proceed()
```

**proceed()에 대해:**

- `@Around`에서만 사용하며, 호출해야 원래 메서드가 실행됩니다
- 호출하지 않으면 원래 메서드가 아예 실행되지 않습니다 (캐시 등에서 의도적으로 활용 가능)
- 원래 메서드에 반환값이 있다면 `return result`도 필수입니다
- `@Before`, `@After` 등에서는 Spring이 알아서 원래 메서드를 실행하므로 proceed() 불필요



### ⑤ Weaving — Aspect를 실제로 적용하는 과정

Weaving은 Aspect(횡단 관심사 코드)를 대상 객체에 **실제로 결합하는 과정**입니다. 피자 가게에서 주방 관리자를 주방에 배치하는 행위 자체에 해당합니다.

Weaving이 일어나는 시점에 따라 3가지로 나뉩니다.

**① 컴파일 타임 Weaving (Compile-Time Weaving)**

```
소스 코드(.java) → [컴파일러 + AspectJ 컴파일러] → 바이트코드(.class)
                                                    ↑ AOP 코드가 직접 삽입됨
```

`.java`를 `.class`로 컴파일하는 시점에 Aspect 코드를 바이트코드에 직접 삽입합니다. AspectJ의 특수 컴파일러(`ajc`)가 필요합니다. 원본 코드 자체가 변경되므로 성능 오버헤드가 없지만, 별도 컴파일러 설정이 필요합니다.

**② 로드 타임 Weaving (Load-Time Weaving)**

```
바이트코드(.class) → [ClassLoader가 메모리에 적재하는 시점] → 변경된 클래스
                                                              ↑ 적재하면서 AOP 코드 삽입
```

JVM이 클래스를 메모리에 로딩하는 시점에 바이트코드를 조작하여 Aspect를 적용합니다. Java Agent(`-javaagent`)를 설정해야 합니다. 컴파일러 변경 없이 사용 가능하지만, 클래스 로딩 시 약간의 지연이 있습니다.

**③ 런타임 Weaving (Runtime Weaving) — Spring AOP가 사용하는 방식**

```
[Bean 생성 시점]
  원래 객체(OrderService) 생성
    ↓
  AOP 대상인지 확인
    ↓
  Proxy 객체(OrderService$$CGLIB) 생성
    ↓
  Container에 Proxy를 Bean으로 등록
    ↓
  호출자 → [Proxy] → Advice 실행 → [원래 객체] → Advice 실행 → 반환
```

애플리케이션 실행 중에 Proxy 객체를 동적으로 생성하여 Aspect를 적용합니다. **Spring AOP는 이 방식만 사용합니다.** 별도 컴파일러나 Agent가 필요 없어 가장 쉽지만, Proxy를 거치는 오버헤드가 있고, 메서드 실행 JoinPoint만 지원합니다.

**3가지 비교:**

|                     | 컴파일 타임             | 로드 타임               | 런타임 (Spring AOP)    |
| ------------------- | ----------------------- | ----------------------- | ---------------------- |
| **시점**            | 컴파일 시               | 클래스 로딩 시          | 실행 중 (Bean 생성 시) |
| **방식**            | 바이트코드 직접 수정    | 로딩 시 바이트코드 조작 | Proxy 객체 생성        |
| **도구**            | AspectJ 컴파일러(ajc)   | Java Agent              | Spring이 자동 처리     |
| **성능**            | 오버헤드 없음           | 로딩 시 약간 지연       | Proxy 호출 오버헤드    |
| **JoinPoint**       | 메서드, 필드, 생성자 등 | 메서드, 필드, 생성자 등 | 메서드 실행만          |
| **Self-Invocation** | ✅ 동작함                | ✅ 동작함                | ❌ 동작 안 함           |
| **설정 난이도**     | 어려움                  | 보통                    | 쉬움                   |

실무에서는 Spring AOP(런타임 Weaving)로 거의 대부분 해결됩니다. AspectJ(컴파일/로드 타임)는 Self-Invocation이 반드시 필요하거나, 필드 접근 감시 등 고급 기능이 필요한 특수한 경우에만 사용합니다.

------



## 4. Spring AOP의 동작 원리 — Proxy 패턴

Spring AOP는 **Proxy 패턴**으로 동작합니다. Bean을 생성할 때, AOP 대상인 Bean은 원래 객체 대신 **Proxy 객체**를 Container에 등록합니다.

```
호출자 → [Proxy 객체] → Advice(Before) → [실제 객체의 메서드] → Advice(After) → 반환
```

```java
@Service
public class OrderService {
    @Transactional
    public void createOrder() { ... }
}

// 실제로 Container에 등록되는 것:
// OrderService$$SpringCGLIB (Proxy) ← 이게 Bean으로 등록됨
//     └── 내부에 진짜 OrderService를 감싸고 있음
```



**Proxy 생성 방식 2가지:**

|                        | JDK Dynamic Proxy               | CGLIB Proxy          |
| ---------------------- | ------------------------------- | -------------------- |
| **기반**               | 인터페이스                      | 클래스 상속          |
| **조건**               | 대상이 인터페이스를 구현해야 함 | 인터페이스 없어도 됨 |
| **Spring Boot 기본값** | ❌                               | ✅ (기본값)           |

------



## 5. Self-Invocation 문제 — 면접 단골 질문

같은 클래스 내에서 메서드를 호출하면 Proxy를 거치지 않아 AOP가 동작하지 않는 문제입니다.

```java
@Service
public class OrderService {

    @Transactional
    public void createOrder() { ... }     // 트랜잭션 적용됨

    public void bulkCreate(List<OrderRequest> requests) {
        for (OrderRequest req : requests) {
            this.createOrder();            // 🚫 트랜잭션 적용 안 됨!
        }
    }
}
외부에서 호출:  호출자 → [Proxy] → createOrder()     ← AOP 적용 ✅
내부에서 호출:  bulkCreate() → this.createOrder()     ← Proxy 안 거침 ❌
```



**해결 방법 (권장): 별도 클래스로 분리**

```java
@Service
public class OrderService {
    private final OrderCreator orderCreator;

    public void bulkCreate(List<OrderRequest> requests) {
        for (OrderRequest req : requests) {
            orderCreator.createOrder(req);   // 외부 Bean 호출 → Proxy 거침 ✅
        }
    }
}

@Service
public class OrderCreator {
    @Transactional
    public void createOrder(OrderRequest request) { ... }
}
```

Self-Invocation 문제가 발생하는 근본 원인은 Spring AOP가 **런타임 Weaving(Proxy 방식)**을 사용하기 때문입니다. AspectJ의 컴파일 타임/로드 타임 Weaving에서는 바이트코드 자체에 AOP 코드가 삽입되므로 이 문제가 발생하지 않습니다.

------



## 6. @Transactional — AOP의 대표적 활용

`@Transactional`은 Spring에서 가장 많이 사용되는 AOP 기능입니다. 개발자가 트랜잭션 시작/커밋/롤백 코드를 직접 쓰지 않아도 AOP Proxy가 자동으로 처리합니다.

```java
@Transactional
public void createOrder(OrderRequest request) {
    orderRepository.save(order);           // INSERT
    paymentService.processPayment(order);  // 결제 처리
    // 여기서 예외 발생하면? → INSERT도 자동 롤백!
}
```

실제로 Proxy가 하는 일은 다음과 같습니다.

```java
// Proxy 내부 동작 (개념적 표현)
public void createOrder_proxy(OrderRequest request) {
    TransactionStatus tx = transactionManager.getTransaction();
    try {
        target.createOrder(request);       // 진짜 메서드 실행
        transactionManager.commit(tx);     // 성공 시 커밋
    } catch (RuntimeException e) {
        transactionManager.rollback(tx);   // 실패 시 롤백
        throw e;
    }
}
```



### @Transactional 주요 옵션

```java
@Transactional(
    readOnly = true,                           // 읽기 전용 (SELECT 최적화)
    propagation = Propagation.REQUIRED,        // 전파 옵션 (기본값)
    isolation = Isolation.READ_COMMITTED,      // 격리 수준
    rollbackFor = Exception.class,             // 어떤 예외에서 롤백할지
    timeout = 30                               // 타임아웃 (초)
)
```



### Propagation (전파 옵션) — 실무에서 중요한 것 2가지

| 전파 옵션             | 설명                                             |
| --------------------- | ------------------------------------------------ |
| **REQUIRED** (기본값) | 기존 트랜잭션이 있으면 참여, 없으면 새로 생성    |
| **REQUIRES_NEW**      | 항상 새 트랜잭션 생성, 기존 트랜잭션은 잠시 중단 |

```java
@Transactional  // REQUIRED (기본)
public void createOrder(OrderRequest request) {
    orderRepository.save(order);
    notificationService.sendNotification(order);
}

@Transactional(propagation = Propagation.REQUIRES_NEW)  // 별도 트랜잭션
public void sendNotification(Order order) {
    // 이 트랜잭션이 실패해도 createOrder의 트랜잭션에 영향 없음
}
```



### ⚠️ Checked Exception은 기본적으로 롤백하지 않음

Spring `@Transactional`은 기본적으로 **RuntimeException과 Error에서만 롤백**합니다.

```java
@Transactional
public void createOrder() throws IOException {
    orderRepository.save(order);
    throw new IOException("파일 에러");   // 🚫 롤백 안 됨! (Checked Exception)
}

// 해결: rollbackFor 지정
@Transactional(rollbackFor = Exception.class)   // 모든 예외에서 롤백
public void createOrder() throws IOException { ... }
```

------



## 7. AOP 만드는 방법 — 실전 코드

### 기본 3단계

```
Step 1: spring-boot-starter-aop 의존성 추가
Step 2: @Aspect + @Component 클래스 생성
Step 3: Advice(@Around 등) + Pointcut(어디에 적용할지) 작성
```



### 방법 A: 패키지 전체에 적용 (execution 방식)

```java
@Aspect
@Component
public class ExecutionTimeAspect {

    private static final Logger log = LoggerFactory.getLogger(ExecutionTimeAspect.class);

    @Around("execution(* com.example.service.*.*(..))")
    public Object measureTime(ProceedingJoinPoint joinPoint) throws Throwable {
        long start = System.currentTimeMillis();
        log.info("[시작] {}", joinPoint.getSignature().toShortString());

        Object result = joinPoint.proceed();

        long duration = System.currentTimeMillis() - start;
        log.info("[끝] {} → {}ms", joinPoint.getSignature().toShortString(), duration);
        return result;
    }
}
```



### 방법 B: 원하는 메서드에만 적용 (커스텀 어노테이션 방식)

```java
// ① 커스텀 어노테이션 정의
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface LogExecutionTime { }

// ② Aspect 구현
@Aspect
@Component
public class ExecutionTimeAspect {
    @Around("@annotation(LogExecutionTime)")
    public Object measureTime(ProceedingJoinPoint joinPoint) throws Throwable {
        long start = System.currentTimeMillis();
        Object result = joinPoint.proceed();
        log.info("[성능] {} → {}ms", joinPoint.getSignature().toShortString(),
                System.currentTimeMillis() - start);
        return result;
    }
}

// ③ 원하는 메서드에 어노테이션 추가
@Service
public class OrderService {
    @LogExecutionTime
    public void createOrder() { ... }   // 이 메서드만 시간 측정됨
}
```



### 실무 예제: 재시도 로직

```java
// ① 어노테이션 정의 (옵션값 포함)
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Retry {
    int maxAttempts() default 3;
    long delay() default 1000;
}

// ② Aspect 구현 (파라미터 바인딩으로 어노테이션 값 사용)
@Aspect
@Component
public class RetryAspect {
    @Around("@annotation(retry)")
    public Object retry(ProceedingJoinPoint joinPoint, Retry retry) throws Throwable {
        int maxAttempts = retry.maxAttempts();
        long delay = retry.delay();
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                return joinPoint.proceed();
            } catch (Exception e) {
                if (attempt == maxAttempts) throw e;
                log.warn("[Retry] {}회 실패, {}ms 후 재시도", attempt, delay);
                Thread.sleep(delay);
            }
        }
        return null;
    }
}

// ③ 사용
@Service
public class PaymentService {
    @Retry(maxAttempts = 3, delay = 2000)
    public void processPayment(PaymentRequest request) {
        externalPaymentApi.call(request);
    }
}
```

------



## 8. Spring AOP vs AspectJ

|                     | Spring AOP          | AspectJ                       |
| ------------------- | ------------------- | ----------------------------- |
| **Weaving 시점**    | 런타임 (Proxy)      | 컴파일/로드 타임              |
| **JoinPoint**       | 메서드 실행만       | 메서드, 필드, 생성자 등       |
| **성능**            | Proxy 오버헤드 있음 | 바이트코드 직접 조작이라 빠름 |
| **적용 범위**       | Spring Bean만       | 모든 Java 객체                |
| **Self-Invocation** | ❌ 동작 안 함        | ✅ 동작함                      |
| **설정 난이도**     | 쉬움                | 어려움                        |

실무에서는 Spring AOP로 거의 대부분 해결됩니다.

------



## 핵심 키워드

| 카테고리           | 키워드                                                    |
| ------------------ | --------------------------------------------------------- |
| **핵심 개념**      | AOP, Cross-Cutting Concerns, Core Concerns, 관심사 분리   |
| **5대 용어**       | Aspect, Advice, Pointcut, JoinPoint, Weaving              |
| **Advice 종류**    | @Before, @After, @AfterReturning, @AfterThrowing, @Around |
| **Pointcut**       | execution, @annotation, 파라미터 바인딩                   |
| **JoinPoint**      | JoinPoint, ProceedingJoinPoint, proceed()                 |
| **Weaving**        | 컴파일 타임 Weaving, 로드 타임 Weaving, 런타임 Weaving    |
| **동작 원리**      | Proxy Pattern, JDK Dynamic Proxy, CGLIB Proxy             |
| **주의사항**       | Self-Invocation, 내부 호출 문제                           |
| **@Transactional** | Propagation, rollbackFor, Checked vs Unchecked Exception  |
| **비교**           | Spring AOP vs AspectJ                                     |

## 🎯 면접 예상 질문

### Q1. AOP란 무엇이며, 왜 사용하나요?

**모범 답안:**

> AOP는 여러 클래스에 반복되는 횡단 관심사(로깅, 트랜잭션, 인증 등)를 비즈니스 로직에서 분리하여 모듈화하는 프로그래밍 패러다임입니다. AOP를 사용하면 비즈니스 로직은 핵심 관심사에만 집중할 수 있고, 공통 기능은 Aspect로 한 곳에서 관리하므로 코드 중복이 제거되고 유지보수가 용이해집니다.

### Q2. AOP의 핵심 용어 5가지를 설명해주세요.

**모범 답안:**

> **Aspect**는 횡단 관심사를 모듈화한 클래스입니다. **Advice**는 횡단 관심사의 실제 실행 코드로, @Before, @After, @Around 등이 있습니다. **Pointcut**은 Advice를 어디에 적용할지 정의하는 표현식입니다. **JoinPoint**는 Advice가 적용되는 실행 지점으로, Spring AOP에서는 메서드 실행 시점입니다. **Weaving**은 Aspect를 대상 객체에 실제로 결합하는 과정으로, Spring AOP는 런타임에 Proxy를 생성하는 런타임 Weaving을 사용합니다.

### Q3. Spring AOP는 내부적으로 어떻게 동작하나요?

**모범 답안:**

> Spring AOP는 런타임 Weaving 방식으로, Bean 생성 시점에 AOP 대상인 Bean의 Proxy 객체를 생성하여 Container에 등록합니다. 호출자가 메서드를 호출하면 Proxy가 먼저 받아서 Advice를 실행한 뒤, 원래 객체의 메서드를 호출합니다. Proxy 생성 방식으로는 인터페이스 기반의 JDK Dynamic Proxy와 클래스 상속 기반의 CGLIB Proxy가 있으며, Spring Boot의 기본값은 CGLIB입니다.

### Q4. Self-Invocation 문제란 무엇이며, 왜 발생하고, 어떻게 해결하나요?

**모범 답안:**

> Self-Invocation은 같은 클래스 내에서 `this.method()`로 메서드를 호출하면 Proxy를 거치지 않아 AOP가 적용되지 않는 문제입니다. Spring AOP가 런타임 Weaving(Proxy 방식)을 사용하기 때문에 발생합니다. 외부에서 호출해야 Proxy를 거치므로, 해당 메서드를 별도 클래스로 분리하는 것이 권장되는 해결 방법입니다.

### Q5. @Transactional에서 Checked Exception이 발생하면 롤백이 될까요?

**모범 답안:**

> 기본적으로 롤백되지 않습니다. Spring @Transactional은 RuntimeException과 Error에서만 롤백합니다. Checked Exception에서도 롤백하려면 `@Transactional(rollbackFor = Exception.class)`처럼 rollbackFor 옵션을 명시해야 합니다.
