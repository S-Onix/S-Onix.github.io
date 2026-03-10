---
title: Spring 깊이 이해하기 10편 - Hexagonal Architecture
date: 2026-03-04 17:50:46 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : Hexagonal 설계 구조 학습

## 📝 본문

## 1. Layered Architecture의 한계에서 출발

Layered에서는 Service가 JPA Repository에 직접 의존합니다. DB를 교체하면 비즈니스 로직이 있는 Service까지 수정해야 합니다. 비즈니스 규칙은 안 바뀌었는데 외부 기술 변경에 끌려가는 문제입니다.

```
Layered:  Service → JpaRepository (구체 기술에 직접 의존)
```

------



## 2. Hexagonal Architecture란?

비즈니스 로직(도메인)을 중심에 놓고, 외부 기술(DB, API, UI)을 **Port와 Adapter로 분리**하는 아키텍처 패턴입니다. Ports and Adapters 패턴이라고도 합니다.

핵심 철학: **"비즈니스 로직이 외부 기술에 의존하지 않는다"**

```
[외부] → Port → [도메인(핵심)] → Port → [외부]
Inbound Adapter → Port ← Domain → Port ← Outbound Adapter
```

------



## 3. Port — 도메인이 정의한 인터페이스

도메인이 외부와 소통하기 위해 자기가 직접 정의한 규격(인터페이스)입니다.



### Inbound Port (= Use Case)

외부에서 도메인으로 들어오는 규격. "도메인이 제공하는 기능 목록"입니다.

```java
public interface CreateOrderUseCase {
    OrderResponse createOrder(CreateOrderCommand command);
}

public interface GetOrderUseCase {
    OrderResponse getOrder(Long id);
}
```



### Outbound Port

도메인에서 외부로 나가는 규격. "도메인이 외부에 요청하는 것들"입니다.

```java
public interface SaveOrderPort {
    Order save(Order order);
}

public interface LoadOrderPort {
    Optional<Order> findById(Long id);
}

public interface RequestPaymentPort {
    PaymentResult requestPayment(PaymentRequest request);
}
```

------



## 4. Adapter — Port의 실제 구현체

Port라는 규격을 실제 기술로 구현한 것입니다. Adapter가 Port에 의존합니다.



### Inbound Adapter

외부 요청을 받아서 도메인의 Inbound Port(Use Case)를 호출합니다.

```java
@RestController
public class OrderController {
    private final CreateOrderUseCase createOrderUseCase;

    @PostMapping("/orders")
    public ResponseEntity<OrderResponse> create(@RequestBody OrderRequest request) {
        return ResponseEntity.ok(createOrderUseCase.createOrder(request.toCommand()));
    }
}
```



### Outbound Adapter

Outbound Port를 실제 기술로 구현합니다.

```java
@Repository
public class OrderJpaAdapter implements SaveOrderPort, LoadOrderPort {
    private final OrderJpaRepository jpaRepository;

    @Override
    public Order save(Order order) {
        OrderEntity entity = OrderEntity.from(order);
        return jpaRepository.save(entity).toDomain();
    }

    @Override
    public Optional<Order> findById(Long id) {
        return jpaRepository.findById(id).map(OrderEntity::toDomain);
    }
}
```

DB 교체 시 Adapter만 새로 만들면 됩니다.

```
SaveOrderPort ← OrderJpaAdapter (MySQL)      현재 사용 중
SaveOrderPort ← OrderMongoAdapter (MongoDB)   새로 만들어서 교체
```

------



## 5. Domain — 비즈니스 로직 핵심

Port(인터페이스)에만 의존하고, 외부 기술을 전혀 모릅니다.

