---
title: 자바 ClassLoader 파헤쳐보기
date: 2026-02-26 16:22:19 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, ClassLoader]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : Claude 문답형식을 이용한 ClassLoader 학습
- 목표 : ClassLoader에 대해 이해한다.

## 📝 본문

## 1. ClassLoader의 역할

ClassLoader는 .class 파일(바이트코드)을 읽어서 JVM 메모리(Method Area / Metaspace)에 로드하는 역할을 한다. ClassLoader 자체도 `java.lang.ClassLoader`라는 추상 클래스이며, Java 객체이다.

```java
public abstract class ClassLoader {
    private final ClassLoader parent;  // 부모 ClassLoader 참조
    
    public Class<?> loadClass(String name) { ... }
    protected Class<?> findClass(String name) { ... }
}
```

------



## 2. 세 가지 기본 ClassLoader

JVM에는 기본적으로 세 가지 ClassLoader가 계층 구조를 이루고 있다.

```
Bootstrap ClassLoader (최상위)
      │
      ▼
Extension ClassLoader (Java 9+: Platform ClassLoader)
      │
      ▼
Application ClassLoader (System ClassLoader)
```

| ClassLoader              | 로드 대상                                             | 구현             |
| ------------------------ | ----------------------------------------------------- | ---------------- |
| **Bootstrap**            | JVM 핵심 클래스 (java.lang.*, java.util.*, java.io.*) | C/C++ (네이티브) |
| **Extension (Platform)** | 확장 라이브러리 ($JAVA_HOME/lib/ext)                  | Java             |
| **Application (System)** | 우리 코드, classpath에 있는 라이브러리                | Java             |

### 확인 방법

```java
System.out.println(String.class.getClassLoader());     // null (Bootstrap)
System.out.println(MyClass.class.getClassLoader());    // AppClassLoader
```

Bootstrap ClassLoader는 C/C++ 구현이라 Java 객체가 아니므로, `getClassLoader()` 호출 시 `null`이 반환된다.



------

## 3. Bootstrap ClassLoader가 C/C++인 이유

"ClassLoader가 클래스를 로드한다. 그런데 ClassLoader 자체도 클래스다. 그러면 ClassLoader는 누가 로드하지?"

이 모순을 해결하기 위해 Bootstrap ClassLoader는 **Java가 아닌 C/C++로 구현되어 JVM에 내장**되어 있다.

```
JVM 시작 시:
1. Bootstrap ClassLoader (C/C++) → JVM 내부에서 자동 생성
2. Bootstrap이 java.lang.ClassLoader 등 핵심 클래스 로드
3. Bootstrap이 Extension ClassLoader (Java 클래스) 로드
4. Extension이 Application ClassLoader (Java 클래스) 로드
5. Application이 우리 코드 로드
```

Bootstrap ClassLoader는 "맨 처음 닭" — Java 세계 밖에서 시작하여 Java 세계를 부트스트랩(bootstrap)하는 역할이다.



------

## 4. 부모 위임 원칙 (Parent Delegation Principle)

### 동작 순서

클래스 로드 요청이 들어오면 자식이 직접 로드하지 않고 **먼저 부모에게 위임**한다.

```
요청 방향 (위임): 아래 → 위
  Application → Extension → Bootstrap

처리 방향 (로드 시도): 위 → 아래
  Bootstrap(실패) → Extension(실패) → Application(성공!)
```

구체적인 흐름:

```
1. Application ClassLoader: "MyClass 로드해야 해"
   → "부모한테 먼저 물어볼게"

2. Extension ClassLoader: "나도 부모한테 먼저 물어볼게"

3. Bootstrap ClassLoader: "핵심 클래스에 MyClass가 있나? → 없네."

4. Extension ClassLoader: "확장 라이브러리에 있나? → 없네."

5. Application ClassLoader: "classpath에서 찾을게 → 찾았다! 로드 완료!"
```

### 부모 위임을 사용하는 이유

| 이유          | 설명                                                         |
| ------------- | ------------------------------------------------------------ |
| **보안**      | 악의적으로 만든 java.lang.String 등 가짜 핵심 클래스가 로드되는 것을 방지. 항상 Bootstrap이 먼저 진짜 클래스를 로드함 |
| **중복 방지** | 부모가 이미 로드한 클래스를 자식이 다시 로드하지 않음        |
| **일관성**    | 어디에서 요청하든 동일한 클래스는 항상 같은 ClassLoader가 로드 |

------

## 5. 클래스 로딩 상세 단계

```
Loading → Linking [ Verification → Preparation → Resolution ] → Initialization
```

