---
title: 자바의 신 4장
date: 2026-02-14 13:12:20 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 4장 리뷰
- 목표 : 자료형과 2진수에 대해서 다시 공부해본다.

## 📝 본문

###  자바는 네 가지의 변수가 존재한다

- 변수란? 정보를 담아 둘 수 있는 공간을 의미한다.

- 지역변수

  - 지역변수가 선언된 `{}`  중괄호 안에서만 활동 할 수 있다.

- 매개변수

  - 메소드 선언부에 있는 변수로서 메소드에서만 활동 할 수 있다.
  - 메소드가 호출될 때 생명이 시작되고 메소드가 끝나면 소멸된다.

- 인스턴스 변수

  - 클래스 안에 있는 선언되어있는 변수로서 객체가 살아있을 때에만 활동 할 수 있다.
  - 인스턴스 변수가 있는 객체를 참조하는 다른 변수가 없으면 소멸된다.

- 클래스 변수

  - `static` 이라는 예약어가 붙어있는 변수로서 프로그램이 살아있을 때에만 활동한다.
  - 클래스가 처음 호출될 때에 생명이 시작되고 프로그램이 끝날 때에 소멸된다.

  

```java
public class Car{
    // speed, distance, color는 지역변수(localVariable) 이다.
    int speed;
    int distance;
    String color;
    
    // type은 클래스변수(classVariable) 이다.
    static String type; 
    
    public void setSpeed(int changeSpeed){  // chagneSpeed는 매개변수 이다.
        // localVariable은 지역변수 이다.
        int localVariable = 10;
        
        speed = changeSpeed;
    }
    
    public static void main(String [] args) {
        Car seltos = new Car();
        Car sorento = new Car();
        
        
    }
}
```



###  변수 이름을 짓는 방법은?

- 변수 이름에 길이 제한은 없지만 정확한 의미를 알 수 있는 이름이어야한다.
- 보통 변수 이름은 **$**와 **_**로 시작하지 않는다.
- 첫문자는 소문자로 두번째 문자부터는 가장 첫 문자만 대문자로 만든다
  - **c**olor**T**elevision
- 상수는 모두 대문잘 지정하며 문자와 문자 사이에는 **_**로 구분한다.
  - **BASIC_JAVA**



###  자바의 자료형은?

- 크게 두 가지가 존재한다.
  - 기본 자료형
    - 자바에서 제공해주는 자료형으로 사용자가 추가 할 수 없다.
  - 참조 자료형
    - 사용자가 만들 수 있는 자료형으로 대표적으로 클래스가 있다.
- 아래 예제에서 **기본 자료형**은 `=` 뒤에 값이 바로 나왔다.
- **참조 자료형**은 `=` 뒤에 `new`라는 예약어가 뒤에 나왔다.
- 즉 초기화 하는 방법에 따라 자료형을 구분할 수 있다.

```java
//기본 자료형과 참조 자료형을 간단히 구분하는 방법
public class Car{
    // speed, distance, color는 지역변수(localVariable) 이다.
    int speed;
    int distance;
    String color;
    
    // type은 클래스변수(classVariable) 이다.
    static String type; 
    
    public void setSpeed(int changeSpeed){  // chagneSpeed는 매개변수 이다.
        // localVariable은 지역변수 이다.
        int localVariable = 10;
        
        speed = changeSpeed;
    }
    
    public static void main(String [] args) {
        // 기본 자료형
        int a = 100;
        
        
        // 참조 자료형
        Car seltos = new Car();
        Car sorento = new Car();
        
        
    }
}
```

- 예외적인 케이스가 있는데 바로 `String` 이라는 클래스이다.



###  기본 자료형

- 기본 자료형의 종류는 총 8가지이다.
  - 정수형 : byte, short, int, long, char
  - 소수형 : double, float
  - boolean

|       타입        | 최소                        | 최대                      | 최소(2진수) | 최대(2진수) |
| :---------------: | :-------------------------- | ------------------------- | ----------- | ----------- |
|  byte  (1바이트)  | \-128                       | 127                       | \-2^7       | 2^7-1       |
|  short(2바이트)   | \-32,768                    | 32,767                    | \-2^15      | 2^15-1      |
| int     (4바이트) | \-2,147,483,648             | 2,147,483,647             | \-2^31      | 2^31-1      |
|  long  (8바이트)  | \-9,223,372,036,854,775,808 | 9,223,372,036,854,775,807 | \-2^63      | 2^63-1      |
|  char  (2바이트)  | 0('\\u0000')                | 65,535('\\uffff')         | 0           | 2^16-1      |

- char를 제외하고 음수부터 범위가 지정된다. 이것을 `signed` 부호가 있는 형태라 고 한다
- char는 `unsigned` 형태의 자료형이다.



###  8비트와 byte 타입

