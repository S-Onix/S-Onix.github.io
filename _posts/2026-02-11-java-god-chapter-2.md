---
title: 자바의 신2장
date: 2026-02-11 21:26:24 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 2장

- 목표 : cmd 환경에서 자바를 실행하는 방법을 익힌다

## 📝 본문

### CMD?

- 윈도의 명령 프롬프트
- 단축키 windows+R 누른 이후  cmd 입력

![image-20260211213129140](/_posts/assets/img/posts/2026-02-11-java-god-chapter-2/image-20260211213129140.png)

###  자바설치여부 확인

- cmd 화면에서 `java` 를 입력 > 아래와 같은 화면이 나오면 정상적으로 설치된 것이 확인된다.

  ![image-20260211213716470](/_posts/assets/img/posts/2026-02-11-java-god-chapter-2/image-20260211213716470.png)



###  HelloGOdOfJava 만들기

- 프로그래밍 언어가 실행 되려면 **컴파일**이 되야하는데 자바 프로그램이 실행되는 과정은 아래와 같다.

  - **컴파일**이란? 사용자 혹은 개발자가 만든 프로그램 코드를 컴퓨터가 이해할 수 있도록 엮어 주는 작업

  - **자바의 컴파일러**는? `javac.exe` 파일이 컴파일러 역할을 한다.

  - **자바 프로그램 실행 과정 : 소스작성 > 컴파일러(바이트 코드로 변환) > 디스크 > JVM > 운영체제**

    - `.java` 파일이 **컴파일러**를 통해 `.class`파일(바이트 코드)로 변환된다.
    - `.class` 파일은 바이너리 파일로 구성되어 있다.
    - 컴파일 된 `.class` 파일은 `JVM(Java Virtual Machine)`이 읽어서 운영체제에서 실행된다.

    ````java
    /** ex) test.java
       1. test 소스코드 작성
       2. 확장자를 .java로 파일 저장
       3. cmd 화면에서 test.java 파일이 있는 위치로 이동
       		cd {test.java file path}
       4. cmd 화면에서 javac test.java 실행
       5. test.class 파일 만들어졌는지 확인
       6. cmd 화면에서 java test 실행
       7. test.java의 기능이 동작했는지 확인
          7-1. 성공
          7-2. 실패 : 실패시 에러코드가 cmd 화면에 출력됨
    */
    ````

- 자바 프로그램이 실행되기 위해서는 **반드시** `main()` 메소드가 필요하다.

  - `main()` 이 왜 필요한가? 자바프로그램의 시작(진입지점) 위치다.
  - `main()`이 없으면 자바 프로그램은 시작점을 모르고 에러를 반환한다.

  ````java
  public static void main(String [] args) {
      
  }
  ````



###  간단한 화면 출력

- 화면에 메세지가 출력되게 하는 방법
  - `System.out.println("메세지 입력")`
  - `System.out.print("메세지 입력")`
  - 첫번째 방법은 메세지가 출력되고 한줄이 띄워지고, 두번째 방법은 뒤에 이어서 메세지가 출력된다.



## 🎯 마무리

####  직접해 봅시다

````java
/**
1. Profile 클래스 생성 후 main 메소드 작성
2. 화면 출력용 메세지 작성
*/
public class Profile {
    public static void main(String [] args) {
        System.out.println("message1");
        System.out.println("message1");
    }
}
````





####  정리해봅시다

1.  public static void

```java
public : 어떤 클래스에서도 접근 가능하며
static : static 메소드이며 (객체를 생성하지 않아도 접근 가능한 메소드이며 "C.1"장에서 자세히 살펴본다.)
void : 리턴 값이 없음
을 의미한다. 
```

2. String args[]

```java
즉, String문자열의 배열이 들어간다. 이 배열에 대한 설명은 "B.4"장에서 자세히 살펴본다.
```



3.  public static void main(String args[]) 로 선언되어 있는 메소드가 클래스에 없으면, 해당 클래스를 실행할 수는 없다.

4.  System.out.println() 메소드는 자바를 실행한 창에서 문자열을 출력하는데 사용된다. 

5.  System.out.print() 메소드는 줄바꿈을 하지 않기 때문에, 이 메소드 호출 후에 출력 메소드를 호출하면 같은 줄에 결과가 출력된다. 하지만, System.out.println() 메소드는 내용을 출력한 다음에 줄바꿈을 한다.

6. //는 한 줄 주석을 의미한다. 따라서, 해당 코드의 // 뒤에 있는 모든 내용은 무시된다.

7. /*으로 시작하여 */으로 끝나는 주석은 블록 주석으로, 해당 블록 내의 모든 내용은 무시된다.

8. 메소드에는 반드시 "리턴 타입", "메소드 이름", "메소드 내용"이 있어야만 한다. 

