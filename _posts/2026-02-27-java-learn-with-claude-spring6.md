---
title: Spring 깊이 이해하기 6편 - Dependency Injection (DI)
date: 2026-02-27 17:28:23 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : DI 이해하기

## 📝 본문

## 1. Dependency(의존성)란?

내가 동작하려면 다른 누군가가 필요한 상태를 의미합니다.

```java
public class OrderService {
    private final OrderRepository repository = new JdbcOrderRepository();
}
```

`OrderService`가 동작하려면 `JdbcOrderRepository`가 반드시 있어야 합니다. 이때 "OrderService는 JdbcOrderRepository에 의존한다"라고 말합니다.

------



## 2. 강결합(Tight Coupling)의 문제

```java
public class OrderService {
    private final OrderRepository repository = new JdbcOrderRepository(); // 직접 생성
}
```

구현체를 직접 생성하면 다음과 같은 문제가 발생합니다.

- **구현체 변경이 어렵다**: DB를 변경하면 OrderService 코드를 직접 수정해야 함
- **테스트가 어렵다**: `new JdbcOrderRepository()`가 진짜 DB에 연결을 시도하여 단위 테스트가 불가
- **OCP 위반**: 확장에는 열려있고 수정에는 닫혀있어야 하는데, 구현체 변경 시 기존 코드를 수정해야 함

------



## 3. DI — 외부에서 끼워넣기

객체가 자신의 의존성을 직접 생성하지 않고, 외부에서 주입받는 패턴입니다.

```java
@Service
public class OrderService {
    private final OrderRepository repository;

    public OrderService(OrderRepository repository) {  // 인터페이스에만 의존
        this.repository = repository;
    }
}
```

`OrderService`는 `OrderRepository` 인터페이스에만 의존하므로, 실제 구현체가 무엇인지 알지 못합니다. 이것이 **Loose Coupling(느슨한 결합)**이며, DI의 핵심 가치입니다.

------



## 4. IoC (Inversion of Control)

객체의 생성과 의존성 연결의 제어권이 개발자에서 프레임워크로 넘어간 것입니다. DI는 IoC를 구현하는 구체적인 방법론입니다.

```
IoC (큰 개념): 제어권을 프레임워크에 위임
 └── DI (구현 방법): 의존성을 외부에서 주입하는 것
```

------



## 5. IoC Container (= ApplicationContext)

Bean의 생성, 의존성 주입, 생명주기를 관리하는 Spring의 핵심 엔진입니다.

```
BeanFactory (기본 기능)
  └── ApplicationContext (BeanFactory 확장)
        ├── 환경 변수 처리 (Environment)
        ├── 메시지 국제화 (MessageSource)
        ├── 이벤트 발행 (ApplicationEventPublisher)
        └── 리소스 로딩 (ResourceLoader)
```

IoC Container가 하는 일은 다음과 같습니다.

- **Bean 생성**: `@Component`, `@Service`, `@Repository` 등이 붙은 클래스를 찾아 객체를 생성
- **의존성 주입**: 생성자 파라미터를 보고 적절한 Bean을 찾아 주입
- **생명주기 관리**: Bean의 초기화(`@PostConstruct`)와 소멸(`@PreDestroy`)을 관리

------



## 6. Bean

Spring IoC Container에 등록되어 관리되는 객체입니다.

### Bean 등록 방법

**컴포넌트 스캔 (자동 등록)**

```java
@Component    // 범용
@Service      // 비즈니스 로직 계층
@Repository   // 데이터 접근 계층
@Controller   // 웹 요청 처리 계층
```

**@Configuration + @Bean (수동 등록)**

```java
@Configuration
public class AppConfig {
    @Bean
    public OrderRepository orderRepository() {
        return new JdbcOrderRepository(dataSource());
    }
}
```

### Bean 생명주기

```
Container 시작 → @Component 스캔 → Bean 객체 생성 → 의존성 주입(DI)
→ @PostConstruct → 사용 → @PreDestroy → Container 종료
```

### Bean Scope

| Scope         | 설명                                      |
| ------------- | ----------------------------------------- |
| **singleton** | 컨테이너 전체에서 딱 하나만 생성 (기본값) |
| **prototype** | 요청할 때마다 새로운 객체 생성            |
| **request**   | HTTP 요청 하나당 하나 생성                |
| **session**   | HTTP 세션 하나당 하나 생성                |