```java
@Service
public class OrderService implements CreateOrderUseCase, GetOrderUseCase {
    private final SaveOrderPort saveOrderPort;
    private final LoadOrderPort loadOrderPort;
    private final RequestPaymentPort requestPaymentPort;

    @Override
    public OrderResponse createOrder(CreateOrderCommand command) {
        Order order = Order.create(command);       // 도메인 모델이 비즈니스 규칙 검증
        Order saved = saveOrderPort.save(order);   // Port를 통해 저장 (JPA인지 MongoDB인지 모름)
        requestPaymentPort.requestPayment(PaymentRequest.from(saved));
        return OrderResponse.from(saved);
    }
}
```

------



## 6. 의존성 역전 (Dependency Inversion)

고수준 모듈(도메인)이 저수준 모듈(DB, API)에 직접 의존하지 않고, 둘 다 추상화(Port)에 의존하게 만드는 원칙입니다.

```
Layered:     Service ──→ JpaRepository     (고수준이 저수준에 직접 의존)
Hexagonal:   Service ──→ Port ←── JpaAdapter  (둘 다 추상화에 의존)
```

의존 방향이 항상 도메인(안쪽)을 향하므로, 외부 기술이 바뀌어도 도메인은 영향을 받지 않습니다.

------



## 7. 패키지 구조

```
com.example.order/
├── domain/                          ← 핵심 (외부 의존 없음)
│   ├── Order.java
│   └── OrderStatus.java
├── application/                     ← Use Case + Port 정의
│   ├── port/
│   │   ├── in/
│   │   │   ├── CreateOrderUseCase.java
│   │   │   └── GetOrderUseCase.java
│   │   └── out/
│   │       ├── SaveOrderPort.java
│   │       └── LoadOrderPort.java
│   └── service/
│       └── OrderService.java
└── adapter/                         ← 외부 기술 구현
    ├── in/web/
    │   └── OrderController.java
    └── out/persistence/
        ├── OrderJpaAdapter.java
        └── OrderEntity.java
```

------



## 8. Layered vs Hexagonal 비교

|                       | Layered                    | Hexagonal                     |
| --------------------- | -------------------------- | ----------------------------- |
| **의존 방향**         | 위에서 아래로              | 항상 도메인(안쪽)을 향함      |
| **Service 의존 대상** | JPA Repository (구체 기술) | Port (인터페이스)             |
| **DB 교체 시**        | Service까지 수정           | Adapter만 새로 만듦           |
| **테스트**            | JPA Mock 필요              | Port Mock만 있으면 됨         |
| **학습 곡선**         | 낮음                       | 높음                          |
| **적합한 상황**       | 단순 CRUD, 빠른 개발       | 복잡한 도메인, 마이크로서비스 |

------



## 9. 실무에서의 현실적 판단

**Hexagonal이 적합한 경우**: 도메인 로직이 복잡한 프로젝트(금융, 결제 등), 외부 시스템 연동이 많은 마이크로서비스, DB 교체 가능성이 있는 장기 프로젝트. 팀원이 구조에 익숙해야 효과가 있습니다.

**Layered가 적합한 경우**: 단순 CRUD 중심, 빠르게 MVP를 만들어야 하는 경우. 학습 곡선이 낮아 개발 기간을 단축할 수 있습니다.

**현실적 조언**: Layered로 시작하되 Service가 인터페이스에 의존하도록 하고, 도메인이 복잡해지면 점진적으로 Hexagonal로 전환합니다.

------



## 핵심 키워드

| 카테고리      | 키워드                                                  |
| ------------- | ------------------------------------------------------- |
| **핵심 개념** | Hexagonal Architecture, Ports and Adapters, 도메인 중심 |
| **Port**      | Inbound Port(Use Case), Outbound Port, 인터페이스       |
| **Adapter**   | Inbound Adapter(Controller), Outbound Adapter(JPA Impl) |
| **원칙**      | Dependency Inversion, 의존성이 안쪽을 향함              |
| **도메인**    | Rich Domain Model, 순수 Java, 프레임워크 비의존         |
| **비교**      | Layered vs Hexagonal, DB 교체 시나리오                  |
| **연관 개념** | DDD, CQRS, Use Case, Command/Query 분리                 |

## 🎯 면접 예상 질문

