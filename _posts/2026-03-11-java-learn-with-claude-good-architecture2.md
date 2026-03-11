---
title: [설계의 기본] - 헥사고날, DDD
date: 2026-03-11 17:31:52 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 설계]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 헥사고날 DDD 이해
- 목표 : 헥사고날 설계에 대한 이해도를 높인다.

## 📝 본문

## 왜 함께 쓰는가?

2024~2025년 트렌드는 **DDD와 헥사고날을 함께 쓰는 것이 표준**으로 자리잡았다.

```
DDD      → 도메인을 올바르게 설계하는 방법론  (무엇을 설계할지)
헥사고날  → 그 도메인을 외부로부터 보호하는 구조 (어떻게 구조를 잡을지)

DDD만 쓰면      → 도메인은 풍부한데 인프라에 오염될 수 있음
헥사고날만 쓰면 → 구조는 있는데 도메인이 빈약할 수 있음
함께 쓰면       → 도메인이 풍부하고 + 인프라로부터 완전히 격리됨 ✅
```

------



## 레이어드 아키텍처의 문제점

### 전통적인 구조

```
❌ 전통적 레이어드 아키텍처

  Controller
      ↓
  Service         ← 비즈니스 로직
      ↓
  Repository
      ↓
  Database
```

의존성이 위에서 아래로 흐르기 때문에 **DB나 외부 API가 변경되면 Service까지 영향이 전파**된다.

```java
// ❌ 레이어드 아키텍처의 전형적인 문제
@Service
class OrderService {
    @Autowired
    private JpaOrderRepository jpaRepository;  // JPA 직접 의존

    @Autowired
    private RestTemplate restTemplate;         // 외부 API 직접 의존

    public void placeOrder(OrderRequest request) {
        // URL 하드코딩 — API 변경 시 Service 수정 필요 ❌
        String url = "https://inventory-api/check/" + request.getProductId();
        boolean inStock = restTemplate.getForObject(url, Boolean.class);

        if (!inStock) throw new RuntimeException("재고 없음");

        // JPA 직접 사용 — DB 변경 시 Service 수정 필요 ❌
        jpaRepository.save(new OrderEntity(request));
    }
}
```

### 문제점 정리

```
Service가 너무 많은 것을 알고 있음
  ├── JPA 구체 클래스          → DB 변경 시 Service 수정 필요
  ├── 외부 API URL             → API 변경 시 Service 수정 필요
  ├── HTTP 통신 방법           → 기술 세부사항에 오염
  └── 실제 DB/API 없이 테스트 불가 → 단위 테스트 어려움
```

------



## 헥사고날 아키텍처

### 핵심 아이디어

> **"비즈니스 로직(도메인)을 중심에 두고, 외부 세계와의 연결은 포트와 어댑터로 격리한다"**

```
          외부 세계
  ┌──────────────────────────────────┐
  │  REST API     Kafka     CLI      │
  │     ↓           ↓        ↓      │
  │  [Adapter]  [Adapter] [Adapter] │  ← 어댑터 (번역기)
  │     ↓           ↓        ↓      │
  │  [Port]     [Port]    [Port]    │  ← 포트 (인터페이스)
  │                ↓                │
  │  ┌───────────────────────────┐  │
  │  │                           │  │
  │  │       Domain (핵심)        │  │  ← 도메인 (불변)
  │  │                           │  │
  │  └───────────────────────────┘  │
  │                ↓                │
  │  [Port]     [Port]    [Port]    │  ← 포트 (인터페이스)
  │     ↓           ↓        ↓      │
  │  [Adapter]  [Adapter] [Adapter] │  ← 어댑터 (번역기)
  │  MySQL      Redis       S3      │
  └──────────────────────────────────┘
          외부 세계
```

### 3가지 핵심 용어

**Domain (도메인)**

- 순수한 비즈니스 로직
- DB도 모르고, HTTP도 모르고, 외부 API도 모름
- 절대 변하지 않아야 할 핵심

**Port (포트)**

- 도메인이 외부와 소통하는 인터페이스
- "나는 이런 기능이 필요해" 라고 선언만 함
- Incoming Port — 외부 → 도메인 (UseCase)
- Outgoing Port — 도메인 → 외부 (Repository 등)

**Adapter (어댑터)**

