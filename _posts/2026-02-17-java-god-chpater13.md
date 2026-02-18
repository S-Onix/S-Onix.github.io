---
title: 자바의 신 13장
date: 2026-02-17 16:19:09 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 13장
- 목표 : 인터페이스와 추상클래스, Eum 클래스에 대한 개념을 확립한다.

## 📝 본문

###  인터페이스

- 어떤 클래스를 만들 것인지, 어떤 기능을 가질 것인지 미리 정의할 수 있는 클래스

- 클래스의 기능에 대한 정의만 있고 실제 구현은 되어있지 않는다.

- `implements`예약어를 통해서 인터페이스를 참조하고 실제 구현해야한다.

- 여러 개의 인터페이스를 한 클래스에서 받아 구현할 수 있다.

- 요구사항 정의 > 분석 >  설계 > 구현 및 테스트 > 배포 의 과정 중 설계 단계시 인터페이스를 정의해두면 구현 단계에서 좀 더 시간을 단축 할 수 있다.

- 인터페이스를 정의함으로 여러 개발자가 통일된 이름을 사용하고 문서로 만들 때에 도움을 받을 수 있다.

- `static method` 혹은 `final method`가 선언되어 있으면 **안된다**.

  ```java
  public interface MemberManager{
      public boolean addMember(MemberDTO member);
      public boolean removeMember(String name, String phone);
      public boolean updateMember(MemberDTO member);
  }
  
  
  public class MemberManagerImpl implements MemberManager{
      /**
      인터페이스 MemberManger 에 선언되어 있는 세개의 메소드를 모두 구현해야 실행이 된다. (내용은 없어도 아래와 같이는 되어 있어야한다.)
      */
      @Override
      public boolean addMember(MemberDTO member){
          return false;
      }
      @Override
      public boolean removeMember(String name, String phone){
          return false;
      }
      @Override
      public boolean updateMember(MemberDTO member){
          return false;
      }
  }
  
  public class InterfaceExample {
      public static void main(String [] args) {
          MemberManager memberManger = new MemberManager();
          /**
          위의 코드는 오류가 발생한다. 인터페이스는 구현된 내용이 없는 껍데기 같은 존재이기 때문이다.
          */
          
          MemberManger memberManger2 = new MamberManagerImpl();
          /**
          상속관계의 클래스 형 변환을 통해 겉은 MemberManger 처럼 보이지만 실속은 MemberManagerImpl 객체로 만들어진다.
          */
          
      }
  }
  ```



###  Abstract 클래스

- 인터페이스와 일반 클래스의 중간에 있는 에매모호한 클래스이다.

- abstract는 추상적인 이라는 의미를 가지고 있다.

- `abstract` 이라는 키워드가 붙은 클래스를 말한다.

- `interface`처럼 메소드를 정의만 해 놓을 수도 있고 일반 클래스처럼 구현하는 것이 동시에 가능하다.

- `interface`와는 다르게 `static method / final method`가 있어도 괜찮다.

- `extends` 라는 예약어를 통해 확장 되어 질 수 있다.

- 왜 `abstact class`가 있을까?

  - 공통적인 기능을 미리 구현해 놓을 때에 도움이 된다.
  - A,B,C,D 클래스는 a,b,c 라는 기능을 모두 구현해야하는데 메소드의 이름은 같아도 구현 방식이 다르다. 그런데 d라는 공통적인 기능이 있을 때에 F라는 abstract클래스를 통해서 F 클래스 안에 d메소드를 먼저 구현하고 상속 받으면 된다.

  ```java
  public abstract class MemberMangerAbstract{
      public abstract boolean addMember(MemberDTO member);
      public abstract boolean removeMember(String name, String phone);
      public abstract boolean updateMember(MemberDTO member);
      public void printLog(String data) {
          System.out.println("Data = " + data);
      }
  }
  
  public class MemberManagerImpl2 extends MemberMangerAbstract{
       /**
      abstract 클래스인 MemberMangerAbstract 에 abstract가 예약어로 붙어있는 세개의 메소드를 모두 구현해야 실행이 된다. (내용은 없어도 아래와 같이는 되어 있어야한다.)
      */
      @Override
      public boolean addMember(MemberDTO member){
          return false;
      }
      @Override
      public boolean removeMember(String name, String phone){
          return false;
      }
      @Override
      public boolean updateMember(MemberDTO member){
          return false;
      }
  }
  ```



###  클래스, 추상클래스, 인터페이스 차이점

| 구분              | 클래스 (Class)       | 추상 클래스 (Abstract)          | 인터페이스 (Interface)             |
| :---------------- | :------------------- | :------------------------------ | :--------------------------------- |
| **핵심 목적**     | 객체 생성            | 상속을 통한 기능 확장/구조 정의 | 기능(행위) 구현 강제               |
| **메서드**        | 모두 구현됨          | 구현된 메서드 + 추상 메서드     | 대부분 추상 메서드 (선언만)        |
| **변수(필드)**    | 인스턴스/static 변수 | 일반 변수/상수 가능             | 상수(`public static final`)만 가능 |
| **상속/구현**     | -                    | 단일 상속 (`extends`)           | 다중 구현 (`implements`)           |
| **인스턴스 생성** | 가능                 | 불가능                          | 불가능                             |



###  Final