기본 Scope인 Singleton에서는 여러 스레드가 하나의 Bean을 공유하므로, Bean은 반드시 **Stateless(무상태)**로 설계해야 합니다.

------



## 7. 주입 방식 3가지

### 생성자 주입 (권장)

```java
@Service
public class OrderService {
    private final OrderRepository repository;

    public OrderService(OrderRepository repository) {
        this.repository = repository;
    }
}
```

### 세터 주입

```java
@Service
public class OrderService {
    private OrderRepository repository;

    @Autowired
    public void setRepository(OrderRepository repository) {
        this.repository = repository;
    }
}
```

### 필드 주입 (비권장)

```java
@Service
public class OrderService {
    @Autowired
    private OrderRepository repository;
}
```

### 비교

|                      | 생성자 주입 | 세터 주입 | 필드 주입 |
| -------------------- | ----------- | --------- | --------- |
| **불변성 (final)**   | ✅           | ❌         | ❌         |
| **컴파일 타임 검증** | ✅           | ❌         | ❌         |
| **순환 참조 감지**   | ✅ 시작 시   | ❌ 런타임  | ❌ 런타임  |
| **테스트 편의성**    | ✅           | ⚠️         | ❌         |
| **권장 여부**        | ✅ 권장      | ⚠️ 선택적  | ❌ 비권장  |

------



## 8. @Qualifier와 @Primary

같은 타입의 Bean이 여러 개일 때 `NoUniqueBeanDefinitionException`이 발생합니다.

- **@Primary**: 기본값으로 선택될 Bean 지정
- **@Qualifier**: 특정 Bean을 명시적으로 지정 (@Primary보다 우선순위 높음)

```java
@Repository
@Primary
public class JpaOrderRepository implements OrderRepository { }

@Repository
public class JdbcOrderRepository implements OrderRepository { }

@Service
public class OrderService {
    // @Primary에 의해 JpaOrderRepository 주입
    public OrderService(OrderRepository repository) { ... }
}

@Service
public class LegacyOrderService {
    // @Qualifier가 @Primary를 오버라이드
    public LegacyOrderService(@Qualifier("jdbcOrderRepository") OrderRepository repository) { ... }
}
```

------



## 9. 순환 참조 (Circular Dependency)

A가 B에 의존하고, B가 다시 A에 의존하는 순환 구조입니다. 생성자 주입에서는 애플리케이션 시작 시점에 바로 감지됩니다.

해결 방법은 공통 로직을 별도 서비스로 분리하거나, 이벤트 기반으로 직접 의존을 끊는 것입니다.

------



## 10. 심화: @Configuration과 CGLIB Proxy

`@Configuration` 클래스는 CGLIB Proxy로 감싸져서, `@Bean` 메서드가 여러 번 호출되어도 이미 생성된 Bean이 있으면 기존 것을 반환합니다. `@Component` 안의 `@Bean`은 이 보장이 없습니다.

------



## 11. 심화: Profile별 Bean 전환

```java
@Repository
@Profile("prod")
public class JpaOrderRepository implements OrderRepository { }

@Repository
@Profile("local")
public class InMemoryOrderRepository implements OrderRepository { }
```

코드 수정 없이 환경별로 다른 구현체를 주입할 수 있습니다.

------



## 핵심 키워드

| 카테고리       | 키워드                                                       |
| -------------- | ------------------------------------------------------------ |
| **핵심 개념**  | Dependency Injection, Tight Coupling, Loose Coupling, OCP    |
| **IoC**        | IoC (Inversion of Control), IoC Container, ApplicationContext, BeanFactory |
| **Bean**       | Bean, Component Scan, @Component, @Service, @Repository, @Configuration, @Bean |
| **Bean Scope** | Singleton, Prototype, Stateless, @PostConstruct, @PreDestroy |
| **주입 방식**  | Constructor Injection, Setter Injection, Field Injection, @Autowired |
| **Bean 선택**  | @Qualifier, @Primary, NoUniqueBeanDefinitionException        |
| **순환 참조**  | Circular Dependency                                          |
| **심화**       | CGLIB Proxy, BeanDefinition, @Profile                        |



## 🎯 면접 예상 질문