- 포트의 구체적인 구현체
- 외부 세계와 도메인 사이의 번역기 역할
- Incoming Adapter — Controller, Kafka Consumer 등
- Outgoing Adapter — JPA Repository, Redis, S3 등

### 의존성 방향

```
✅ Adapter → Domain (가능)
❌ Domain  → Adapter (절대 불가)

도메인은 어댑터를 절대 모른다!
```

### 헥사고날로 개선된 코드

```java
// 1. Incoming Port (UseCase)
interface PlaceOrderUseCase {
    void placeOrder(PlaceOrderCommand command);
}

// 2. Outgoing Port — 도메인이 외부에 요청하는 기능 선언
interface OrderRepository {
    void save(Order order);
}

interface InventoryPort {
    boolean isInStock(String productId);
}

interface PaymentPort {
    void pay(Order order);
}

// 3. Domain Service — 순수 비즈니스 로직만 ✅
@Service
class OrderService implements PlaceOrderUseCase {
    private final OrderRepository orderRepository;
    private final InventoryPort inventoryPort;
    private final PaymentPort paymentPort;

    public OrderService(
        OrderRepository orderRepository,
        InventoryPort inventoryPort,
        PaymentPort paymentPort
    ) {
        this.orderRepository = orderRepository;
        this.inventoryPort = inventoryPort;
        this.paymentPort = paymentPort;
    }

    @Override
    public void placeOrder(PlaceOrderCommand command) {
        // URL도 모르고, JPA도 모르고, HTTP도 모름
        // 비즈니스 흐름만 알고 있음 ✅
        if (!inventoryPort.isInStock(command.getProductId())) {
            throw new OutOfStockException("재고 없음");
        }
        Order order = Order.create(command);
        orderRepository.save(order);
        paymentPort.pay(order);
    }
}

// 4. Outgoing Adapter — 포트의 구체적 구현
@Component
class JpaOrderAdapter implements OrderRepository {
    private final JpaOrderRepository jpaRepository;

    public void save(Order order) {
        jpaRepository.save(OrderJpaEntity.from(order));
    }
}

@Component
class RestInventoryAdapter implements InventoryPort {
    private final RestTemplate restTemplate;

    public boolean isInStock(String productId) {
        // URL은 여기서만 앎 ✅
        String url = "https://inventory-api/check/" + productId;
        return restTemplate.getForObject(url, Boolean.class);
    }
}
```

### 패키지 구조

```
com.waitqueue.order
  ├── application                         ← 도메인 레이어
  │   ├── domain
  │   │   └── Order.java                  ← 순수 도메인 객체
  │   ├── port
  │   │   ├── in                          ← Incoming Port
  │   │   │   └── PlaceOrderUseCase.java
  │   │   └── out                         ← Outgoing Port
  │   │       ├── OrderRepository.java
  │   │       ├── InventoryPort.java
  │   │       └── PaymentPort.java
  │   └── service
  │       └── OrderService.java
  │
  └── adapter                             ← 어댑터 레이어
      ├── in
      │   └── web
      │       └── OrderController.java
      └── out
          ├── persistence
          │   └── JpaOrderAdapter.java
          ├── payment
          │   └── RestPaymentAdapter.java
          └── inventory
              └── RestInventoryAdapter.java
```

### 각 클래스의 위치 판단 기준

```
도메인 객체 (Order, WaitingQueue 등)  → application/domain
UseCase 인터페이스                    → application/port/in
Repository/외부 인터페이스            → application/port/out
Controller, Kafka Consumer           → adapter/in
JPA, Redis, 외부 API 구현체           → adapter/out
```

### 예외 발생 시 흐름

```
클라이언트 요청
    ↓
Controller (Incoming Adapter)
    ↓
Service.method()
    ↓
domain.method() → 예외 발생! (비즈니스 규칙 위반)
    ↑ 스택 거슬러 올라감
Service (처리 안 함)
    ↑
Controller (처리 안 함)
    ↑
GlobalExceptionHandler (최종 처리) ✅
    ↓
클라이언트에게 에러 응답

핵심: 예외 발생 시 repository.save() 호출 안 됨
      → DB에 잘못된 데이터 저장 위험 없음 ✅
```

### SOLID와의 연결

