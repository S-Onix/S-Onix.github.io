---
title: 자바의 신 10장
date: 2026-02-15 20:31:04 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 10장
- 목표 : 자바의 꽃인 상속에 대해서 정확히 이해한다.

## 📝 본문

###  상속

- 부모의 내용을 자식이 사용할 수 있는 것.

- 그렇다면 상속을 왜 사용할까?

  - **코드의 재사용성, 확장성, 그리고 유지보수의 효율성**을 위해 상속을 사용한다.

  - **1. 코드 재사용 (Code Reusability)**

    - 공통적인 기능은 부모 클래스에 한 번만 정의해두고, 자식 클래스에서 그대로 가져다 쓸 수 있습니다.
    - 비슷한 기능을 가진 클래스를 만들 때 코드를 다시 작성할 필요가 없어 개발 시간이 절약됩니다. 

    **2. 코드 확장 (Extensibility)**

    - 부모 클래스의 기능을 그대로 물려받으면서, 자식 클래스에서 새로운 기능(메서드나 필드)을 추가하거나, 필요 없는 기능을 변경(오버라이딩, Overriding)할 수 있습니다. 

    **3. 유지보수 용이성 (Maintainability)**

    - 공통 로직을 한 곳(부모 클래스)에서 관리하므로, 수정이 필요할 때 부모 클래스만 수정하면 모든 자식 클래스에 자동으로 반영됩니다. 

    **4. 다형성 활용 (Polymorphism)**

    - 부모 클래스 타입으로 자식 클래스 객체를 참조할 수 있어, 다양한 형태의 자식 객체들을 일관된 방식으로 처리할 수 있습니다.
    - *예: `Animal` 클래스를 상속받은 `Dog`, `Cat` 객체를 `Animal` 타입으로 묶어서 관리.* 

    **5. 객체지향적 설계 (Hierarchy)**

    - 현실 세계의 'is-a' 관계(예: Dog is an Animal)를 코드로 명확하게 표현할 수 있어, 구조적이고 체계적인 프로그래밍이 가능해집니다. 



```java
public class Parent {
    public Parent(){
        System.out.println("create Parent Constructor");
    }
    
    public void printName(){
        System.out.println("Parent PrintName");
    }
}
```

```java
public class Child extends Parent{ // Parent를 상속받는 다는 것을 의미하는 extends
    public Child(){
        System.out.println("create Child Constructor");
    }
    
    public void printName(){
        System.out.println("Child PrintName");
    }
}
```

```java
public class InheritancePrint{
    public static void main(String [] args) {
        Child child = new Child();
        child.printName();
        
        /**
        실행 결과 아래와 같이 출력된다.
        create Parent Constructor
        create Child Constructor
        Child PrintName
        */
    }
}
```

- 위의 코드를 좀 더 부연설명해보자면...
  - Child 클래스는 Parent 클래스를 상속받았다.
  - Child 클래스의 생성자가 호출(객체가 만들어지면)되면 Parent 클래스의 생성자(기본생성자)가  먼저 자동으로 실행된다.
  - Child 클래스는 Parent 클래스의 public 혹은 protected 로 선언된 모든 인스턴스 변수 및 클래스 변수와 메소드를 사용할 수 있다.
- 자바에서는 **다중 상속**이 허용되지 않는다.



###  부모 클래스에 기본 생성자가 없으면?

- `super()`라는 예약어를 통해서 부모 클래스의 생성자를 지정해서 호출 할 수 있다.
- `super()`라는 예약어는 반드시 자식 클래스의 생성자메소드 안에서 첫번째 줄에 위치해야한다.
- 첫번째 줄에 위치해야하는 이유는 조금만 생각해보면 알 수 있다. 부모클래스를 사용하기 위해서는 부모클래스의 생성자를 먼저 호출한다고 했다. 위의 예시에서 출력 순서를 보면 부모 클래스의 생성자에 있는 내용이 먼저 출력 된 것 같이 명시적으로 생성자를 호출하려면 가장 첫번째에 위치해야 하는 것이다.

