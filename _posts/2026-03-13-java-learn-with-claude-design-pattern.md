---
title: 자바 디자인패턴
date: 2026-03-13 16:25:04 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 설계, 디자인패턴]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 디자인패턴 학습
- 목표 : Spring에서 어떤 디자인 패턴을 사용하는지 숙지한다.

## 📝 본문

## 디자인 패턴이란?

### 핵심 개념

> **"반복적으로 등장하는 설계 문제를 해결하는 검증된 방법"**

```
GoF 디자인 패턴 23가지
  ├── 생성 패턴 (5개) — 객체를 어떻게 만들지
  ├── 구조 패턴 (7개) — 객체를 어떻게 조합할지
  └── 행동 패턴 (11개) — 객체가 어떻게 협력할지
```

### 모든 패턴의 공통 원리

```
공통점
  └── 인터페이스/추상화로 한 단계 떨어뜨려서
      변경의 영향을 최소화한다

이게 바로 DIP (의존성 역전 원칙)
  즉, 디자인 패턴 = DIP를 다양한 상황에 적용한 구체적인 방법들
```

### SOLID → 디자인 패턴 → 헥사고날 연결

```
SOLID (설계 원칙)
  └── DIP — 인터페이스에 의존하라
        ↓ 구체적으로 어떻게?
디자인 패턴 (구현 방법)
  ├── Strategy  — 알고리즘을 인터페이스로
  ├── Factory   — 생성을 인터페이스로
  ├── Decorator — 부가기능을 인터페이스로
  ├── Observer  — 이벤트를 인터페이스로
  └── Template Method — 뼈대를 추상 클래스로
        ↓ 아키텍처 전체에 적용하면?
헥사고날 아키텍처
  └── Port — 도메인과 인프라 사이를 인터페이스로
```

------



## Strategy 패턴

### 개념

> **"알고리즘을 인터페이스로 캡슐화해서 런타임에 교체 가능하게 만든다"**

### 구성요소

```
Strategy (전략 인터페이스)     — 알고리즘 선언
ConcreteStrategy (구체 전략)   — 알고리즘 구현
Context (전략을 사용하는 곳)   — Strategy에만 의존
```

### ❌ 위반 코드

```java
class PaymentService {
    public void pay(String paymentType, int amount) {
        if (paymentType.equals("CARD")) {
            System.out.println("카드 결제: " + amount + "원");
        } else if (paymentType.equals("KAKAO_PAY")) {
            System.out.println("카카오페이 결제: " + amount + "원");
        }
        // 새 결제수단 추가 시 → 기존 코드 수정 필요 ❌
    }
}
```

### ✅ Strategy 패턴 적용

```java
// 1. Strategy 인터페이스
interface Pay {
    void pay(int amount);
}

// 2. 구체 Strategy
class CardPayment implements Pay {
    public void pay(int amount) {
        System.out.println("카드 결제: " + amount + "원");
    }
}

class KakaoPayment implements Pay {
    public void pay(int amount) {
        System.out.println("카카오페이 결제: " + amount + "원");
    }
}

class NaverPayment implements Pay {
    public void pay(int amount) {
        System.out.println("네이버페이 결제: " + amount + "원");
    }
}

// 새 결제수단 추가? → 클래스만 추가 ✅
class TossPayment implements Pay {
    public void pay(int amount) {
        System.out.println("토스 결제: " + amount + "원");
    }
}

// 3. Context — 인터페이스에만 의존
class PaymentService {
    private final Pay payStrategy;

    public PaymentService(Pay payStrategy) {
        this.payStrategy = payStrategy;
    }

    public void pay(int amount) {
        payStrategy.pay(amount);  // 런타임에 어떤 전략이든 실행 ✅
    }
}

// 4. 사용
PaymentService service = new PaymentService(new CardPayment());
service.pay(10000);  // 카드 결제: 10000원
```

### 헥사고날과의 연결

