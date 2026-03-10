---
title: [설계의 기본] - SOLID 원칙 완벽 정리
date: 2026-03-10 17:36:08 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 설계]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답을 활용한 좋은 설계를 하는 방법 숙지
- 목표 : 설계에 대한 기본기를 갖춘다.

## 📝 본문

## SRP

## 단일 책임 원칙 (Single Responsibility Principle)

> **"클래스는 변경되는 이유가 단 하나여야 한다"** — Robert C. Martin

### 핵심 개념

- **책임 = 변경의 이유 = 특정 액터(이해관계자)의 요구**
- 기능이 많다고 SRP 위반이 아니라, **서로 다른 이해관계자의 요구로 변경**될 수 있다면 위반



### ❌ 위반 코드

```java
class UserService {
    public void register(String email, String rawPassword) {
        // 1. 비밀번호 유효성 검증 → 보안/기획팀 요구로 변경
        if (rawPassword.length() < 8) {
            throw new IllegalArgumentException("비밀번호는 8자 이상");
        }
        // 2. 비밀번호 암호화 → 개발팀 요구로 변경
        String encoded = passwordEncoder.encode(rawPassword);
        // 3. 저장 → 개발팀 요구로 변경
        userRepository.save(new User(email, encoded));
        // 4. 환영 이메일 발송 → 마케팅팀 요구로 변경
        emailSender.sendWelcomeEmail(email);
    }
}
// 변경 이유가 4가지 → SRP 위반 ❌
```

### ✅ 준수 코드

```java
class PasswordPolicy {
    public void validate(String rawPassword) {
        if (rawPassword.length() < 8)
            throw new IllegalArgumentException("비밀번호는 8자 이상");
    }
}

class UserRegistrationService {  // 오케스트레이션만 담당
    private final PasswordPolicy passwordPolicy;
    private final PasswordEncoder passwordEncoder;
    private final UserRepository userRepository;
    private final UserNotificationService notificationService;

    public void register(String email, String rawPassword) {
        passwordPolicy.validate(rawPassword);
        String encoded = passwordEncoder.encode(rawPassword);
        userRepository.save(new User(email, encoded));
        notificationService.sendWelcome(email);
    }
}
// 변경 이유: "회원가입 흐름이 바뀔 때" 단 하나 ✅
```

### 오케스트레이션이란?

지휘자처럼 **어떻게(HOW) 하는지는 모르고, 무엇을(WHAT) 어떤 순서로** 할지만 아는 것. 각 전문 클래스에게 역할을 위임하고 흐름만 조율한다.

### 장점

- **가독성** — 클래스명이 곧 기능을 나타냄
- **변경 영향 최소화** — 변경 시 해당 클래스만 수정
- **독립 테스트** — 각 클래스를 별도로 테스트 가능

### 면접 포인트

> "SRP에서 책임이란 무엇인가요?"

**"책임 = 변경의 이유 = 특정 액터(이해관계자)의 요구"** 같은 기능이라도 변경을 요구하는 주체가 다르면 책임이 다르다.

------



## OCP

## 개방/폐쇄 원칙 (Open/Closed Principle)

> **"확장에는 열려있고, 수정에는 닫혀있어야 한다"**

### 핵심 개념

- **새 요구사항 = 새 코드 추가 O, 기존 코드 수정 X**
- 인터페이스로 확장 포인트를 열어두고, 의존성 주입으로 구현체를 외부에서 결정



### ❌ 위반 코드

```java
class NotificationService {
    public void send(String type, String message) {
        if (type.equals("EMAIL")) {
            System.out.println("이메일 발송: " + message);
        } else if (type.equals("SMS")) {
            System.out.println("SMS 발송: " + message);
        }
        // Slack 추가 시 → 기존 코드 수정 필요 ❌
    }
}
```

### ✅ 준수 코드

```java
interface NotificationSender {
    void send(String message);
}

class EmailNotificationSender implements NotificationSender {
    public void send(String message) {
        System.out.println("이메일 발송: " + message);
    }
}

class KakaoNotificationSender implements NotificationSender {
    public void send(String message) {
        System.out.println("카카오톡 발송: " + message);
    }
}

// Slack 추가? → SlackNotificationSender 클래스만 추가 ✅
class SlackNotificationSender implements NotificationSender {
    public void send(String message) {
        System.out.println("Slack 발송: " + message);
    }
}

class NotificationService {
    private final NotificationSender sender;

    public NotificationService(NotificationSender sender) {
        this.sender = sender;
    }

    public void send(String message) {
        sender.send(message);  // 기존 코드 수정 없음 ✅
    }
}
```



### 장점

- **사이드 이펙트 Zero** — 기존 코드를 건드리지 않으므로 기존 기능이 깨질 위험 없음
- **독립 테스트** — 새 클래스만 테스트하면 됨
- **가독성** — 클래스명이 곧 기능

### 면접 포인트

> "OCP를 지키면 클래스가 너무 많아지지 않나요?"