```java
class Parent{
    public name;
    public age;
    
    public Parent(String name) {
        this.name=name;
        System.out.println("Parent name Constructor create");
    }
    
    public Parnet(int age) {
        this.age = age;
        System.out.println("Parent age Constructor create");
    }
}

class ChildOther extends Parent{
    
    public ChildOther(String name){
        super(name); // 부모의 생성자 중 매개변수가 String 타입이 하나인 것을 호출함.
        System.out.println("ChildOther name Constructor create");
    }
    
    public ChildOther(int age) {
        super(age); // 부모의 생성자 중 매개변수가 int 타입이 하나인 것을 호출함.
        System.out.println("ChildOther age Constructor create");
    }
    
}
```



###  메소드 Overriding

- 상속관계라 함은 하위에 있는 객체(자식)가 상위의 클래스(부모) 기능(private를 제외한)을 사용할 수 있는 것을 의미한다.

- 자식 클래스에서 부모 클래스의 메소드 중에 동일한 이름의 다른 기능을 하는 메소드를 만들고 싶을 때에 사용하는 것을 **메소드 Overriding** 이라고 한다.

- 메소드 Overriding은 자식 메소드와 부모 메소드의 **이름, 매개변수 갯수, 반환 타입, 접근 제어자** 등 전부 일치된 상태에서 사용이 가능하다.

  ```java
  class Parent{
      public Parent(){
  		System.out.println("Parent Constructor");
      }
      
      public overridingMethod(){
          System.out.println("Parent overridingMethod");
      }
  }
  
  class Child{
      public Child(){
  		System.out.println("Child Constructor");
      }
      
      public overridingMethod(){
          System.out.println("Child overridingMethod");
      }
  }
  
  class Test{
      public static void main(String [] args) {
          Child child = new Child();
          child.overrideMethod();
          /**
          실행 결과
          Parent Constructor
          Child Constructor
          Child overridingMethod
          */
      }
  }
  ```

- **반환타입, 접근 제어자** 등이 다르면 문제가 발생한다

  - 단, 부모 클래스의 메서드가 private 인 경우 자식 클래스의 메서드는 모든 접근 제어자를 사용하는 것이 가능하다.
  - 반대로 부모 클래스의 메서드가 public인데 자식 클래스의 메서드가 private인 경우는 사용이 불가능 하다.
  - 즉, 자식 클래스의 메소드의 허용되는 접근 권한이 크면 된다.



###  참조 자료형의 형 변환

- 기본 자료형의 형 변환을 봤었다. 범위가 큰 것에서 작은 것으로 변환시에는 문제가 발생할 수 있었다.

- 참조 자료형 또한 마찬가지이다. 범위가 큰 것에서 작은 것으로 변환시에 문제가 발생할 수 있다.

  - 즉 자식이 부모로 형 변환 하는 것은 가능해도 부모가 자식으로 형 변환 하는 것은 문제를 발생시킨다.

  ```java
  public class InheritanceCasting{
      public static void main(String [] args) {
          Parent parent = new Parent();
          Child child = new Child();
          
          Parent parent2 = child;
          Child child2 = parent;   // 에러 발생
          Child child3 = (Child) parent; // 형변환을 명시적으로 했지만 예외 발생
          
          //------------------------------------------------
          
          // 타입캐스팅이 가능한 경우
          Parent parent3 = new Child();
          Child child4 = (Child) parent3;
          
      }
  }
  ```

- parent3는 타입이 Parent 이지만 객체를 생성할 때에 Child 객체를 만들었다.

- 그렇기 때문에 Child로 형변환을 해도 문제가 발생하지 않는다.



###  형변환은 했는데 그러면 어떤거에서 형변환건지 알기 위해서는?