### Q1. DI(Dependency Injection)란 무엇이며, 왜 사용하나요?

**모범 답안:**

> DI는 객체가 자신의 의존성을 직접 생성하지 않고, 외부에서 주입받는 패턴입니다. DI의 궁극적 목표는 느슨한 결합(Loose Coupling)입니다. 구체 클래스가 아닌 인터페이스에 의존하므로, 새로운 구현체가 추가되어도 기존 코드를 수정할 필요가 없습니다. 이는 OCP(개방-폐쇄 원칙)를 준수하게 해주며, 테스트 시 Mock 객체를 주입할 수 있어 단위 테스트가 용이해집니다.

**주의할 점:**

- "의존성"은 "내가 동작하려면 다른 누군가가 필요한 상태"이고, "주입"은 "그 필요한 것을 외부에서 넣어주는 행위"입니다. 면접에서는 Dependency와 Injection 둘 다 설명해야 합니다.

### Q2. IoC(Inversion of Control)란 무엇이며, DI와의 관계를 설명해주세요.

**모범 답안:**

> IoC는 객체의 생성과 의존성 연결의 제어권이 개발자에서 프레임워크로 넘어간 것을 의미합니다. DI는 이 IoC를 구현하는 구체적인 방법론입니다. 즉 IoC가 "제어를 넘긴다"는 큰 개념이라면, DI는 "의존성을 외부에서 주입한다"는 구체적 기법입니다. Spring에서는 IoC Container(ApplicationContext)가 Bean의 생성, 의존성 주입, 생명주기를 관리합니다.

### Q3. Spring의 Bean이란 무엇이며, Bean의 기본 Scope는 무엇인가요? 그리고 그 Scope에서 주의할 점은 무엇인가요?

**모범 답안:**

> Bean은 Spring IoC Container가 관리하는 객체입니다. Bean의 기본 Scope는 Singleton으로, 애플리케이션 전체에서 딱 하나만 생성되어 모든 곳에서 공유됩니다. Singleton이기 때문에 여러 스레드가 하나의 Bean 객체를 동시에 사용합니다. 따라서 Bean은 반드시 Stateless(무상태)로 설계해야 합니다. 변경 가능한 인스턴스 변수를 두면 동시성 버그가 발생할 수 있습니다.

**꼬리 질문 대비:**

- "Singleton 외에 다른 Scope는?" → prototype(매번 새 객체), request(HTTP 요청당 하나), session(세션당 하나)

### Q4. 의존성 주입 방식 3가지를 설명하고, 생성자 주입이 권장되는 이유를 말해주세요.

**모범 답안:**

> 의존성 주입 방식에는 생성자 주입, 세터 주입, 필드 주입이 있습니다. 생성자 주입이 권장되는 이유는 세 가지입니다. 첫째, **불변성 보장**입니다. `final` 키워드를 사용할 수 있어 주입된 의존성이 변경되지 않음을 보장합니다. 둘째, **컴파일 타임 검증**입니다. 필수 의존성이 빠지면 컴파일 시점에 에러가 발생하여, 런타임 NPE를 방지합니다. 셋째, **순환 참조 조기 감지**입니다. 순환 참조가 있으면 애플리케이션 시작 시점에 바로 실패하여 설계 문제를 조기에 발견할 수 있습니다.

**주의할 점:**

- `@Autowired`는 주입 "방식"이 아니라, 자동 주입을 알리는 "어노테이션"입니다. 3가지 방식 모두에서 사용 가능합니다.
- 생성자 주입 권장 이유 암기 팁: **"불변, 컴파일, 순환"**

### Q5. 같은 타입의 Bean이 여러 개일 때 어떤 문제가 발생하며, 어떻게 해결하나요?

**모범 답안:**

> 같은 타입의 Bean이 여러 개 등록되면 Spring이 어떤 Bean을 주입할지 알 수 없어 `NoUniqueBeanDefinitionException`이 발생합니다. 이를 해결하는 방법은 두 가지입니다. `@Primary`는 기본적으로 선택될 Bean을 지정하고, `@Qualifier`는 특정 Bean을 명시적으로 지정합니다. `@Qualifier`가 `@Primary`보다 우선순위가 높아, 기본값은 `@Primary`로 두고 특수한 경우에만 `@Qualifier`로 오버라이드하는 패턴을 씁니다.