### Loading (로드)

.class 파일을 읽어서 JVM 메모리에 올리는 단계이다.

### Linking (링크)

**Verification (검증):**

로드된 바이트코드가 유효하고 안전한지 검증한다.

- 파일 형식 검증: Magic Number가 CAFEBABE인지, 버전 호환성
- 바이트코드 검증: 명령어 유효성, 타입 일치 여부
- 심볼릭 참조 검증: 참조하는 클래스/메서드/필드가 존재하는지

잘못된 바이트코드가 발견되면 `VerifyError`가 발생한다.

**Preparation (준비):**

static 변수에 메모리를 할당하고 **타입의 기본값으로 초기화**한다. 코드에서 지정한 실제 값이 아님에 주의한다.

java

```java
public class Example {
    static int count = 10;       // Preparation: count = 0
    static String name = "Kim";  // Preparation: name = null
    static boolean flag = true;  // Preparation: flag = false
}
```

| 타입                       | Preparation 기본값 |
| -------------------------- | ------------------ |
| int, long, short, byte     | 0                  |
| float, double              | 0.0                |
| boolean                    | false              |
| 참조형 (String, Object 등) | null               |

**Resolution (해석):**

심볼릭 참조(Symbolic Reference)를 실제 메모리 참조(Direct Reference)로 변환한다.

```
Constant Pool (심볼릭 참조):
  #5 = "java/lang/String"         (문자열 이름)
  #8 = "println"                   (메서드 이름)

Resolution 후 (Direct Reference):
  #5 → 0x7F3A2100 (String 클래스의 실제 메모리 주소)
  #8 → 0x7F3A8400 (println 메서드의 실제 메모리 주소)
```

### Initialization (초기화)

static 변수에 **실제 값을 할당**하고, **static 블록을 실행**하는 단계이다.

java

```java
static int count = 10;
// Preparation: count = 0 (기본값)
// Initialization: count = 10 (실제 값) ← 이 시점!
```

### 전체 흐름 정리

```
Loading:        .class 파일을 읽어서 JVM 메모리에 올림
Linking:
  Verification: 바이트코드가 유효하고 안전한지 검증
  Preparation:  static 변수에 메모리 할당, 기본값 초기화
  Resolution:   심볼릭 참조 → 실제 메모리 참조로 변환
Initialization: static 변수에 실제 값 할당, static 블록 실행
```

------



## 6. 클래스의 고유성 (Class Identity)

### 고유성 공식

```
클래스의 고유성 = FQCN(Fully Qualified Class Name) + ClassLoader 인스턴스
```

**같은 이름의 클래스라도 다른 ClassLoader가 로드하면 서로 다른 클래스로 취급된다.**

java

```java
ClassLoader loader1 = new CustomClassLoader();
ClassLoader loader2 = new CustomClassLoader();

Class<?> classA = loader1.loadClass("com.example.MyClass");
Class<?> classB = loader2.loadClass("com.example.MyClass");

System.out.println(classA == classB);  // false!
```

### 실무적 영향

**ClassCastException 발생 가능:**

java

```java
Object obj = loader1.loadClass("MyClass").newInstance();
MyClass casted = (MyClass) obj;  // 💥 ClassCastException!
// loader1이 로드한 MyClass ≠ Application ClassLoader가 로드한 MyClass
```

**웹 애플리케이션 격리 (Tomcat):**

```
Tomcat
├── Common ClassLoader (공통 라이브러리)
├── WebApp1 ClassLoader → MyClass (버전 1.0)
└── WebApp2 ClassLoader → MyClass (버전 2.0)
    (같은 이름이지만 서로 다른 클래스 → 충돌 없이 독립 동작)
```

------



## 7. Lazy Loading (지연 로딩)

JVM은 클래스를 프로그램 시작 시 모두 로드하지 않고, **해당 클래스가 처음 사용될 때 로드**한다.

### 클래스가 로드되는 시점 (Active Use)

| 시점                    | 예시                                            |
| ----------------------- | ----------------------------------------------- |
| **인스턴스 생성**       | `new MyClass()`                                 |
| **static 멤버 접근**    | `MyClass.staticField`, `MyClass.staticMethod()` |
| **자식 클래스 로드 시** | `new Child()` → Parent도 먼저 로드              |
| **리플렉션**            | `Class.forName("com.example.MyClass")`          |
| **main 클래스**         | JVM 시작 시 가장 먼저 로드                      |

### Lazy Loading의 이유