```
Strategy 패턴       헥사고날
──────────────────────────────
Strategy 인터페이스  = Port (Outgoing)
ConcreteStrategy    = Adapter
Context             = Domain Service
```

### 실전 예시 — 대기열 순서 결정

```java
interface QueueOrderStrategy {
    List<UserId> sort(List<WaitingEntry> entries);
}

// 선착순
class FifoQueueStrategy implements QueueOrderStrategy {
    public List<UserId> sort(List<WaitingEntry> entries) {
        return entries.stream()
            .sorted(Comparator.comparing(WaitingEntry::getEnteredAt))
            .map(WaitingEntry::getUserId)
            .collect(toList());
    }
}

// VIP 우선
class VipFirstQueueStrategy implements QueueOrderStrategy {
    public List<UserId> sort(List<WaitingEntry> entries) {
        return entries.stream()
            .sorted(Comparator.comparing(WaitingEntry::isVip).reversed())
            .map(WaitingEntry::getUserId)
            .collect(toList());
    }
}

// 랜덤 추첨
class LotteryQueueStrategy implements QueueOrderStrategy {
    public List<UserId> sort(List<WaitingEntry> entries) {
        List<WaitingEntry> shuffled = new ArrayList<>(entries);
        Collections.shuffle(shuffled);
        return shuffled.stream()
            .map(WaitingEntry::getUserId)
            .collect(toList());
    }
}

// Context
class WaitingQueue {
    private final QueueOrderStrategy orderStrategy;

    public List<UserId> getOrderedWaiters() {
        return orderStrategy.sort(this.entries);
    }
}
```

### SOLID 연결

```
OCP — 새 결제수단 추가 시 기존 코드 수정 없음
DIP — PaymentService가 구체 클래스가 아닌 Pay에 의존
```

### Strategy vs If-else

```
If-else
  ├── 새 수단 추가 시 기존 코드 수정 → 사이드 이펙트 위험
  ├── 로직이 한 곳에 몰려 테스트 어려움
  └── 코드가 길어질수록 가독성 저하

Strategy
  ├── 새 클래스만 추가 → 기존 코드 수정 없음 ✅
  ├── 각 전략 독립 테스트 가능 ✅
  └── 단, 전략이 2~3개로 고정이면 오히려 과함 ⚠️
```

------



## Factory 패턴

### 개념

> **"객체 생성을 별도의 클래스(Factory)에 위임한다"**

### 종류

```
Factory 패턴
  ├── Simple Factory   — 가장 기본, 생성 로직을 한 곳에 모음
  ├── Factory Method   — 상속으로 생성을 서브클래스에 위임
  └── Abstract Factory — 관련 객체군을 함께 생성
```

### ❌ Factory 없을 때 문제점

```java
@RestController
class PaymentController {
    public void pay(String paymentType, int amount) {
        // Controller가 객체 생성 방법을 알고 있음 ❌
        if (paymentType.equals("CARD")) {
            new PaymentService(new CardPayment()).pay(amount);
        } else if (paymentType.equals("KAKAO_PAY")) {
            new PaymentService(new KakaoPayment()).pay(amount);
        }
        // 새 결제수단 추가 시 Controller도 수정 ❌
    }
}
```

### ✅ Simple Factory

```java
class PaymentFactory {
    public static Pay create(String paymentType) {
        switch (paymentType) {
            case "CARD":       return new CardPayment();
            case "KAKAO_PAY":  return new KakaoPayment();
            case "NAVER_PAY":  return new NaverPayment();
            default: throw new IllegalArgumentException("지원하지 않는 결제수단: " + paymentType);
        }
    }
}
```

### ✅ Spring에서의 Factory — Enum + List 주입 (권장)