- 의미 그대로 마지막이라는 예약어이다.
- 이 예약어는 클래스, 메소드, 변수 등에 선언 할 수 있다.
- 예약어가 클래스에 붙은 경우
  - `final`이 붙은 클래스는 **상속을 해 줄 수 없다.**
  - 누군가에 의해서 수정되면 안되는 클래스에 보통 final 예약어를 붙여 사용한다.
- 예약어가 메소드에 붙은 경우
  - `fianl`이 붙은 메소드는 **Overriding 할 수 없다.**
  - 클래스와 마찬가지로 누군가에 의해 수정되면 안되기 때문이다.
- 예약어가 변수에 붙은 경우
  - `final`이 붙은 변수는 초기화 이후 바꿀 수 없다.
  - 인스턴스 변수인 경우에는 바로 초기화 해야한다.
  - 지역 변수인 경우 초기화 하는 위치는 어디가 되든 상관 없다. (해당 영역 내에서만 초기화해야한다.)
  - 참조자료형 변수인 경우에는 **딱 한번만** 객체 생성이 가능하다.
    - 생성된 객체의 내부 인스턴스 변수가 final이 아닌경우 변경이 자유롭다.



###  Enum 클래스 (상수의 집합)

- 기본 자료형의 값을 고정해 놓은 것을 상수라고 한다.

  ```java
  public enum OverTimeValues{
      THREE_HOUR(18000),
      FIVE_HOUR(30000),
      WEEKEND_FOUR_HOUR(40000),
      WEEKEND_EIGHT_HOUR(60000);
      
      private final int amount;
      OverTimeValues(int amount) {
          this.amount = amount;
      }
      
      public int getAmount(){
          return this.amount;
      }
  }
  
  public class OverTimeManger{
      public int getOverTimeAmount(OverTimeValues value) {
          int amount = 0;
          System.out.println(value);
          switch(value) {
              case THREE_HOUR :
                  amount = 18000;
                  break;
              case FIVE_HOUR :
                  amount = 30000;
                  break;
              case WEEKEND_FOUR_HOUR :
                  amount = 40000;
                  break;
              case WEEKEND_EIGHT_HOUR :
                  amount = 60000;
                  break;
          }
          
          return amount;
      }
      
      public static void main(String [] args) {
          OverTimeManger manager = new OverTimeManager();
          int myAmount = manager.getOverTimeAmount(OverTimeValues.THREE_HOUR);
          System.out.println(myAmount);
          
          /** 실행 결과
          THREE_HOUR
          18000
          */
          
          OverTimeValues [] values = OverTimeValues.values();
          for(OverTimeValues value : values) {
              System.out.println(value);
          }
          /** 실행결과
          THREE_HOUR
      	FIVE_HOUR
      	WEEKEND_FOUR_HOUR
      	WEEKEND_EIGHT_HOUR
          */
      }
  }
  ```

  

## 🎯 마무리

####  직접해 봅시다1

```java
package c.impl.list;

public interface List{
    public void add();
    public void update(int index, Object value);
    public void remove(int index);
    public Object get(int index);
}

public abstract class AbstractList implements List{
    public abstract void clear();
    
    @Override
    public void add(){
        
	}
    @Override
    public void update(int index, Object value){
        
    }
    @Override
    public void remove(int index){
        
    }
    @Override
    public Object get(int index){
        return null;
    }
}
```



####  직접해 봅시다2

```java
public enum HealthInsurance{
    LEVEL_ONE(1000, 1.0),
    LEVEL_TWO(2000, 2.0),
    LEVEL_THREE(3000, 3.2),
    LEVEL_FOUR(4000, 4.5),
    LEVEL_FIVE(5000, 5.6),
    LEVEL_SIX(6000, 7.1);
    
    private final int maxSalary;
    private final double ratio;
    
    public HealthInsurance(int maxSalary, double ratio) {
        this.maxSalary = maxSalary;
        this.ratio = ratio;
    }
    
    public double getRatio(){
        return ratio;
    }
    
    public static HealthInsurance getHealthInsurance(int salary) {
        if(salary < 1000) {
            return LEVEL_ONE;
        }else if (salary < 2000) {
            return LEVEL_TWO
        }else if (salary < 3000) {
            return LEVEL_THREE
        }else if (salary < 4000) {
            return LEVEL_FOUR
        }else if (salary < 5000) {
            return LEVEL_FIVE
        }else {
            return LEVEL_SIX;
        }
    }
    
}
```





####  정리해 봅시다

1. 인터페이스에서는 메소드를 선언만 해야 한다. 메소드 선언후 중괄호를 열고 닫기만해도 컴파일이 되지 않는다.



2. 클래스 선언시 class 가 들어가는 자리에 interface가 위치해야 한다.



3. abstract 클래스는 인터페이스처럼 메소드를 선언만 할 수도 있고, 일부 메소드를 구현 할 수도 있다.



4. abstract 메소드 선언시에는 abstract 예약어를 사용해야 한다. 당연히 해당 클래스도 abstract class로 선언 되어 있어야만 한다.



5. final로 선언된 클래스는 확장(extends)할 수 없다.



6. 메소드를 final로 선언하면 override할 수 없다. 



7. 변수를 final로 선언하면, 그 값을 변경할 수 없다. 따라서 변수는 대부분 선언과 동시에 값을 할당한다. 



8. enum 클래스의 상수들은 콤마 , 로 구분한다. 



9. 모든 enum 클래스의 부모 클래스는 java.lang.Enum 이다. 



10. values() 메소드는 enum클래스에 선언된 상수의 목록을 배열로 리턴한다.