| 이유               | 설명                                          |
| ------------------ | --------------------------------------------- |
| **시작 속도 향상** | 모든 클래스를 한꺼번에 로드하면 시작이 느려짐 |
| **메모리 절약**    | 사용하지 않는 클래스는 메모리에 올리지 않음   |
| **유연성**         | 조건에 따라 다른 클래스를 동적으로 로드 가능  |

JIT 컴파일러가 Hot Code만 컴파일하는 것과 같은 철학 — 필요한 것만, 필요한 시점에!



------

## 8. Custom ClassLoader

기본 세 가지 ClassLoader 외에 개발자가 직접 ClassLoader를 만들 수 있다.

### 사용 사례

| 사용 사례                   | 설명                                                |
| --------------------------- | --------------------------------------------------- |
| **웹앱 격리**               | WAS에서 각 애플리케이션별 독립적인 클래스 공간 제공 |
| **Hot Deploy / Hot Reload** | 서버 재시작 없이 새 버전 클래스 교체                |
| **암호화 클래스 로드**      | 암호화된 .class 파일을 복호화 후 로드               |
| **네트워크 로드**           | 원격 서버에서 클래스를 다운로드하여 로드            |
| **플러그인 시스템**         | 런타임에 플러그인을 동적으로 추가/제거              |

### Hot Deploy 동작 원리

JVM에서 이미 로드된 클래스는 교체할 수 없지만, ClassLoader를 새로 만들어서 새 버전의 클래스를 로드하면 가능하다.

```
1단계: ClassLoader_v1 → MyClass (버전 1.0) 로드 중
2단계: ClassLoader_v1 버리고, ClassLoader_v2 생성
3단계: ClassLoader_v2 → MyClass (버전 2.0) 로드
→ 서버 재시작 없이 새 버전 적용!
```

Spring DevTools, JRebel 같은 핫 리로드 도구의 핵심 원리이다.

### 암호화 ClassLoader 예시

java

```java
public class EncryptedClassLoader extends ClassLoader {
    @Override
    protected Class<?> findClass(String name) {
        byte[] encrypted = readFile(name + ".enc");
        byte[] decrypted = decrypt(encrypted);
        return defineClass(name, decrypted, 0, decrypted.length);
    }
}
```

------



## 9. Thread Context ClassLoader와 부모 위임 역전

### 문제 상황

JDBC의 DriverManager는 java.sql 패키지에 있으므로 **Bootstrap ClassLoader**가 로드한다. 하지만 실제 DB 드라이버(MySQL Driver 등)는 classpath에 있으므로 **Application ClassLoader**가 로드해야 한다.

부모 위임 원칙에 따르면 부모(Bootstrap)가 자식(Application)에게 로드를 요청할 수 없다. 위임은 항상 아래 → 위 방향이기 때문이다.

### 해결: Thread Context ClassLoader

각 스레드는 자신만의 Context ClassLoader를 가지고 있으며, 기본적으로 Application ClassLoader가 설정된다.

java

```java
Thread.currentThread().getContextClassLoader();  // Application ClassLoader
```

DriverManager는 자신을 로드한 Bootstrap 대신, 현재 스레드의 Context ClassLoader를 빌려서 DB 드라이버를 로드한다.

```
정상적인 부모 위임:
  Application → Extension → Bootstrap (아래 → 위)

Thread Context ClassLoader (역전):
  Bootstrap의 DriverManager
    → Thread.currentThread().getContextClassLoader() 호출
    → Application ClassLoader를 얻음
    → MySQL Driver 로드 성공! (위 → 아래)
```

### 부모 위임 원칙을 깨는 이유

정상적인 부모 위임은 항상 아래 → 위로 위임하는데, Thread Context ClassLoader는 위(Bootstrap) → 아래(Application) 방향으로 클래스를 로드하기 때문에 부모 위임 원칙을 역전시킨다.

### SPI (Service Provider Interface) 패턴

이런 패턴이 사용되는 대표적인 사례들:

| 사례     | 설명                                              |
| -------- | ------------------------------------------------- |
| **JDBC** | DriverManager(Bootstrap) → DB Driver(Application) |
| **JNDI** | JNDI 코어(Bootstrap) → JNDI 구현체(Application)   |
| **SPI**  | Java 표준 API → 서드파티 구현체 로드              |

------

## 10. 클래스 로딩과 싱글톤 패턴

### static final 싱글톤이 스레드 안전한 이유

```java
public class Singleton {
    private static final Singleton INSTANCE = new Singleton();
    
    private Singleton() { }
    
    public static Singleton getInstance() {
        return INSTANCE;
    }
}
```

JVM 스펙에 의해 클래스 초기화(Initialization)는 다음이 보장된다:

1. **딱 한 번만 실행된다**
2. **여러 스레드가 동시에 초기화하려 하면, JVM이 내부적으로 락을 걸어 한 스레드만 초기화를 수행하고 나머지는 대기한다**

따라서 volatile이나 synchronized 없이도 스레드 안전하다.

### DCL 패턴과의 비교

| 항목             | DCL 패턴                                   | static final 패턴     |
| ---------------- | ------------------------------------------ | --------------------- |
| 스레드 안전 보장 | 개발자가 volatile + synchronized 직접 구현 | JVM이 알아서 보장     |
| 복잡도           | 높음 (실수 가능)                           | 낮음 (간단)           |
| Lazy Loading     | ✅                                          | ✅ (클래스 첫 사용 시) |
| 재정렬 문제      | volatile 없으면 발생                       | JVM이 내부적으로 방지 |

### Lazy Holder Idiom (더 발전된 패턴)

```java
public class Singleton {
    private Singleton() { }
    
    private static class Holder {
        private static final Singleton INSTANCE = new Singleton();
    }
    
    public static Singleton getInstance() {
        return Holder.INSTANCE;  // 이 시점에 Holder 클래스가 로드 → INSTANCE 생성
    }
}
```

Singleton 클래스가 로드되어도 Holder 클래스는 로드되지 않고, getInstance()가 호출될 때 비로소 Holder가 로드되면서 INSTANCE가 생성된다. 진정한 Lazy Loading이면서 JVM의 클래스 초기화 동기화 보장으로 스레드 안전하다.



------

## 11. ClassLoader 누수와 Metaspace OOM

### 연결고리

ClassLoader는 자신이 로드한 모든 Class 객체를 참조하고 있고, 각 Class 객체는 Metaspace에 있는 클래스 메타데이터를 참조한다.

```
ClassLoader가 살아있는 한
→ 해당 ClassLoader가 로드한 모든 클래스 메타데이터는
→ Metaspace에서 해제되지 않는다
GC Root
  └── Thread (활성 스레드)
        └── ClassLoader_v1 (수거 안 됨!)
              ├── MyClassA의 메타데이터 → Metaspace에 유지
              ├── MyClassB의 메타데이터 → Metaspace에 유지
              └── MyClassC의 메타데이터 → Metaspace에 유지
```

### 누수 시나리오

```
1차 배포: ClassLoader_v1 → 500개 클래스 메타데이터 (Metaspace 점유)
재배포:   ClassLoader_v2 → 500개 클래스 메타데이터 (추가 점유)
          ClassLoader_v1이 GC 안 되면? → 500개가 여전히 남아있음!
재배포:   ClassLoader_v3 → 500개 추가...
→ Metaspace 계속 증가 → OutOfMemoryError: Metaspace 💥
```

ClassLoader가 GC 되면 해당 ClassLoader가 로드한 모든 클래스 메타데이터도 Metaspace에서 해제된다.

## 🎯 면접 예상 질문

---

**Q1. 클래스 로더에 대해 전체적으로 설명해주세요. (종합)**

> ClassLoader는 .class 파일을 JVM 메모리에 로드하는 역할을 합니다. Bootstrap(JVM 핵심 클래스, C/C++ 구현), Extension(확장 라이브러리), Application(우리 코드, classpath)의 세 가지 기본 ClassLoader가 계층 구조를 이룹니다.
>
> 클래스 로드 시 부모 위임 원칙을 따라 자식이 직접 로드하기 전에 부모에게 먼저 위임합니다(Application → Extension → Bootstrap). 이를 통해 핵심 클래스의 보안, 중복 로드 방지, 일관성을 보장합니다.
>
> 로딩 단계는 Loading(바이트코드를 메모리에 올림) → Linking(Verification: 검증, Preparation: static 기본값, Resolution: 심볼릭→실제 참조) → Initialization(static 실제 값 할당, static 블록 실행)으로 이루어집니다.
>
> 클래스의 고유성은 "FQCN + ClassLoader"의 조합으로 결정되어, 같은 이름의 클래스도 다른 ClassLoader가 로드하면 서로 다른 클래스로 취급됩니다.

------

**Q2. 부모 위임 원칙이란 무엇이고, 왜 필요한가요?**

> 클래스 로드 요청이 들어오면 자식 ClassLoader가 직접 로드하지 않고 먼저 부모에게 위임합니다. 부모가 못 찾으면 자식이 시도합니다. 보안(핵심 클래스 대체 방지), 중복 로드 방지, 일관성 보장을 위해 필요합니다. 예를 들어 악의적으로 java.lang.String을 만들어도, 항상 Bootstrap이 먼저 진짜 String을 로드하므로 가짜 클래스가 끼어들 수 없습니다.