```java
// 1. Enum으로 타입 정의 — 클라이언트 규격
enum PaymentType {
    CARD, KAKAO_PAY, NAVER_PAY, TOSS
}

// 2. 각 구현체에 자신의 타입 명시
interface Pay {
    void pay(int amount);
    PaymentType getType();
}

@Component
class CardPayment implements Pay {
    public void pay(int amount) {
        System.out.println("카드 결제: " + amount + "원");
    }
    public PaymentType getType() { return PaymentType.CARD; }
}

@Component
class KakaoPayment implements Pay {
    public void pay(int amount) {
        System.out.println("카카오페이 결제: " + amount + "원");
    }
    public PaymentType getType() { return PaymentType.KAKAO_PAY; }
}

// 3. Factory — Spring이 List 자동 주입
@Component
class PaymentFactory {
    private final Map<PaymentType, Pay> paymentMap;

    // Spring이 Pay 구현체 전부를 List로 자동 주입
    public PaymentFactory(List<Pay> payments) {
        paymentMap = payments.stream()
            .collect(toMap(Pay::getType, pay -> pay));
    }

    public Pay getPayment(PaymentType type) {
        Pay pay = paymentMap.get(type);
        if (pay == null)
            throw new IllegalArgumentException("지원하지 않는 결제수단: " + type);
        return pay;
    }
}

// 4. Controller — 클라이언트는 Enum 값만 보내면 됨
@RestController
class PaymentController {
    private final PaymentFactory paymentFactory;

    @PostMapping("/pay")
    public void pay(@RequestParam PaymentType type,
                    @RequestParam int amount) {
        Pay pay = paymentFactory.getPayment(type);
        new PaymentService(pay).pay(amount);
    }
}
```

### Spring이 Map을 만드는 방식

```
Spring 시작 시
  ├── @Component 붙은 Pay 구현체 전부 스캔
  └── List<Pay> 로 자동 주입
      [CardPayment, KakaoPayment, NaverPayment]

PaymentFactory 생성 시
  └── List를 Map으로 변환
      { CARD: CardPayment, KAKAO_PAY: KakaoPayment ... }

클라이언트가 "KAKAO_PAY" 전송 시
  └── Map에서 KakaoPayment 찾아서 반환
```

### 새 결제수단 추가 시 변경 범위

```
TossPay 추가 시
  ├── PaymentType Enum에 TOSS 추가  ← 불가피한 변경
  └── TossPayment 클래스 추가       ← 새 클래스만 추가

Controller, PaymentFactory, PaymentService
  → 수정 없음 ✅
```

### SOLID 연결

```
DIP — 클라이언트가 구체 클래스를 직접 생성 X
OCP — 새 타입 추가 시 기존 코드 수정 없음
```

------



## Decorator 패턴

### 개념

> **"기존 객체를 감싸서(Wrap) 기능을 동적으로 추가한다"**

### 상속 대신 Decorator를 쓰는 이유

```
상속으로 기능 조합 시 — 클래스 폭발 문제
  EmailSender
    ├── EmailWithLogging
    ├── EmailWithRetry
    ├── EmailWithLoggingAndRetry      ← 조합마다 클래스 필요 ❌
    └── EmailWithLoggingAndRetryAndTiming ...

Decorator로 기능 조합 시 — 런타임 자유 조합
  LoggingDecorator(EmailSender)
  RetryDecorator(EmailSender)
  LoggingDecorator(RetryDecorator(EmailSender))  ← 조합 자유 ✅
```

### ✅ Decorator 패턴 적용

