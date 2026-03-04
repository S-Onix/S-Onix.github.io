---
title: Spring 깊이 이해하기 9편 - Layered Architecture
date: 2026-03-04 16:39:46 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : 기본 설계 구조 학습

## 📝 본문

## 1. 왜 계층을 나누는가?

모든 코드를 한 곳에 넣으면 다음 문제가 발생합니다.

- **변경의 파급 효과**: DB 변경, API 변경, 비즈니스 규칙 변경이 전부 같은 클래스에 영향
- **테스트 불가**: 비즈니스 로직만 테스트하고 싶은데 DB와 외부 API가 엮여있음
- **코드 재사용 불가**: 같은 로직이 필요하면 복붙해야 함
- **협업 어려움**: 여러 개발자가 같은 파일을 수정하면 충돌 발생

------



## 2. Layered Architecture란?

애플리케이션을 역할별 계층으로 분리하여, 각 계층이 자신의 책임에만 집중하도록 하는 아키텍처 패턴입니다.

```
┌─────────────────────────────────────────┐
│  Presentation Layer (@Controller)       │  ← 요청/응답 처리
├─────────────────────────────────────────┤
│  Business Layer (@Service)              │  ← 비즈니스 로직
├─────────────────────────────────────────┤
│  Data Access Layer (@Repository)        │  ← DB 접근
└─────────────────────────────────────────┘
```

------



## 3. 각 계층의 역할

### Presentation Layer (Controller)

- HTTP 요청 파라미터 수신 및 검증
- Service 호출
- HTTP 응답 코드와 응답 본문 반환
- **하면 안 되는 일**: 비즈니스 로직, 직접 DB 접근

### Business Layer (Service)

- 비즈니스 규칙 검증 및 실행
- 트랜잭션 관리 (@Transactional)
- 여러 Repository나 다른 Service를 조합
- **하면 안 되는 일**: HTTP 관련 처리, 직접 SQL 작성

### Data Access Layer (Repository)

- DB CRUD 연산
- 쿼리 작성 및 실행 (JPA, QueryDSL 등)
- **하면 안 되는 일**: 비즈니스 로직, HTTP 관련 처리

------



## 4. 계층 간 데이터 전달 — DTO

Entity를 직접 노출하지 않고 DTO(Data Transfer Object)를 사용합니다.

```
Client ←→ [Controller] ←→ [Service] ←→ [Repository] ←→ DB
       RequestDTO          Entity          Entity
       ResponseDTO
```

Entity를 직접 반환하면 안 되는 이유:

- **보안**: password, deletedAt 같은 내부 필드가 클라이언트에 노출
- **API 스펙 결합**: Entity 필드명 변경이 곧 API 변경이 됨
- **순환 참조**: JPA 양방향 관계에서 JSON 직렬화 시 무한 루프 발생 가능

------



## 5. 의존 방향 규칙

```
Controller → Service → Repository (위에서 아래로만)
```

역방향 의존을 금지하는 이유: 변경이 연쇄적으로 퍼지는 것을 방지합니다. 단방향을 지키면 DB 변경 시 Repository만, 비즈니스 규칙 변경 시 Service만, API 변경 시 Controller만 수정하면 됩니다.

------



## 6. 실무 확장 구조

```
Presentation Layer
  ├── Controller (REST API)
  └── GlobalExceptionHandler
Business Layer
  ├── Service (비즈니스 로직)
  ├── Facade (여러 Service 조합)
  └── Validator (복잡한 검증 로직)
Data Access Layer
  ├── Repository (DB 접근, QueryDSL 포함)
  └── Client (외부 API 호출)
Domain
  ├── Entity (도메인 모델)
  └── Enum, VO (값 객체)
```

### QueryDSL 위치

QueryDSL은 Data Access Layer(Repository)에 위치합니다. Custom Repository 패턴으로 구현합니다.

```java
public interface OrderRepository extends JpaRepository<Order, Long>, OrderRepositoryCustom {
    // JpaRepository: 기본 CRUD
    // OrderRepositoryCustom: QueryDSL 복잡 쿼리
}
```

Service는 QueryDSL의 존재를 알 필요 없이 Repository 메서드만 호출합니다.

------



## 7. Layered Architecture의 한계

- **DB 중심 설계**: 테이블부터 설계하고 위로 올라가는 패턴, 비즈니스 로직보다 DB 구조에 끌려감
- **Service 비대화**: 비즈니스 로직이 모두 Service에 집중되어 "God Service" 문제 발생
- **인프라 의존성**: Service가 Repository(JPA)에 직접 의존하므로 DB 교체 시 Service까지 영향