```
Port = DIP의 아키텍처 레벨 적용

클래스 레벨 DIP    → OrderService가 OrderRepository(인터페이스)에 의존
아키텍처 레벨 DIP  → 도메인이 Port(인터페이스)에만 의존

DIP  → Port로 의존성을 역전시킨다 (기반)
 ↓
OCP  → 새 Adapter 추가 시 기존 코드 수정 없이 확장 가능 (결과)
```

------



## DDD 핵심 구성요소

### 1. Entity

- 고유한 식별자(ID)를 가진 객체
- ID가 같으면 같은 객체
- 상태가 변할 수 있음

```java
class Order {  // Entity
    private final OrderId orderId;  // 고유 식별자

    @Override
    public boolean equals(Object o) {
        return this.orderId.equals(((Order) o).orderId);  // ID로 동등성 판단
    }
}
```

**판단 기준:** "이것을 구별해야 하는가?"

- 주문 2개가 같은 상품/금액이어도 다른 주문 → Entity ✅

------



### 2. Value Object (VO)

- 식별자 없이 값 자체가 의미를 가지는 객체
- 불변(Immutable)
- 값이 같으면 같은 객체

```java
// ❌ 원시값 사용 — 의미 없음
class Order {
    private int price;
}

// ✅ Value Object 사용 — 의미 명확
class Money {
    private final int amount;
    private final Currency currency;

    public Money(int amount, Currency currency) {
        if (amount < 0) throw new IllegalArgumentException("금액은 0 이상");
        this.amount = amount;
        this.currency = currency;
    }

    public Money add(Money other) {
        if (!this.currency.equals(other.currency))
            throw new IllegalArgumentException("통화 단위 불일치");
        return new Money(this.amount + other.amount, this.currency);  // 불변 ✅
    }
}
```

**판단 기준:** "값 자체가 의미인가?"

- 10000원짜리 Money 2개는 완전히 같음 → VO ✅

------



### 3. Aggregate & Aggregate Root

- 연관된 Entity/VO의 묶음 = Aggregate
- 묶음의 진입점 = Aggregate Root
- 외부는 반드시 Root를 통해서만 접근

```java
class Order {  // Aggregate Root
    private final OrderId orderId;
    private final List<OrderItem> items;  // Aggregate 내부 Entity
    private Money totalPrice;

    // 외부는 Order를 통해서만 OrderItem에 접근 ✅
    public void addItem(Product product, int quantity) {
        OrderItem item = new OrderItem(product, quantity);
        items.add(item);
        this.totalPrice = calculateTotal();  // 내부 일관성 유지
    }

    public void cancel() {
        validateCancellable();
        this.status = OrderStatus.CANCELLED;
        this.items.forEach(OrderItem::cancel);  // 내부 일관성 유지
    }
}

// ❌ 외부에서 직접 접근 — Aggregate 규칙 위반
orderItem.setStatus("CANCELLED");

// ✅ 반드시 Root를 통해 접근
order.cancel();
```

**경계 기준:**

- "함께 생성되고 함께 삭제되는가?"
- "항상 함께 일관성이 유지되어야 하는가?"

------



### 4. Domain Event

- 도메인에서 중요한 사건이 발생했음을 알리는 객체
- 다른 도메인과의 결합도를 낮춤

```java
// 직접 정의하는 마커 인터페이스 (헥사고날 권장 방식)
public interface DomainEvent {
    LocalDateTime occurredAt();
}

// 구체적인 이벤트
public class UserEnteredQueueEvent implements DomainEvent {
    private final String queueId;
    private final UserId userId;
    private final LocalDateTime occurredAt;

    public UserEnteredQueueEvent(String queueId, UserId userId) {
        this.queueId = queueId;
        this.userId = userId;
        this.occurredAt = LocalDateTime.now();
    }
}

// 도메인에서 이벤트 발행
class WaitingQueue {
    private List<DomainEvent> domainEvents = new ArrayList<>();

    public WaitingToken enter(UserId userId) {
        validateEnterable();
        userIds.add(userId);
        // 다른 도메인에 직접 의존 X ✅
        domainEvents.add(new UserEnteredQueueEvent(this.queueId, userId));
        return WaitingToken.of(this, userId);
    }
}

// 이벤트 발행은 Adapter가 담당 (Spring 의존은 여기서만)
@Component
class SpringEventPublisherAdapter implements EventPublisherPort {
    private final ApplicationEventPublisher publisher;

    public void publish(DomainEvent event) {
        publisher.publishEvent(event);  // Spring 의존은 Adapter에서만 ✅
    }
}
```