```java
// 1. 공통 인터페이스
interface NotificationSender {
    void send(String message);
}

// 2. 기본 구현체
@Component
class EmailSender implements NotificationSender {
    public void send(String message) {
        System.out.println("이메일 발송: " + message);
    }
}

// 3. Decorator 추상 클래스
abstract class NotificationDecorator implements NotificationSender {
    protected final NotificationSender wrapped;

    public NotificationDecorator(NotificationSender wrapped) {
        this.wrapped = wrapped;
    }
}

// 4. 구체 Decorator — 로깅
class LoggingDecorator extends NotificationDecorator {
    public LoggingDecorator(NotificationSender wrapped) {
        super(wrapped);
    }

    public void send(String message) {
        System.out.println("[LOG] 발송 시작: " + message);
        wrapped.send(message);                          // 기존 기능 실행
        System.out.println("[LOG] 발송 완료");
    }
}

// 5. 구체 Decorator — 재시도
class RetryDecorator extends NotificationDecorator {
    private final int maxRetry;

    public RetryDecorator(NotificationSender wrapped, int maxRetry) {
        super(wrapped);
        this.maxRetry = maxRetry;
    }

    public void send(String message) {
        for (int i = 0; i < maxRetry; i++) {
            try {
                wrapped.send(message);
                return;
            } catch (Exception e) {
                System.out.println("[RETRY] " + (i + 1) + "번째 재시도");
            }
        }
        throw new RuntimeException("최대 재시도 초과");
    }
}

// 6. 조합해서 사용
NotificationSender sender = new EmailSender();
NotificationSender withLogging = new LoggingDecorator(sender);
NotificationSender withBoth = new LoggingDecorator(
                                  new RetryDecorator(sender, 3)
                              );
withBoth.send("안녕하세요");
```

### Spring AOP = Decorator의 자동화

```java
// AOP로 더 깔끔하게 — 기존 코드 수정 없음 ✅
@Aspect
@Component
class TimingAspect {

    @Around("execution(* QueueUseCase.enterQueue(..))")
    public Object timing(ProceedingJoinPoint joinPoint) throws Throwable {
        long start = System.currentTimeMillis();
        Object result = joinPoint.proceed();  // 기존 기능 실행
        long end = System.currentTimeMillis();
        System.out.println("실행 시간: " + (end - start) + "ms");
        return result;
    }
}

// @Transactional, @Cacheable 모두 Decorator 패턴으로 동작
@Service
class QueueService {
    @Transactional  // Spring이 자동으로 Decorator로 감싸줌
    public WaitingToken enterQueue(EnterQueueCommand command) {
        // 트랜잭션 시작 → 비즈니스 로직 → 트랜잭션 커밋/롤백
    }
}
```

### Controller에서 Decorator 호출 방식

```
수동 Decorator
  Controller → new TimingDecorator(new QueueService())
  → Controller가 Decorator 존재를 알아야 함 ❌

Spring AOP (권장)
  Controller → QueueUseCase (인터페이스만 앎)
  → Spring이 자동으로 프록시(Decorator)를 끼워넣음 ✅
  → Controller는 Decorator 존재를 모름 ✅
```

### SOLID 연결

```
OCP — 기존 EmailSender 수정 없이 기능 추가
SRP — 로깅/재시도가 각자 자신의 책임만
DIP — Decorator가 구체 클래스가 아닌 인터페이스를 감쌈
```

------



## Observer 패턴

### 개념

> **"어떤 객체의 상태가 변하면, 그 객체에 의존하는 다른 객체들에게 자동으로 알린다"**

### ❌ Observer 없을 때 문제점

```java
@Service
class OrderService {
    private final EmailService emailService;
    private final InventoryService inventoryService;
    private final CouponService couponService;

    public void placeOrder(PlaceOrderCommand command) {
        Order order = Order.create(command);
        orderRepository.save(order);

        // 직접 호출 — 강한 결합 ❌
        emailService.sendOrderConfirmation(order);
        inventoryService.decreaseStock(order);
        couponService.useCoupon(command.getCouponId());
        // 새 기능 추가 시 OrderService 수정 필요 ❌
    }
}
```

### ✅ Spring @EventListener로 구현