이 한계를 해결하기 위해 Hexagonal Architecture가 등장했습니다.

------



## 핵심 키워드

| 카테고리        | 키워드                                                       |
| --------------- | ------------------------------------------------------------ |
| **핵심 개념**   | Layered Architecture, 관심사 분리, 단방향 의존               |
| **3계층**       | Presentation(@Controller), Business(@Service), Data Access(@Repository) |
| **데이터 전달** | DTO, Entity 캡슐화, RequestDTO, ResponseDTO                  |
| **실무 확장**   | Facade 패턴, Custom Repository, QueryDSL                     |
| **한계**        | DB 중심 설계, Service 비대화, 인프라 의존성                  |



## 🎯 면접 예상 질문

### Q1. Layered Architecture란 무엇이며, 왜 계층을 나누나요?

**모범 답안:**

> Layered Architecture는 애플리케이션을 역할별 계층으로 분리하여, 각 계층이 자신의 책임에만 집중하도록 하는 아키텍처 패턴입니다. 계층을 나누는 이유는 첫째, 변경의 영향 범위를 제한하기 위해서입니다. DB가 변경되면 Repository만, 비즈니스 규칙이 바뀌면 Service만 수정하면 됩니다. 둘째, 테스트 용이성입니다. 비즈니스 로직만 독립적으로 단위 테스트할 수 있습니다. 셋째, 협업 편의성입니다. 각 계층을 다른 개발자가 독립적으로 작업할 수 있습니다.

**암기:** "변경 범위 제한, 테스트 용이, 협업 편의"

### Q2. Spring에서 일반적으로 사용하는 3계층과 각 계층의 역할을 설명해주세요.

**모범 답안:**

> Spring에서는 Presentation, Business, Data Access 3계층을 사용합니다. Presentation Layer는 @Controller로, HTTP 요청을 받고 응답을 반환하는 진입점입니다. Business Layer는 @Service로, 비즈니스 로직과 트랜잭션을 관리합니다. Data Access Layer는 @Repository로, DB와의 통신을 담당합니다. 각 계층은 Controller → Service → Repository 방향으로만 의존합니다.

### Q3. Entity를 Controller에서 직접 반환하면 안 되는 이유는 무엇인가요?

**모범 답안:**

> Entity를 직접 반환하면 안 되는 이유는 세 가지입니다. 첫째, 보안 문제입니다. Entity에 password, deletedAt 같은 내부 필드가 클라이언트에 그대로 노출됩니다. 둘째, API 스펙 결합입니다. Entity 필드명을 바꾸면 API 응답도 바뀌어서, DB 구조 변경이 곧 API 변경이 됩니다. 셋째, 순환 참조 위험입니다. JPA Entity 간 양방향 관계가 있으면 JSON 직렬화 시 무한 루프가 발생할 수 있습니다. 그래서 DTO를 사용하여 필요한 데이터만 선별하여 반환합니다.

**암기:** "보안, API 결합, 순환 참조 → DTO로 해결"

### Q4. 계층 간 의존 방향 규칙은 무엇이며, 왜 지켜야 하나요?

**모범 답안:**

> 의존 방향은 Controller → Service → Repository로 위에서 아래로만 향합니다. 역방향 의존이 생기면 변경이 연쇄적으로 퍼지기 때문입니다. 단방향을 지키면 DB 스키마 변경 시 Repository만, 비즈니스 규칙 변경 시 Service만, API 응답 변경 시 Controller만 수정하면 되어 각 계층이 독립적으로 변경 가능합니다.

### Q5. Layered Architecture의 한계는 무엇인가요?

**모범 답안:**

> Layered Architecture의 한계는 크게 세 가지입니다. 첫째, DB 중심 설계입니다. Repository가 가장 아래에 있다 보니 테이블부터 설계하고 위로 올라가는 패턴이 되어, 비즈니스 로직보다 DB 구조에 끌려가기 쉽습니다. 둘째, Service 비대화입니다. 비즈니스 로직이 모두 Service에 집중되면서 하나의 Service가 수천 줄이 되는 "God Service" 문제가 발생합니다. 셋째, 인프라 의존성입니다. Service가 Repository(JPA)에 직접 의존하므로, DB를 교체하면 Service까지 영향을 받습니다. 이러한 한계를 해결하기 위해 Hexagonal Architecture가 등장했습니다.

**암기:** "DB 중심, Service 비대화, 인프라 의존 → Hexagonal로 해결"
