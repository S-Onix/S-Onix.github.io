---
title: 자바의 신 5장
date: 2026-02-14 15:16:45 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 5장
- 목표 : 연산자에 대해서 다시 복습해본다.

## 📝 본문

###  연산자의 종류

- 대입 연산자 / 이항 연산자 / 단항 연산자 / 산술연산자 / 비교연산자 / 논리연산자
- 대입 연산자는 오른쪽의 값을 왼쪽에 넣는 것을 말한다.
  - a = 5 (Rvalue to Lvalue)
- 피연산자가 두 개인 것 : 이항 연산자 
- 피연산자가 한 개인 것 : 단항 연산자 

```java
public static void main(String [] args) {
    int a = 5;
    int b = 10;
    
    int c = a/b;  // 0으로 출력됨 (실제 값은 0.5) int는 정수만 표현 가능하기 떄문에
    
    double a2 = 5;
    double b2 = 10;
    double c2 = a2/b2; // 0.5 출력됨
    
    // 소수를 표현하기 위해서는 실수형 자료구조를 무조건 사용해야한다.
    
}
```

- 위의 예제에서 이항 연산자를 의미하는 것이 바로 `a/b` 이다 a와 b라는 피연산자에 /라는 연산자가 붙어있다.

- 단항 연산자

  - 종류 : `++, --, !, +, -` 등

  - `++`의 의미

    ```java
    int a = 10;
    a++;
    System.out.print("a = " + a); // a는 11이 출력된다.
    ++a;
    System.out.print("a = " + a); // a는 12이 출력된다.
    
    /* a++ 는 이렇게 동작된다
    순서 : 10 > ++ > 11 > print
    
    중간에 print를 넣는다면?
    int a = 10;
    System.out.println(a);
    a = a + 1
    System.out.println(a);
    
    동작을 수행하고 1을 더한다.
    
    ++a 는 이렇게 동작된다
    a = a + 1
    System.out.println(a);
    
    먼저 1을 더하고 다음 동작을 수행한다.
    */
    ```



###  비교연산자

- `== , !=, >, <, >=, <=` 등 값을 비교하는 연산자를 비교 연산자라고 한다.
- 연산의 결과는 boolean 값으로 나타난다.



###  논리연산자

- 여러 조건이 있을 때에 구분할 수 있게 하는 연산자
- `&&, ||`등
- `&&` 두 개의 조건이 모두 true인 경우만 true
- `||` 두 개의 조건이 모두 false인 경우만 false



###  삼항연산자

- (조건) ? (true일 때의 반환 값) : (false일 때의 반환값)
  - `age >= 20 ? true : false`



### 형변환 (타입케스팅)

- 서로 다른 타입 사이에서 변환하는 작업을 말한다

- 주의 사항 : 범위가 작은 타입에서 큰 타입으로 넘어가는 것은 괜찮지만 큰 범위에서 작은 범위로 바뀌는 것은 주의해야한다.

  ```java
  byte value = 127;
  short shortValue = (short) value;  // byte 타입의 value가 short 타입으로 변환됨
  shortValue += 1;  // shortValue는 128이 된다.
  byte convertByte = (byte) shortValue; // convertByte의 값은 -128이 된다.
  
  /**
  값이 이상하게 나오는 이유?
  2진수로 나타내면 이렇게 되어있음
  01111111  (첫번째 줄의 value)
  short로 타입 캐스팅
  0000000001111111 (short는 2바이트이기 때문에 이와 같이 표현됨)
  shortValue +1
  0000000010000000
  byte로 타입 캐스팅
  10000000 (앞에 00000000 이 사라짐)
  결국 -128로 출력됨
  */
  
  
  ```



###  비트연산자

- `&, |, ^, ~, <<, >>, >>>` 등이 있다.
- **AND (&)**: 두 비트가 모두 1일 때 1 반환 (둘 다 1이어야 1).
- **OR (|)**: 두 비트 중 하나라도 1이면 1 반환.
- **XOR (^)**: 두 비트가 서로 다를 때 1 반환.
- **NOT (~)**: 비트를 0은 1로, 1은 0으로 반전 (1의 보수).
- **왼쪽 시프트 (<<)**: 비트들을 왼쪽으로 이동, 오른쪽은 0으로 채움 (2배씩 증가).
- **오른쪽 시프트 (>>)**: 비트들을 오른쪽으로 이동, 부호 비트는 유지. 



###  &&와 &의 차이점

- `&&`의 경우 앞의 조건이 false인 경우 뒤의 조건을 검사하지 않는다
- `&`의 경우 앞의 조건이 false이더라도 뒤의 조건을 검사한다.

## 🎯 마무리

####  직접해 봅시다

```java
public class SalaryManager{
    public double getMonthlySalary(int yearlySalary) {
        double monthSalary = (double) yearlySalary / 12.0;
        double totalTax = 0;
        
        totalTax += calculateTax(monthSalary);
        totalTax += calculateNationalPersion(monthSalary);
        totalTax += calculateHealthInsurance(monthSalary);
        
        monthSalary -= totalTax
        
        return monthSalary;
    }
    // 근로소득세 반환
    public double calculateTax(double monthSalary) {
        double tax = 12.5;
        return monthSalary / 100 * tax;
    }
    
    // 국민 연금 공제금 반환
    public double calculateNationalPersion(double monthSalary) {
        double tax = 8.1;
        return monthSalary / 100 * tax;
    }
    
    // 건강보험료 반환
    public double calculateHealthInsurance(double monthSalary) {
        double tax = 13.5;
        return monthSalary / 100 * tax;
    }
    
    public static void main(String [] args){
        SalaryManager manager = new SalaryManager();
        System.out.println("한달 급여액은 : " + manager.getMonthlySalary(20000000) + "원 입니다.");
    }
}
```



#### 정리해 봅시다

1. 할당 연산자는 = 이며, 우측에는 할당할 값, 좌측에는 할당 받을 변수를 위치시켜야 한다.



2. 사칙연산 연산자는 + - * / 이며, 나머지는 % 연산자를 사용하면 된다.



3. += 는 기존 값에 우측 항의 값을 더할 때 사용한다.



4. 연산할 때 연산자의 우선순위가 혼동될 경우에는 소괄호()를 사용하면 계산의 가독성을 높일 수 있다.



5. == 는 값이 동등한지를, !=는 값이 다른지를 확인하는 연산자이다. 두 연산의 결과는 모두 boolean 타입이다.



6. 두 연산자의 차이는 우측항의 값이 포함되는지 여부이다. =이 있는 연산자는 우측항의 값을 포함한다.



7. ! 연산자는 무조건 boolean 타입에만 사용할 수 있다. 해당 결과의 반대로 변환한다. (true일 때에는 false로, false일 때에는 true로 변환한다.)



8. "? :"연산자는 값을 간편하게 할당할 때 사용한다. 조건이 true일 경우에는 ? 뒤의 값을, false일 경우에는 : 뒤의 값을 지정한다.



9. short 타입을 long 타입으로 변환할 때에는 casting을 해 줄 필요가 없다. 



10. long 타입을 short 타입으로 변환할 때에는 범위가 큰 타입에서 작은 타입으로 변환되는 것이기 때문에 casting을 해 줘야만 한다.



11. 범위가 큰 타입으로 작은 타입으로 변환할 경우에는 값이 달라질 확률이 매우 높다. 