------

**Q3. 같은 이름의 클래스를 서로 다른 ClassLoader로 로드하면?**

> JVM에서 서로 다른 클래스로 취급됩니다. 클래스의 고유성은 "FQCN + ClassLoader"로 결정되기 때문입니다. ClassCastException이 발생할 수 있으며, Tomcat 같은 WAS는 이 특성을 활용해 웹앱별로 다른 버전의 라이브러리를 독립적으로 사용할 수 있게 합니다.

------

**Q4. 클래스 로딩의 상세 단계를 설명해주세요.**

> Loading은 .class 파일을 읽어서 JVM 메모리에 올리는 것입니다. Linking은 세 단계로 나뉘는데, Verification은 바이트코드의 유효성과 안전성을 검증하고, Preparation은 static 변수에 메모리를 할당하고 타입의 기본값(0, null, false)으로 초기화하며, Resolution은 심볼릭 참조를 실제 메모리 주소로 변환합니다. Initialization은 static 변수에 코드에서 지정한 실제 값을 할당하고 static 블록을 실행합니다.

------

**Q5. Preparation과 Initialization의 차이는?**

> Preparation은 static 변수에 타입의 기본값(int는 0, 참조형은 null)을 할당하는 단계이고, Initialization은 코드에서 지정한 실제 값(예: static int count = 10에서 10)을 할당하고 static 블록을 실행하는 단계입니다. 예를 들어 `static int count = 10`이면 Preparation에서 count = 0이 되고, Initialization에서 count = 10이 됩니다.

------

**Q6. Bootstrap ClassLoader가 C/C++로 구현된 이유는?**

> "ClassLoader가 클래스를 로드하는데, ClassLoader 자체도 클래스"라는 모순을 해결하기 위해서입니다. Bootstrap ClassLoader는 JVM에 내장된 C/C++ 코드로 구현되어 Java 세계 밖에서 시작하며, java.lang.ClassLoader를 포함한 핵심 클래스들을 로드하여 Java 세계를 부트스트랩합니다. 그래서 getClassLoader() 호출 시 null이 반환됩니다.

------

**Q7. Lazy Loading이란?**

> JVM이 클래스를 프로그램 시작 시 모두 로드하지 않고, 해당 클래스가 처음 사용될 때 로드하는 것입니다. 인스턴스 생성, static 멤버 접근, 자식 클래스 로드, 리플렉션 사용 시 로드됩니다. 시작 속도 향상과 메모리 절약을 위한 설계이며, JIT가 Hot Code만 컴파일하는 것과 같은 철학입니다.

------

**Q8. Thread Context ClassLoader란?**

> 부모 위임 원칙의 한계를 해결하기 위한 메커니즘입니다. JDBC의 DriverManager처럼 Bootstrap ClassLoader가 로드한 클래스에서 Application ClassLoader가 로드해야 하는 클래스를 참조해야 할 때, Thread Context ClassLoader를 통해 Application ClassLoader를 빌려 사용합니다. 이는 부모 위임의 아래→위 방향을 위→아래로 역전시킵니다.

------

**Q9. Custom ClassLoader가 필요한 경우는?**

> WAS에서 웹앱별 클래스 격리, 서버 재시작 없이 클래스를 교체하는 Hot Deploy, 암호화된 .class 파일을 복호화 후 로드, 네트워크에서 클래스를 다운로드하여 로드, 런타임에 플러그인을 동적으로 추가/제거하는 경우 등에 필요합니다.

------

**Q10. static final 싱글톤이 volatile 없이도 스레드 안전한 이유는?**

> JVM 스펙에 의해 클래스 초기화(Initialization)는 딱 한 번만, 스레드 안전하게 수행되는 것이 보장되기 때문입니다. 여러 스레드가 동시에 초기화하려 하면 JVM이 내부적으로 락을 걸어 한 스레드만 초기화하고 나머지는 대기합니다. DCL 패턴과 달리 개발자가 volatile이나 synchronized를 직접 구현할 필요가 없습니다.

------

**Q11. ClassLoader 누수가 Metaspace OOM을 일으키는 이유는?**

> ClassLoader는 자신이 로드한 모든 클래스의 메타데이터를 참조합니다. ClassLoader가 GC 수거되지 않으면 해당 메타데이터가 Metaspace에서 해제되지 않습니다. 웹앱 재배포 시 이전 ClassLoader가 수거되지 않으면 메타데이터가 계속 누적되어 Metaspace가 부족해집니다.