**DomainEvent는 직접 정의하는 것인가?**

- Spring의 `ApplicationEvent` 를 상속하거나, 직접 인터페이스로 정의할 수 있음
- 헥사고날에서는 **직접 정의 권장** — 도메인이 Spring에 의존하지 않아야 하기 때문

------



## Anemic vs Rich Domain Model

### Anemic Domain Model (빈혈 도메인 모델)

"빈혈" — 피가 부족한 것처럼 **행동이 없는 도메인 객체**

```java
// ❌ Anemic Model — 데이터만 있고 규칙이 없음
class WaitingQueue {
    private String queueId;
    private List<String> userIds;
    private String status;  // "OPEN" / "CLOSED" / "FULL"

    // getter/setter만 있음
    public void setStatus(String status) { this.status = status; }
}

// 모든 규칙이 Service에 몰려있음 ❌
class QueueService {
    public void enterQueue(String queueId, String userId) {
        WaitingQueue queue = queueRepository.findById(queueId);
        if (queue.getStatus().equals("CLOSED")) {
            throw new RuntimeException("마감된 대기열");
        }
        if (queue.getUserIds().size() >= queue.getMaxCapacity()) {
            queue.setStatus("FULL");
            throw new RuntimeException("대기열 가득 참");
        }
        queue.getUserIds().add(userId);
        queueRepository.save(queue);
    }
}
```



### Rich Domain Model (풍부한 도메인 모델)

"풍부한" — **행동과 규칙을 스스로 가진 도메인 객체**

```java
// ✅ Rich Model — 규칙을 스스로 가짐
enum QueueStatus {
    OPEN, FULL, CLOSED
}

class WaitingQueue {
    private final String queueId;
    private final List<UserId> userIds = new ArrayList<>();
    private final int maxCapacity;
    private QueueStatus status;

    public WaitingToken enter(UserId userId) {
        validateEnterable();    // 도메인이 직접 검증 ✅
        userIds.add(userId);
        updateStatus();         // 도메인이 직접 상태 관리 ✅
        return WaitingToken.of(this, userId);
    }

    private void validateEnterable() {
        if (status == QueueStatus.CLOSED)
            throw new QueueClosedException("마감된 대기열");
        if (status == QueueStatus.FULL)
            throw new QueueFullException("대기열 가득 참");
    }

    private void updateStatus() {
        if (userIds.size() >= maxCapacity) {
            this.status = QueueStatus.FULL;
        }
    }
}

// Service는 오케스트레이션만 ✅
class QueueService {
    public WaitingToken enterQueue(EnterQueueCommand command) {
        WaitingQueue queue = queueRepository.findById(command.getQueueId());
        WaitingToken token = queue.enter(new UserId(command.getUserId()));
        queueRepository.save(queue);
        return token;
    }
}
```

### 비교 정리

```
              Anemic               Rich
──────────────────────────────────────────────
도메인 객체   데이터만              데이터 + 규칙 + 행동
Service       규칙 + 흐름           흐름만 (오케스트레이션)
테스트        Service 통해야        도메인 단독 테스트 가능
재사용성      낮음                  높음
진입장벽      낮음                  높음
상태값 관리   String (오타 위험)    Enum (타입 안전)
```

### 어떤 게 더 좋은가?

> "무조건 하나가 좋다고 하기 어렵고 팀 숙련도에 따라 다르다. 숙련도가 낮은 팀이라면 Anemic이 진입장벽이 낮아서 더 나을 수 있다. 반면 숙련도가 높은 팀이라면 Rich Model이 더 좋다. Service가 오케스트레이션만 담당해서 흐름 파악이 쉽고, 수정 대상이 명확히 분리되어 유지보수가 효율적이다. 또한 도메인 객체를 외부 의존성 없이 단독으로 테스트할 수 있다."

------



## 도메인 설계 기준

### 1. 비즈니스 언어로 이름 짓기 (유비쿼터스 언어)

```java
// ❌ 기술 중심 네이밍
class QueueData { }
class UserInfo { }
class StatusCode { }

// ✅ 비즈니스 언어 네이밍
class WaitingQueue { }    // 대기열
class Customer { }        // 고객
class QueueStatus { }     // 대기열 상태
```