- 1byte는 8비트이다.
- 1과 0을 작성할 수 있는 하나의 공간을 1bit 라고 한다.
- 1byte는 1과 0을 작성하는 공간이 8개가 있다는 것을 의미한다.
- 보통 가장 왼쪽에 있는 위치에 있는 0과 1은 부호 (**+ 혹은 -**)를 의미한다.
  - 비트로 표현하기 떄문에 가장 큰값 혹은 작은 값에서 +1하게 되면 반전이 일어나게 된다.
  - 01111111 는 10진수 표현으로 127을 의미한다. 여기서 +1을 하게 되면
  - 10000000 로 변환되게 되고 -128이 된다. (가장 앞의 1과 0은 부호를 표현하기 때문에)
  - 10000000 에서 1을 빼면 01111111 이 되므로 127이 된다. (-128 -> 127)



###  왜 Byte 형태의 자료형을 만들었는가?

- 가장 효율적인 자료형태이기 때문이다.
- 컴퓨터의 CPU는 바이트 단위로 처리한다.
- 이미지를 처리할 때에 왜 byte를 사용하는가?
  - 색을 표현하는데 있어서 0~255까지의 데이터만 사용하면 되기 때문에 (저장 공간을 효율적으로 사용함)
  - 1바이트 범위 내의 색상으로도 인간의 눈이 구분하지 못하는 색상도 존재함(인간이 인지하는 색상을 전부 표현할 수 있음)



###  소수점을 처리하려면?

- `double, float`를 사용하면 된다.
  - `float` 는 32 비트    [부호(1비트) + 지수(8비트) + 가수(23비트)  > 총합 32]
  - `double `은 64 비트 [부호(1비트) + 지수(11비트) + 가수(52비트) > 총합 64]



###  문자열을 표현하는 char도 정수형 자료이다.

```java
int intValue = 'a';
System.out.println("intValue=["+intValue+"]");  // 97이 출력되는 것을 확인 할 수 있다.
```

- 예시처럼 문자를 입력하고 어떤 정수 값을 가지고 있는지 확인할 수 있다.
- ASCII 코드 표를 보면 문자가 어떤 정수 값을 가지고 있는지 알 수 있다.
- 문자는 2^16-1 개까지의 범위를 가지고 있다. 이것을 바이트 형태로 생각하면 2바이트의 크기를 가지고 있다고 생각하면 된다.



###  기본 자료형의 초기값은?

```java
byte = 0;
short = 0;
int = 0;
long = 0;
float = 0.0;
double = 0.0;
char =   (실제로는 \u0000);
boolean = false;
```







## 🎯 마무리

####  직접해 봅시다

````java
/**
1. ProfilePrint 클래스 byte 타입의 나이를 나타내는 age, String 타입의 name의 인스턴스 변수 생성
2. 결혼했는지 여부를 boolean 타입의 인스턴스 변수로 선언하고 isMarried 라는 이름으로 만들어라
3. setAge 메소드를 만들어라
4. 나이를 리턴하는 메소드를 만들어라
5,6 번 이름에 대해서도 set get을 만들어라
7,8. 결혼했는지 여부를 지정하는 메소드를 만들고 결혼 여부를 리턴하는 메소드를 만들어라
9. ProfilePrint 클래스에 메인 메소드를 만들어라
10. 객체를 생성하고 3,5,7에서 만든 메소드를 호출하라
11. 4,6,8 메소드를 호출하여 결과를 출력하자
*/
public class ProfilePrint {
    String name;
    byte age;
    boolean isMarried;
    
    public void setName(String str) {
        name = str;
    }
    
    public String getName(){
        return name;
    }
    
    public void setAge(byte val) {
        age = val
    }
    
    public byte getAge(){
        return age;
    }
    
    public void setMarried(boolean flag) {
        isMarried = flag;
    }
    
    public void isMarried(){
        return isMarried;
    }
    
    
    public void introduce(){
        System.out.println("My name is " + getName());
        System.out.println("My age is " + getAge());
        System.out.println("isMarried is " + isMarried());
    }
    
    public static void main(String [] args) {
        ProfilePrint profilePrint = new ProfilePrint();
        profile.setName("Min");
        profile.setAge(20);
        profile.setMarried(true);
        
        profile.introduce();
    }
}
````





####  정리해봅시다

1. 변수가 선언 된 위치로 구분한다. 자바 4가지 변수 - 지역 변수(중괄호 내), 매개 변수(메서드로 넘어오는 변수), 인스턴스 변수(메서드 밖, 클래스 안에 선언된 변수), 클래스 변수(메서드 밖, 클래스 안에 선언되어있고 static 예약어가 붙은 변수)
   변수의 이름을 지을 때 대문자로 시작해도 되나요?네. 컴파일 시 이상은 없지만 되도록 명명 규칙을 따라 맨 앞글자는 대문자보다는 소문자로 시작하자. (단, 상수의 경우 변수명을 모두 대문자로 작성)

2. 참조 자료형

3. 8가지 (byte, short, int, long, char, float, double, boolean)

4. byte, short, int, long, char
   byte는 몇 비트(bit)로 되어 있나요?8비트(부호 비트 1 + 값 표현 비트 7)

5. 8비트(부호 비트 1 + 값 표현 비트 7)

6. byte 범위 내의 정수 값을 메모리 낭비 없이 저장하기 위해byte는 8비트, int는 32비트이므로 byte 범위 내의 값을 int로 저장하면 메모리가 낭비된다.

7. long

8. float, double

9. char는 정수형 자료이다

10. int value = 'a';

11. boolean