```java
// 1. 이벤트 클래스 — 불변객체 ✅
class OrderCompletedEvent {
    private final Order order;        // final → 변경 불가
    private final String couponId;    // final → 변경 불가

    public OrderCompletedEvent(Order order, String couponId) {
        this.order = order;
        this.couponId = couponId;
    }

    // getter만 존재 ✅
    public Order getOrder() { return order; }
    public String getCouponId() { return couponId; }
}

// 2. Publisher — 이벤트만 발행
@Service
class OrderService {
    private final ApplicationEventPublisher eventPublisher;

    public void placeOrder(PlaceOrderCommand command) {
        // 핵심 비즈니스 로직
        Order order = Order.create(command);
        orderRepository.save(order);

        // 부가 처리는 이벤트로 위임 ✅
        eventPublisher.publishEvent(
            new OrderCompletedEvent(order, command.getCouponId())
        );
    }
}

// 3. Subscriber — 각자 자신의 책임만
@Component
class EmailNotificationListener {
    @EventListener
    public void sendConfirmation(OrderCompletedEvent event) {
        System.out.println("주문 확인 이메일 발송");
    }
}

@Component
class InventoryListener {
    @EventListener
    public void decreaseStock(OrderCompletedEvent event) {
        System.out.println("재고 차감");
    }
}

@Component
class CouponListener {
    @EventListener
    public void useCoupon(OrderCompletedEvent event) {
        System.out.println("쿠폰 처리");
    }
}

// 새 기능 추가? → Listener 클래스만 추가 ✅
@Component
class PointListener {
    @EventListener
    public void givePoints(OrderCompletedEvent event) {
        System.out.println("포인트 적립");
    }
}
```

### Spring이 @EventListener를 연결하는 방식

```
Spring 시작 시
  ↓
@Component 붙은 클래스 전부 스캔
  ↓
@EventListener 붙은 메서드 찾음
  ↓
파라미터 타입별로 내부 Map에 등록
{
  OrderCompletedEvent → [EmailListener.sendConfirmation,
                         InventoryListener.decreaseStock,
                         CouponListener.useCoupon]
}
  ↓
이벤트 발행 시 해당 타입의 메서드 전부 실행

핵심: 메서드 이름은 자유, 파라미터 타입으로 매칭 ✅
```

### 이벤트 클래스 설계 원칙

```java
// 이벤트 = "과거에 일어난 사실" → 불변이어야 함
// Java 16+에서는 record 사용 권장
record OrderCompletedEvent(Order order, String couponId) {
    // final 필드, getter, equals, hashCode 자동 생성
    // setter 없음 ✅
}
```

### 순서가 중요한 경우

```java
@Component
class InventoryListener {
    @EventListener
    @Order(1)  // 재고 차감 먼저
    public void decreaseStock(OrderCompletedEvent event) { ... }
}

@Component
class EmailListener {
    @EventListener
    @Order(2)  // 재고 차감 후 이메일 발송
    public void sendConfirmation(OrderCompletedEvent event) { ... }
}
```

### DDD Domain Event와의 연결

```
DDD Domain Event = Observer 패턴의 구현체

도메인에서 이벤트 발행
  └── domainEvents.add(new OrderCompletedEvent(...))
              ↕
Observer 패턴
  └── Publisher가 이벤트 발행 → Subscriber들이 자동으로 처리
```

### 장단점

```
장점
  ├── 느슨한 결합 — Publisher가 Subscriber를 모름
  ├── OCP — 새 Listener 추가 시 기존 코드 수정 없음
  └── SRP — 각 Listener가 자신의 책임만

단점
  ├── 흐름 파악 어려움 — 이벤트가 많아질수록 디버깅 힘듦
  ├── 실행 순서 보장 안됨 — @Order로 해결 가능
  └── 과도하게 쓰면 오히려 복잡도 증가

언제 쓰는가?
  ├── 핵심 로직 완료 후 부가 처리가 많은 경우
  ├── 다른 도메인과 결합도를 낮추고 싶은 경우
  └── 새 기능이 자주 추가되는 경우
```

------



## Template Method 패턴

### 개념

> **"알고리즘의 뼈대(순서)는 부모가 정의하고, 세부 구현은 자식이 채운다"**

### ❌ Template Method 없을 때 문제점