> "기획자/비즈니스 담당자와 같은 언어를 써야 한다" 코드를 보고 비즈니스 흐름이 읽혀야 한다.

### 2. Entity vs VO 판단 기준

```
Entity  → "이것을 구별해야 하는가?"
          예) 같은 상품/금액이어도 다른 주문 → Entity

VO      → "값 자체가 의미인가?"
          예) 10000원짜리 Money 2개는 완전히 같음 → VO
```

### 3. 어떤 행동을 도메인에 넣을지

```
도메인에 넣어야 할 것
  └── "이 객체의 상태를 변경하는 규칙인가?"
      예) 주문 취소 가능 여부 → Order가 알아야 함

Service에 남겨야 할 것
  └── "여러 도메인을 조율하는 흐름인가?"
      예) 주문 취소 후 결제 환불 → 여러 도메인 조율 = Service
```

### 4. Aggregate 경계 잡기

```
같은 Aggregate
  └── "함께 생성되고 함께 삭제되는가?"
      예) Order ↔ OrderItem → 같은 Aggregate

다른 Aggregate
  └── "독립적으로 존재할 수 있는가?"
      예) Order ↔ Customer → 다른 Aggregate (ID로만 참조)
```

### 5. 도메인 설계 자가 체크리스트

```
✅ 클래스명이 비즈니스 용어인가?
✅ setter 없이 의미있는 메서드명으로 상태를 변경하는가?
✅ 유효성 검증이 도메인 안에 있는가?
✅ DB, Spring 등 기술에 의존하지 않는가?
✅ 도메인 단독으로 테스트 가능한가?
✅ 외부는 Aggregate Root를 통해서만 접근하는가?
```

------



## JPA Entity vs 도메인 Entity

### 핵심 차이

```
JPA Entity    →  DB 테이블과 매핑되는 기술적 객체
도메인 Entity  →  비즈니스 규칙을 가진 순수한 객체
```

### JPA Entity를 도메인으로 쓰면 생기는 문제

```
1. DB 구조 변경이 도메인에 영향
   컬럼명 변경 → @Column 수정 → 도메인 코드 수정 ❌

2. JPA 때문에 도메인 설계가 제약됨
   JPA는 기본 생성자 필요    → 불변 객체 만들기 어려움
   JPA는 setter 필요한 경우  → 캡슐화 깨짐
   연관관계 매핑 강제         → 도메인 설계 왜곡

3. 도메인이 Spring/JPA에 의존하게 됨
   @Entity, @Column 등 JPA 어노테이션이 도메인에 침투 ❌
```

### Adapter에서 변환으로 해결

```java
// 1. 도메인 Entity — 순수함 ✅
class Order {
    private final OrderId orderId;
    private final UserId userId;
    private OrderStatus status;

    public void cancel() {
        validateCancellable();
        this.status = OrderStatus.CANCELLED;
    }
}

// 2. JPA Entity — DB 매핑만 담당
@Entity
@Table(name = "orders")
class OrderJpaEntity {
    @Id
    private String orderId;
    private String userId;
    private String status;

    // 도메인 → JPA Entity 변환
    public static OrderJpaEntity from(Order order) {
        OrderJpaEntity entity = new OrderJpaEntity();
        entity.orderId = order.getOrderId().getValue();
        entity.userId = order.getUserId().getValue();
        entity.status = order.getStatus().name();
        return entity;
    }

    // JPA Entity → 도메인 변환
    public Order toDomain() {
        return Order.restore(
            new OrderId(this.orderId),
            new UserId(this.userId),
            OrderStatus.valueOf(this.status)
        );
    }
}

// 3. Adapter에서 변환 담당
@Component
class JpaOrderAdapter implements OrderRepository {
    private final OrderJpaRepository jpaRepository;

    @Override
    public void save(Order order) {
        jpaRepository.save(OrderJpaEntity.from(order));
    }

    @Override
    public Order findById(OrderId orderId) {
        return jpaRepository.findById(orderId.getValue())
            .map(OrderJpaEntity::toDomain)
            .orElseThrow(() -> new OrderNotFoundException(orderId));
    }
}
```

### 전체 변환 흐름