### Q1. Hexagonal Architecture란 무엇이며, Layered Architecture와의 핵심 차이는 무엇인가요?

**모범 답안:**

> Hexagonal Architecture는 비즈니스 로직(도메인)을 중심에 놓고, 외부 기술(DB, API, UI)을 Port와 Adapter로 분리하는 아키텍처 패턴입니다. Layered Architecture와의 핵심 차이는 의존 방향입니다. Layered에서는 Service가 JPA Repository에 직접 의존하지만, Hexagonal에서는 Service가 Port(인터페이스)에만 의존하고 실제 구현은 Adapter가 담당합니다. 따라서 DB나 외부 API가 변경되어도 비즈니스 로직은 수정할 필요가 없습니다.

**암기:** "도메인 중심 + Port/Adapter 분리 + 의존성이 항상 안쪽(도메인)을 향함"

### Q2. Port와 Adapter가 무엇인지 설명해주세요.

**모범 답안:**

> Port는 도메인이 외부와 소통하기 위해 정의한 인터페이스입니다. 외부에서 도메인으로 들어오는 Inbound Port(Use Case)와, 도메인에서 외부로 나가는 Outbound Port가 있습니다. Adapter는 Port를 실제 기술로 구현한 것입니다. Inbound Adapter(Controller)는 HTTP 요청을 받아 Use Case를 호출하고, Outbound Adapter(JpaAdapter)는 Port를 JPA로 구현합니다. 의존 방향은 Adapter가 Port에 의존합니다.

**주의할 점:**

- "Port가 Adapter에 의존한다"는 틀림. Adapter가 Port에 의존하는 것이 맞음

### Q3. 의존성 역전(Dependency Inversion)이란 무엇이며, Hexagonal에서 어떻게 적용되나요?

**모범 답안:**

> 의존성 역전이란 고수준 모듈(도메인)이 저수준 모듈(DB, API)에 직접 의존하지 않고, 둘 다 추상화(Port)에 의존하게 만드는 원칙입니다. Layered에서는 Service가 JPA Repository에 직접 의존했지만, Hexagonal에서는 Service가 Port(인터페이스)에 의존하고, Adapter도 Port를 구현하여 Port에 의존합니다. 의존 방향이 항상 도메인(안쪽)을 향하므로 외부 기술이 바뀌어도 도메인은 영향을 받지 않습니다.

### Q4. Hexagonal Architecture에서 DB를 교체하면 어떤 코드를 수정해야 하나요?

**모범 답안:**

> Outbound Adapter만 새로 만들면 됩니다. 예를 들어 MySQL에서 MongoDB로 교체한다면, OrderMongoAdapter를 만들어 기존 SaveOrderPort를 구현하면 됩니다. Port(인터페이스)는 그대로이므로 Service와 도메인 코드는 수정할 필요가 없습니다. 이것이 Layered Architecture와의 가장 큰 차이점입니다.

### Q5. 실무에서 Hexagonal Architecture는 언제 적합하고, 언제 Layered가 적합한가요?

**모범 답안:**

> Hexagonal은 도메인 로직이 복잡한 프로젝트(금융, 결제 등), 외부 시스템 연동이 많은 마이크로서비스, DB 교체 가능성이 있는 장기 프로젝트에 적합합니다. 단, 팀원들이 구조에 익숙해야 효과가 있습니다. Layered는 단순 CRUD 중심의 프로젝트, 빠르게 MVP를 만들어야 하는 경우에 적합합니다. 학습 곡선이 낮아 개발 기간을 단축할 수 있습니다. 실무에서는 Layered로 시작하되 Service가 인터페이스에 의존하도록 하고, 복잡해지면 점진적으로 Hexagonal로 전환하는 것이 현실적입니다.

**암기:**

- Hexagonal → "복잡한 도메인, 마이크로서비스, 장기 유지보수"
- Layered → "단순 CRUD, 빠른 개발, 낮은 학습 곡선"