```java
// 공통 로직이 모든 클래스에서 중복
class EmailNotificationSender {
    public void send(String userId, String message) {
        User user = userRepository.findById(userId);  // 중복 ❌
        String formatted = "<html>" + message + "</html>";
        emailClient.send(user.getEmail(), formatted);
        logRepository.save(userId, message);           // 중복 ❌
    }
}

class SmsNotificationSender {
    public void send(String userId, String message) {
        User user = userRepository.findById(userId);  // 중복 ❌
        String formatted = "[SMS] " + message;
        smsClient.send(user.getPhone(), formatted);
        logRepository.save(userId, message);           // 중복 ❌
    }
}
```

### ✅ Template Method 패턴 적용

```java
// 1. 추상 클래스 — 알고리즘 뼈대 정의
abstract class NotificationSender {

    // Template Method — 순서 고정, final로 변경 금지
    public final void send(String userId, String message) {
        // 1. 수신자 조회 (공통) ✅
        User user = userRepository.findById(userId);

        // 2. 메시지 포맷 (자식이 구현)
        String formatted = formatMessage(message);

        // 3. 발송 (자식이 구현)
        doSend(user, formatted);

        // 4. 발송 이력 저장 (공통) ✅
        logRepository.save(userId, message);
    }

    // Hook Method — 자식이 반드시 구현
    protected abstract String formatMessage(String message);
    protected abstract void doSend(User user, String message);
}

// 2. 구체 클래스 — 세부 구현만
class EmailNotificationSender extends NotificationSender {

    @Override
    protected String formatMessage(String message) {
        return "<html>" + message + "</html>";
    }

    @Override
    protected void doSend(User user, String message) {
        emailClient.send(user.getEmail(), message);
    }
}

class SmsNotificationSender extends NotificationSender {

    @Override
    protected String formatMessage(String message) {
        return "[SMS] " + message;
    }

    @Override
    protected void doSend(User user, String message) {
        smsClient.send(user.getPhone(), message);
    }
}

// 새 채널 추가? → 클래스만 추가 ✅
class KakaoNotificationSender extends NotificationSender {

    @Override
    protected String formatMessage(String message) {
        return "【카카오】 " + message;
    }

    @Override
    protected void doSend(User user, String message) {
        kakaoClient.send(user.getKakaoId(), message);
    }
}
```

### 결제 예시

```java
// 공통 로직 중복 제거
abstract class Payment {

    // Template Method
    public final void pay(int amount) {
        validate(amount);                              // 공통
        doPayment(amount);                             // 자식 구현
        paymentLogRepository.save(getPaymentType(), amount); // 공통
    }

    private void validate(int amount) {
        if (amount <= 0)
            throw new IllegalArgumentException("금액 오류");
    }

    protected abstract void doPayment(int amount);
    protected abstract String getPaymentType();
}

class CardPayment extends Payment {
    protected void doPayment(int amount) {
        System.out.println("카드 결제: " + amount + "원");
    }
    protected String getPaymentType() { return "CARD"; }
}

class KakaoPayment extends Payment {
    protected void doPayment(int amount) {
        System.out.println("카카오페이 결제: " + amount + "원");
    }
    protected String getPaymentType() { return "KAKAO"; }
}
```

### SOLID 연결

```
OCP — 새 채널 추가 시 기존 코드 수정 없음
LSP — 자식(EmailSender)이 부모(NotificationSender)를 완전히 대체
DRY — 공통 로직(수신자 조회, 이력 저장) 중복 제거
```

------



## 패턴 간 비교

### Strategy vs Template Method

```
Strategy
  ├── 인터페이스 + 구현체 (합성)
  ├── 런타임에 알고리즘 교체 가능
  ├── 알고리즘 전체를 교체
  └── 언제? 알고리즘 전체가 바뀌는 경우

Template Method
  ├── 추상 클래스 + 상속
  ├── 컴파일 타임에 결정
  ├── 알고리즘 일부(세부 구현)만 교체
  └── 언제? 순서는 고정, 일부만 바뀌는 경우
```