- `instanceof` 라는 예약어를 사용하여 어떤 클래스인지 알 수 있다.

  ```java
  class Parent{
      
  }
  
  class Child extends Parent{
      
  }
  
  class ChildOther extends Parent{
      
  }
  
  
  class Test{
      public static void main(String [] args) {
          Parent[] parentArray = new Parent[3];
          parentArray[0] = new Parent();
          parentArray[1] = new Child();
          parentArray[2] = new ChildOther();
          
          Test test = new Test();
          test.objectTypeCheck(parentArray);
          
          /**
          실행결과
          Parent Casting
          Child Casting
          ChildOther Casting
          */
      }
      
      private void objectTypeCheck(Parent [] parentArray) {
          for(Parnet tempParent : parentArray) {
              if(tempParent instanceof Child) {
                  System.out.println("Child Casting");
              }else if (tempParent instanceof ChildOther) {
                  System.out.println("ChildOther Casting");
              }else if (tempParent instanceof Parent){
                  System.out.println("Parent Casting");
              }
          }
      }
  }
  ```

- `instaceof` 를 사용시에 첫번째 조건으로 부모 클래스를 사용하면 안된다.

  - 자식 클래스는 모두 부모 클래스를 상속받기 때문에 첫번째 조건에 전부 걸리게 된다.
  - 자식 클래스들을 앞에 작성하고 부모 클래스를 가장 마지막에 작성한다.



### Polymorphism

- 상속과 인터페이스를 통해 하나의 부모 타입 참조 변수로 여러 자식 객체를 참조하여, 동일한 메서드 호출로 상황에 맞는 다양한 동작을 수행하는 것을 의미한다.
- 장점은 아래와 같다.
  - **유연성:** 새로운 자식 클래스가 추가되어도 기존 코드를 수정하지 않고 확장 가능하다.
  - **유지보수성:** 공통된 인터페이스(부모 클래스)를 사용하여 코드의 중복을 줄일 수 있다.
  - **확장성:** 다양한 타이어(객체)를 자동차(부모 타입)에 장착해도 동일하게 작동하는 예시처럼, 인터페이스를 통해 행동을 표준화된다. 



## 🎯 마무리

####  직접해 봅시다

```java
package c.inheritance;

public class Animal{
    private String name;
    private String kind;
    private int legCount;
    private int iq;
    private boolean hasWing;
    
    public void move(){
        System.out.println("animal can move");
    }
    
    public void eatFood(){
        System.out.println("animal can eat food");
    }
}

class Cat extends Animal{
    public void move(){
        System.out.println("cat can silence move");
    }
}

class Dog extends Animal{
    public void howling(){
        System.out.println("dog can howling and call other dogs");
    }
}
```





####  정리해 봅시다

상속을 받는 클래스의 선언문에 사용하는 예약어는 무엇인가요?

- extends

상속을 받은 클래스의 생성자를 수행하면 부모의 생성자도 자동으로 수행된다.

- O

부모 클래스의 생성자를 자식 클래스에서 직접 선택하려고 할 때 사용하는 예약어는 무엇인가요?

- super

메소드 Overriding과 Overloading을 정확하게 설명해 보세요.

- 오버로딩(Overloading) : 같은 이름의 메서드 여러개를 가지면서 매개변수의 유형과 개수가 다르도록 하는 기술
- 오버라이딩(Overriding) : 상위 클래스가 가지고 있는 메서드를 하위 클래스가 재정의해서 사용

A가 부모, B가 자식 클래스라면 A a=new B(); 의 형태로 객체 생성이 가능한가요?

- O

명시적으로 형변환을 하기 전에 타입을 확인하려면 어떤 예약어를 사용해야 하나요?

- instanceof

위의 문제에서 사용한 예약어의 좌측에는 어떤 값이, 우측에는 어떤 값이 들어가나요?

- instanceof의 왼쪽에는 참조변수를 오른쪽에는 타입(클래스명)

instanceof 예약어의 수행 결과는 어떤 타입으로 제공되나요?

- boolean

Polymorphism이라는 것은 뭔가요?

- 다형성(polymorphism)이란 하나의 객체가 여러 가지 타입을 가질 수 있는 것을 의미합니다.다형성은 상속, 추상화와 더불어 객체 지향 프로그래밍을 구성하는 중요한 특징 중 하나입니다. 자바에서는 이러한 다형성을 부모 클래스 타입의 참조 변수로 자식 클래스 타입의 인스턴스를 참조할 수 있도록 하여 구현하고 있습니다.
