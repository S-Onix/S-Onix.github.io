---
title: 자바의 신 3장
date: 2026-02-14 12:33:25 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 3장 리뷰
- 목표 : 객체가 무엇인지 물어볼 때에 대답할 수 있어야한다.

## 📝 본문

###  객체지향 언어?

- 객체지향이란 객체가 중심으로 프로그램 되는 것을 말한다.
- 실생활에서 사용되는 객체 예를 들면 핸드폰, 의자, 책 등이 객체라고 생각하면된다.
- 객체에는 **상태와 행위**가 존재한다.
- 클래스도 마찬가지로 **상태와 행위**가 존재한다.

```java
// 자동차라는 클래스에
public Class Car {
    // 속도와 색상, 이동거리 라는 상태이 있다.
    int speed;
    String color;
    int distance;
    // 속도를 늘려주는 행위가 존재한다.
    public void speedUp() {
        speed = speed+5;
    }
    
    public void breakDown(){
        speed = 0;
    }
}
```



###  클래스와 객체?

- 클래스와 객체는 **꼭 구분**해야한다.
- 위의 자동차라는 클래스는 공장이라고 생각해야한다.
- 공장에서 자동차를 만들어내는데 여러가지 종류의 자동차를 만들 수 있다.
  - 예를 들면 셀토스를 만들 수도 있고 쏘렌토도 만들 수 있다.
- 만들어진 셀토스 혹은 쏘렌토가 바로 **객체**이다.

- 정리하면 클래스는 객체를 만들기 위한 **틀판**이라고 생각하면되고 객체는 클래스를 통해 실제 만들어진 **사물**을 의미한다.



###  그러면 객체는 어떻게 만드는데?

- 객체를 만드는 방법은 예약어를 통해서 만들 수 있다.

  ``` java
  public Class Car {
      int speed;
      String color;
      int distance;
      
      public void speedUp(){
          speed = speed+5;
      }
      
      public void breakDown(){
          speed = 0;
      }
      
      public static void main(String [] args) {
          // 셀토스와 쏘렌토라는 객체를 new라는 예약어를 통해 만들어보겠다.
          Car celtos = new Car();
          Car sorento = new Car();
      }
  }
  ```

- 객체를 만들 때에 `Car()` 라는 메소드와 비슷한 것을 사용했다. 이것을 **생성자** 라고 한다.

  - 생성자 : 객체를 생성하기 위한 거의 유일한 도구
  - 매개변수가 없는 생성자를 **기본생성자**라고 한다.



###  객체를 일하게 하는 방법은?

- 객체를 만들었는데 그러면 이 객체가 할 수 있는 것은 `speedUp() / breakDown()`이라는 행동을 할 수 있다.
- 객체가 일하게 하는 방법은 아래 예시를 통해서 확인해보자

```java
....
public static void main(String [] args) {
    Car celtos = new Car();
    Car sorento = new Car();
    
    // 객체의 상태를 아래와 같이 변경한다.
    celtos.speed = 30;  // 셀토스는 속도가 30이다
    sorento.speed = 50; // 쏘렌토는 속도가 50이다
    
    celtos.speedUp(); // 셀토스가 가속한다.
    sorento.speedUp();// 쏘렌토가 가속한다
    
    sorento.breakDown(); // 쏘렌토 앞에 차가 갑자기 끼어들어 브레이크를 밟았다.
}
```

- 객체를 일하게 하는 방법은 `객체이름`**.**`객체의 행동` 이렇게 작성하면 된다.
- 현재 객체의 상태를 변경할 때에도 **.**을 사용했지만 나중에는 메소드에서 동작할 것이다.

###  



## 🎯 마무리

- ####  직접해 봅시다

  ````java
  /**
  1. Profile 클래스 String 타입의 name 과 int 타입의 age 변수 선언
  2. setName 메소드 만들기
  3. setAge 메소드 만들기
  4. name을 출력해주는 printName 메소드 만들기
  5. age를 출력해주는 printAge 메소드 만들기
  6. main 메소드에 Profile 클래스 객체 선언하기
  7. setName에 'Min'을 넘겨주고 setAge에 20을 넘겨주기
  */
  public class Profile {
      String name;
      int age;
      
      public void setName(String str) {
          name = str;
      }
      
      public void setAge(int val) {
          age = val
      }
      
      public void printName(){
          System.out.println("name : " + name);
      }
      
      public void printAge(){
          System.out.println("age : " + age);
      }
      
      public void introduce(){
          System.out.println("My name is " + name);
          System.out.println("My age is " + age);
      }
      
      public static void main(String [] args) {
          Profile profile = new Profile();
          profile.setName("Min");
          profile.setAge(20);
          
          profile.introduce();
      }
  }
  ````

  

  

  ####  정리해봅시다

  1. 클래스를 통해서 객체를 생성할 수 있다. 즉, 하나의 클래스를 만들면 그 클래스의 모습을 갖는 여러 객체들을 생성 할 수 있다. 
     그러므로, 일반적인 경우 클래스의 메소드나 변수들을 사용하려면 객체를 생성하여 사용하여야 한다.

  2. new 키워드를 사용하여 클래스의 객체를 생성한다.

  3. 생성자(Constructor)를 통하여 클래스의 객체를 생성한다.

  4. 클래스의 변수나 메소드를 호출하려면 "객체이름.변수", "객체이름.메소드이름()"와 같이 사용하면 된다.

  5. 클래스의 "객체"를 생성해야만 메소드를 사용할 수 있다. 

  6. 객체를 생성해야 하고, new 키워드를 사용하여 생성자를 호출해야만 된다.