### Decorator vs 상속

```
상속
  ├── 컴파일 타임에 기능 결정
  ├── 조합마다 클래스 필요 → 클래스 폭발
  └── LSP 지켜야 함

Decorator
  ├── 런타임에 기능 조합 가능
  ├── 조합이 자유로움 → 클래스 최소화
  └── 기존 코드 수정 없이 기능 추가
```

### 전체 패턴 한눈에

```
패턴             핵심 목적                    Spring 구현체
──────────────────────────────────────────────────────────
Strategy        알고리즘 교체                 @Component + DI
Factory         객체 생성 위임               List<T> 주입
Decorator       부가 기능 추가               AOP, @Transactional
Observer        이벤트 기반 느슨한 결합       @EventListener
Template Method 공통 뼈대 + 세부 구현 분리   추상 클래스
```



## 🎯 면접 예상 질문

### Q1. Strategy 패턴과 if-else의 차이는?

> "if-else는 새로운 수단 추가 시 기존 코드를 수정해야 하므로 사이드 이펙트 위험이 있고, 로직이 한 곳에 몰려 테스트가 어렵습니다. Strategy 패턴은 새 클래스만 추가하면 되므로 기존 코드를 건드리지 않고 독립적으로 테스트할 수 있습니다. 다만 알고리즘이 자주 바뀌지 않거나 단순한 경우엔 if-else가 더 단순할 수 있어서 변경 가능성이 높은 곳에 선택적으로 적용하는 게 좋습니다."

### Q2. Factory 패턴이 왜 필요한가?

> "객체 생성 로직이 여러 곳에 흩어지면 새 타입 추가 시 생성하는 모든 곳을 수정해야 합니다. Factory로 생성 로직을 한 곳에 모으면 변경 범위가 최소화됩니다. Spring에서는 List로 구현체를 주입받아 Enum으로 Map을 만들면 새 구현체 추가 시 Factory도 수정할 필요가 없습니다."

### Q3. Decorator 패턴과 상속의 차이는?

> "상속은 LSP를 지켜야 하므로 자식이 부모의 동작을 완전히 대체할 수 있어야 합니다. 또한 기능 조합이 늘어날수록 클래스가 폭발적으로 증가합니다. Decorator는 기존 객체를 감싸서 부가 기능을 추가하므로 기존 코드를 수정하지 않아도 되고, 런타임에 자유롭게 조합할 수 있어서 훨씬 유연합니다."

### Q4. Observer 패턴의 장단점은?

> "장점은 Publisher가 Subscriber를 몰라도 되므로 느슨한 결합이 달성됩니다. 새 Listener 추가 시 기존 코드 수정이 없어 OCP를 자연스럽게 지킵니다. 단점은 이벤트가 많아질수록 누가 무엇을 발행하고 구독하는지 파악하기 어려워 디버깅이 힘들고, 실행 순서가 보장되지 않습니다."

### Q5. Strategy 패턴과 Template Method 패턴의 차이는?

> "Strategy 패턴은 인터페이스로 알고리즘 전체를 교체하는 방식으로 런타임에 동적으로 교체할 수 있습니다. Template Method는 추상 클래스로 알고리즘의 순서를 고정하고 공통 로직을 미리 구현하며, 자식은 달라지는 부분만 채웁니다. 알고리즘 전체가 바뀌는 경우엔 Strategy, 순서는 고정이고 일부만 바뀌는 경우엔 Template Method가 적합합니다."

### Q6. 디자인 패턴들의 공통점은?

> "모든 패턴의 공통 원리는 인터페이스나 추상화로 한 단계 떨어뜨려서 변경의 영향을 최소화하는 것입니다. 이는 결국 DIP(의존성 역전 원칙)의 다양한 상황별 구체적인 구현 방법이라고 볼 수 있습니다."