"클래스 수는 늘어나지만 클래스명이 곧 역할을 나타내서 가독성이 높아지고, 기존 코드를 전혀 건드리지 않기 때문에 사이드 이펙트 위험이 없습니다. 새 기능 추가 시 해당 클래스만 테스트하면 되므로 유지보수가 편해집니다."

------



## LSP

## 리스코프 치환 원칙 (Liskov Substitution Principle)

> **"부모 클래스를 사용하는 곳에 자식 클래스를 넣어도 동작이 같아야 한다"**

### 핵심 개념

- **자식은 부모의 계약을 반드시 지켜야 한다**
- 자식이 부모를 완전히 대체할 수 있어야 함



### ❌ 위반 코드 (직사각형/정사각형 예시)

```java
class Rectangle {
    protected int width, height;
    public void setWidth(int width) { this.width = width; }
    public void setHeight(int height) { this.height = height; }
    public int getArea() { return width * height; }
}

class Square extends Rectangle {
    @Override
    public void setWidth(int width) {
        this.width = width;
        this.height = width;  // 강제로 같이 변경 ❌
    }
}

void resize(Rectangle rect) {
    rect.setWidth(5);
    rect.setHeight(3);
    // Rectangle이면 넓이 = 15 ✅
    // Square이면 넓이 = 9  ❌ → 부모 계약 위반!
}
```

### ✅ 준수 코드

```java
interface Shape {
    int getArea();
}

class Rectangle implements Shape {
    private int width, height;
    public Rectangle(int width, int height) {
        this.width = width;
        this.height = height;
    }
    public int getArea() { return width * height; }
}

class Square implements Shape {
    private int side;
    public Square(int side) { this.side = side; }
    public int getArea() { return side * side; }
}
// Shape 자리에 Rectangle이든 Square든 계약대로 동작 ✅
```



### 위반 신호

- 자식 클래스에서 `UnsupportedOperationException` 던지기
- 자식 클래스에서 빈 메서드로 오버라이드
- 부모 자리에 자식을 넣었을 때 예상과 다른 결과

### 면접 포인트

> "LSP와 OCP의 차이는?"

|        | OCP                      | LSP                          |
| ------ | ------------------------ | ---------------------------- |
| 관심사 | 확장 방법                | 상속 올바름                  |
| 질문   | 수정 없이 확장 가능한가? | 자식이 부모 계약을 지키는가? |
| 해결책 | 인터페이스로 확장 포인트 | 상속 구조 재설계             |

------



## ISP

## 인터페이스 분리 원칙 (Interface Segregation Principle)

> **"클라이언트는 자신이 사용하지 않는 메서드에 의존하면 안 된다"**

### 핵심 개념

- **인터페이스를 뚱뚱하게 만들지 말고 작게 쪼개라**
- 구현체가 필요 없는 메서드를 억지로 구현하는 상황 = ISP 위반



### ❌ 위반 코드

```java
interface Animal {
    void eat();
    void fly();    // 펭귄은 필요 없음 ❌
    void swim();   // 독수리는 필요 없음 ❌
    void run();
}

class Penguin implements Animal {
    public void fly() {
        throw new UnsupportedOperationException("펭귄은 못 날아요"); // ❌
    }
}
```

### ✅ 준수 코드

```java
// 공통 - 모든 동물
interface Animal {
    void eat();
    void run();
}

// 능력별 인터페이스 분리
interface Flyable {
    void fly();
}

interface Swimmable {
    void swim();
}

class Duck implements Animal, Flyable, Swimmable {
    public void eat() { System.out.println("먹는다"); }
    public void run() { System.out.println("뛴다"); }
    public void fly() { System.out.println("난다"); }
    public void swim() { System.out.println("헤엄친다"); }
}

class Eagle implements Animal, Flyable {
    public void eat() { System.out.println("먹는다"); }
    public void run() { System.out.println("뛴다"); }
    public void fly() { System.out.println("독수리처럼 난다"); }
}

class Penguin implements Animal, Swimmable {
    public void eat() { System.out.println("먹는다"); }
    public void run() { System.out.println("뛴다"); }
    public void swim() { System.out.println("헤엄친다"); }
}
```



### ISP가 LSP를 예방하는 이유

```
뚱뚱한 인터페이스 → 억지 구현 강요 → 예외 발생 → LSP 위반
인터페이스 분리   → 필요한 것만 구현 → 예외 없음 → LSP 자연히 준수 ✅
```

### 면접 포인트

> "ISP와 LSP의 차이는?"

|           | LSP                | ISP                       |
| --------- | ------------------ | ------------------------- |
| 관심사    | 상속 구조의 올바름 | 인터페이스 크기           |
| 위반 신호 | 자식에서 예외 발생 | 불필요한 메서드 강제 구현 |
| 해결책    | 상속 구조 재설계   | 인터페이스 잘게 분리      |

------



## DIP

## 의존성 역전 원칙 (Dependency Inversion Principle)