```
Controller
    ↓ Request DTO
Service (UseCase)
    ↓ 도메인 Entity
Domain — Order.cancel() 등 비즈니스 규칙 실행
    ↓ 도메인 Entity
JpaOrderAdapter
    ↓ 변환 (from / toDomain)
OrderJpaEntity
    ↓
DB
```

------

## DDD + 헥사고날 연결

```
헥사고날                  DDD
──────────────────────────────────────────
Domain 레이어       =    Entity + VO + Aggregate
Port (in)           =    UseCase 인터페이스
Port (out)          =    Repository 인터페이스
Adapter (out)       =    Repository 구현체 (JPA Entity 변환 포함)
Domain Event        →    Adapter를 통해 Kafka/Spring으로 발행
```

------

------



## 적용 기준

### DDD + 헥사고날이 적합한 경우

```
✅ 복잡한 비즈니스 로직이 있는 시스템
✅ 마이크로서비스 아키텍처
✅ 장기적으로 유지보수할 프로젝트
✅ 팀 숙련도가 높은 경우
✅ DB/외부 API 교체 가능성이 있는 경우
```

### 단순 레이어드가 더 나은 경우

```
⚠️  단순 CRUD 애플리케이션
⚠️  빠른 MVP 개발
⚠️  소규모 팀 또는 단기 프로젝트
⚠️  비즈니스 로직이 거의 없는 경우
```



## 🎯 면접 예상 질문

### Q1. 레이어드 아키텍처와 헥사고날 아키텍처의 가장 큰 차이는?

> "레이어드 아키텍처는 의존성이 위에서 아래로 흐르기 때문에 DB나 외부 API가 변경되면 Service까지 영향이 전파됩니다. 반면 헥사고날은 도메인이 Port라는 인터페이스에만 의존하고, 실제 구현은 Adapter가 담당합니다. 의존성이 역전되어 있기 때문에 DB를 교체하거나 외부 API가 바뀌어도 도메인 코드는 전혀 수정할 필요가 없습니다."

### Q2. Port는 SOLID의 어떤 원칙과 관련이 깊은가?

> "DIP가 가장 직접적으로 연결됩니다. 도메인(고수준)이 Adapter(저수준)에 직접 의존하지 않고 Port(인터페이스)에만 의존하기 때문입니다. 그리고 DIP를 기반으로 새 Adapter를 추가할 때 기존 코드를 수정하지 않아도 되니 OCP도 자연스럽게 달성됩니다."

### Q3. Anemic Domain Model과 Rich Domain Model의 차이는?

> "Anemic Model은 도메인 객체가 데이터만 보유하고 비즈니스 규칙은 Service에 몰려있는 구조입니다. Rich Model은 도메인 객체가 데이터와 규칙, 행동을 스스로 가진 구조입니다. Rich Model에서는 Service가 오케스트레이션만 담당하므로 흐름 파악이 쉽고, 도메인을 단독으로 테스트할 수 있어 유지보수가 효율적입니다."

### Q4. JPA Entity와 도메인 Entity의 차이는?

> "JPA Entity는 DB 테이블과 매핑되는 기술적 객체고, 도메인 Entity는 비즈니스 규칙을 가진 순수한 객체입니다. JPA Entity를 도메인으로 쓰면 DB 구조 변경이 도메인에 영향을 주고, JPA의 기본 생성자 요구 등으로 도메인 설계가 제약됩니다. 헥사고날에서는 둘을 분리하고 Adapter에서 변환을 담당합니다."

### Q5. DDD와 헥사고날을 왜 함께 쓰는가?

> "DDD는 도메인을 올바르게 설계하는 방법론이고, 헥사고날은 그 도메인을 인프라로부터 보호하는 구조입니다. DDD만 쓰면 도메인은 풍부하지만 인프라에 오염될 수 있고, 헥사고날만 쓰면 구조는 있지만 도메인이 빈약할 수 있습니다. 함께 쓰면 도메인이 풍부하면서도 인프라로부터 완전히 격리되어 가장 이상적인 구조가 됩니다."

### Q6. Aggregate Root가 왜 필요한가?

> "Aggregate 내부의 일관성을 유지하기 위해서입니다. 외부에서 내부 Entity에 직접 접근하면 비즈니스 규칙을 우회할 수 있습니다. Root를 통해서만 접근하게 하면 항상 규칙을 거쳐야 하므로 데이터 일관성이 보장됩니다."