> **"고수준 모듈은 저수준 모듈에 의존하면 안 된다. 둘 다 추상화에 의존해야 한다"**

### 핵심 개념

```
고수준 모듈 - 비즈니스 로직, 정책 (중요한 것)
  예) OrderService - 주문 처리 흐름

저수준 모듈 - 세부 구현, 기술 (바뀔 수 있는 것)
  예) MySQLOrderRepository - DB 저장 방식
```

### ❌ 위반 코드

```java
class OrderService {
    // 구체 클래스에 직접 의존 ❌
    private final MySQLOrderRepository repository
                        = new MySQLOrderRepository();

    public void placeOrder(Order order) {
        repository.save(order);
    }
}
// MySQL → MongoDB로 바꾸면 OrderService도 수정해야 함 ❌
```

### ✅ 준수 코드

```java
// 추상화 - 인터페이스 정의
interface OrderRepository {
    void save(Order order);
}

class MySQLOrderRepository implements OrderRepository {
    public void save(Order order) {
        System.out.println("MySQL에 저장");
    }
}

class MongoOrderRepository implements OrderRepository {
    public void save(Order order) {
        System.out.println("MongoDB에 저장");
    }
}

class OrderService {
    private final OrderRepository repository; // 인터페이스에만 의존 ✅

    public OrderService(OrderRepository repository) {
        this.repository = repository;
    }

    public void placeOrder(Order order) {
        repository.save(order);
    }
}

// MongoDB로 교체? OrderService 코드 수정 없음 ✅
OrderService service = new OrderService(new MongoOrderRepository());
```



### Spring에서의 DIP

```java
@Service
public class OrderService {
    private final OrderRepository repository; // 인터페이스에 의존

    @Autowired // Spring이 구현체를 외부에서 주입 = DIP + DI 패턴
    public OrderService(OrderRepository repository) {
        this.repository = repository;
    }
}
```

> **매일 쓰던 `@Autowired` 가 바로 DIP의 구현체!**

### DIP 위반 체크리스트

```
코드 작성할 때 자문하기
  ├── new 키워드로 구체 클래스를 직접 생성하는가?
  ├── 구체 클래스 타입으로 필드를 선언하는가?
  └── 구현체가 바뀌면 이 클래스도 수정해야 하는가?
      → 하나라도 Yes면 DIP 위반 신호!
```

------



## SOLID 전체 흐름

```
SRP  책임을 분리한다
 ↓
OCP  분리된 책임을 인터페이스로 확장 가능하게 만든다
 ↓
LSP  상속 구조가 올바른지 검증한다
 ↓
ISP  인터페이스를 작게 분리해서 LSP 위반을 예방한다
 ↓
DIP  구체 클래스가 아닌 인터페이스에 의존한다
      ↑
   Spring @Autowired가 이걸 자동으로 해줌
```

> SOLID는 독립된 원칙이 아니라 **서로 연결된 하나의 설계 철학**이다.



## 🎯 면접 예상 질문

### Q1. SRP에서 책임이란 무엇인가요?

> "책임 = 변경의 이유 = 특정 액터(이해관계자)의 요구입니다. 같은 기능이라도 변경을 요구하는 주체가 다르면 책임이 다릅니다."

### Q2. OCP를 지키면 클래스가 너무 많아지지 않나요?

> "클래스 수는 늘어나지만 클래스명이 곧 역할을 나타내서 가독성이 높아지고, 기존 코드를 전혀 건드리지 않기 때문에 사이드 이펙트 위험이 없습니다. 새 기능 추가 시 해당 클래스만 테스트하면 되므로 유지보수가 편해집니다."

### Q3. LSP와 OCP의 차이는?

> "OCP는 기존 코드 수정 없이 새 기능을 추가할 수 있어야 한다는 확장 방법에 관한 원칙이고, LSP는 상속 관계에서 자식 클래스가 부모 클래스를 완전히 대체할 수 있어야 한다는 상속 구조의 올바름에 관한 원칙입니다."

### Q4. ISP와 LSP의 차이는?

> "ISP는 인터페이스를 작게 분리해서 구현체가 필요한 것만 구현하게 하는 원칙이고, LSP는 상속 관계에서 자식이 부모를 완전히 대체할 수 있어야 한다는 원칙입니다. ISP를 잘 지키면 LSP 위반을 자연스럽게 예방할 수 있습니다."

### Q5. SOLID에서 가장 중요한 원칙은?

> "실무에서는 OCP가 가장 중요하다고 생각합니다. 코드베이스가 커질수록 기존 코드 수정은 사이드 이펙트 위험이 크기 때문입니다. 다만 OCP를 지키려면 자연스럽게 DIP로 인터페이스에 의존하게 되고, LSP와 ISP로 인터페이스를 올바르게 설계하게 되고, SRP로 책임을 분리하게 됩니다. 결국 SOLID는 독립된 원칙이 아니라 서로 연결된 하나의 설계 철학입니다."

