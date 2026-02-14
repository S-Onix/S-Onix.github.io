---
title: 자바의 신 8장
date: 2026-02-14 23:29:55 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 8장
- 목표 : 참조 자료형에 대해 놓친 부분을 다시 점검한다.

## 📝 본문

###  참조 자료형?

- 기본 자료형을 제외한 자료형을 참조 자료형이라고 한다.
  - 기본 자료형은 `byte, short, int, long, char, float, double, boolean` 등이 있다.



###  생성자

- 자바는 생성자를 만들지 않아도 자동으로 만들어주는 생성자가 있다. (**기본 생성자**)
- 별도의 생성자를 만들고 기본 생성자를 호출하면 에러가 발생한다.

```java
// 정상 동작
public class ReferenceDefault {
    public static void main(String [] args) {
        ReferenceDefault reference = new ReferenceDefault();
    }
}
```

```java
// 에러 발생
public class ReferenceDefault {
    public ReferenceDefault(String str) {}
    
    public static void main(String [] args) {
        ReferenceDefault reference = new ReferenceDefault();
    }
}
```

- **기본 생성자는 다른 생성자가 없을 때에 자동으로 만들어주지만 다른 생성자가 있을 시에는 생성하지 않는다.**
- 보통 클래스를 작성한 순서는 `인스턴스 변수 선언 > 생성자 > 메소드` 로 진행된다.
- 생성자를 만들 수 있는 개수는 제한되어 있지 않다.



###  갑자기 DTO?

- DTO란 Data Transfer Object라는 약어로서 데이터를 옮기기 위한 객채를 의미한다.
- 실 상황에서는 다양한 데이터를 한번에 옮겨야 하는 경우가 있다.
- 그럴 때에 DTO 클래스를 정의해주고 객채로 만들어 데이터를 세팅한 이후 다른 메소드 혹은 서버로 옮겨주면 된다.
- 다양한 생성자를 통해 전송하기 원하는 데이터를 세팅하고 보낼 수 있다.



###  This

- 클래스의 인스턴스 변수(객체의 변수)와 매개변수를 구분하기 위한 예약어 이다.

  ```java
  public class Test{
      int a;
      
      public void setA(int a) {
          // 왼쪽의 a는 클래스의 인스턴스 변수
          // 오른쪽의 a는 메소드의 매개 변수
          this.a = a;
      }
  }
  ```



###  메소드 Overloading

- 메소드의 이름이 같을 수 있다. 그럴 때에 매개변수의 갯수 혹은 타입을 다르게 함으로 동일한 이름을 가진 메소드를 만들 수 있다.
- 이미 사용하는 메소드 중에 `System.out.println()`을 많이 사용한다
  - 이 때에 `println()` 메소드는 다양한 타입을 매개변수로 받을 수 있다.
  - 사용자는 메소드 Overloading의 기능으로 아무 생각 없이 정수형, 실수형, 문자열형 등을 넣고 사용할 수 있는 것이다.

```java
// 다른 타입의 매개변수가 1개인 경우 혹은 매개변수의 갯수가 다른 경우 메소드 overloading이 가능하다.
public class OverloadingPractice {
    public void print(int a) {
        System.out.print(a);
    }
    
    public void print(double a) {
        System.out.print(a);
    }
    
    public void print(String a, String b) {
        System.out.print(a + b);
    }
}
```



###  메소드에서 값 넘겨주기

- 메소드의 종료 조건
  - 메소드의 모든 문장 실행시
  - return 문장에 도달 했을 때
  - 예외가 발생한 경우

- return 이후 추가로 코드가 작성되어 있다면 에러가 발생한다.
- 여러개의 값을 넘겨주고 싶은 경우에는 앞에서 이야기한 DTO 객채를 만들어서 넘겨주면 된다.
- 중간 특정 조건에 걸려 메소드를 종료하고 싶을 시에는 `return`을 사용한다. (return type이 void여도 상관 없음)



###  static 메소드와 일반 메소드의 차이

- `static`이 선언된 변수는 클래스가 생성시 같이 만들어진다고 했다.

- 마찬가지로 `static`이 선언된 메소드는 클래스가 생성시 같이 만들어진다.

- 객체를 만든다는 것이 아니다.

- `static`이 선언된 메소드는 `static`변수만 호출 할 수 있다.

- `static`이 선언된 변수를 호출 할 때에는 주의해야한다.

  ```java
  public class Test {
      static int a;
      
      public Test(int a) {
          this.a = a;
      }
      
      public static void main(String [] args) {
          Test t1 = new Test(10);
          System.out.println(t1.a);  // 10 출력
          Test t2 = new Test(11);
          System.out.println(t1.a);  // 11 출력
      }
      
      /**
      동일하게 t1의 a를 호출 했는데 10과 11이 출력됬는가?
      클래스 변수는 값을 공유하기 때문이다.
      */
  }
  ```

- 클래스에서 객체가 처음으로 생성될 때에만 한번만 불리는 코드

  - static 블록으로 만들어준다.
  - static 블록은 클래스 안에 있어야한다 (메소드 안에는 선언 불가)

  ```java
  static{
      // 객체가 여러개 만들더라도 처음 객체가 만들어지기 전에 한번만 실행된다.
      // static 으로 선언된 변수 혹은 메소드만 작성될 수 있다.
      
  }
  ```





###  Pass By Value, Pass By Reference

- 둘의 차이점 : [Pass by Value](https://www.google.com/search?q=Pass+by+Value&oq=pass+by+value+pass+by+reference+차이점&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIHCAEQABiABDIGCAIQABgeMgYIAxAAGB4yBggEEAAYHjIGCAUQABgeMgYIBhAAGB4yBggHEAAYHjIGCAgQABgeMgYICRAAGB7SAQkxMDU5MWowajeoAgCwAgA&sourceid=chrome&ie=UTF-8&ved=2ahUKEwjEuLzCoNmSAxW0rlYBHdACLkMQgK4QegQIARAC)(값에 의한 전달)는 함수 호출 시 인자값의 복사본을 전달하여 원본이 변경되지 않는 방식인 반면, [Pass by Reference](https://www.google.com/search?q=Pass+by+Reference&oq=pass+by+value+pass+by+reference+차이점&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIHCAEQABiABDIGCAIQABgeMgYIAxAAGB4yBggEEAAYHjIGCAUQABgeMgYIBhAAGB4yBggHEAAYHjIGCAgQABgeMgYICRAAGB7SAQkxMDU5MWowajeoAgCwAgA&sourceid=chrome&ie=UTF-8&ved=2ahUKEwjEuLzCoNmSAxW0rlYBHdACLkMQgK4QegQIARAD)(참조에 의한 전달)는 데이터의 메모리 주소(참조)를 전달하여 함수 내부에서 원본 데이터를 직접 수정할 수 있는 방식

- | 특징            | Pass by Value                  | Pass by Reference                    |
  | :-------------- | :----------------------------- | :----------------------------------- |
  | **전달 내용**   | 값의 복사본 (Copy)             | 실제 메모리 주소 (Reference/Pointer) |
  | **원본 수정**   | 불가능                         | 가능                                 |
  | **메모리 사용** | 복사본 생성으로 추가 공간 필요 | 별도 복사본 없음                     |
  | **실행 속도**   | 데이터가 크면 느려질 수 있음   | 빠름                                 |
  | **언어 예시**   | 기본 자료형(int, float 등)     | 포인터(C++), 객체 참조 등            |

- 값을 변경할 시에 Pass By Value는 원본 변수가 변경되지 않지만 Pass By Reference는 원본의 데이터가 변경된 값으로 바뀐다.



###  매개 변수를 지정하는 특이한 방법

- 몇개의 변수가 들어올지 모르는 경우가 있다 이때에 사용하는 방법

  ```java
  public void setParam(int ... a); // 배열과 비슷해보이지만 선언하면 다르게 선언된다.
  
  setParam(1);
  setParam(1,2);
  setParam(1,2,3,4);
  setParam(1,2,3);
  setParam(1,2,3,4,5,6,7 ....);
  ```

- 단 `...` 으로 사용되는 변수는 한 메소드에 한 개만 사용가능하며 가장 뒤에 선언해야한다.	

  



## 🎯 마무리

####  직접해 봅시다

```JAVA
public class Student{
    String name;
    String address;
    String phone;
    String email;
    
    public Student(String name) {
        this.name = name;
    }
 	public Student(String name, String address, String phone, String email) {
        this.name = name;
        this.address = address;
        this.phone = phone;
        this.email = email;
    }
    
    public String toString(){
        return name + " " + address + " " + phone + " " + email;
    }   
}


public class ManageStudent{
    
    public Student[] addStudent(){
        student = new Student[3];
        student[0] = new Student("Lim");
        student[1] = new Student("Min");
        student[2] = new Student("Sook", "Seoul", "010XXXXXXXX", "test@gmail.com");

        return student;
    }
    
    public void printStudnets(Students [] students){
        for(Studnet studnet : students) {
			System.out.println(student.toString());
        }
    }
    
    public static void main(String [] args) {
     	Student [] student = null;
        ManageStudnet manageStudnet = new ManageStudnet();
        student = manageStudent.addStudent();
        
    }
}
```





####  정리해 봅시다

1. 생성자는 반드시 만들 필요는 없으나, 만드는 습관을 가지는 것이 좋다.



2. 기본 생성자를 만들지 않고, 매개변수가 있는 생성자만 만들었을 때, 기본 생성자를 사용하여 객체를 생성할 수는 없다. 그러면 컴파일 에러가 발생한다.



3. 생성자의 개수는 제한이 없다.



4. this라는 예약어는 해당 객체를 의미한다. 따라서, 메소드 내에서 this를 사용하면 인스턴스 변수를 의미하게 된다.



5. return 예약어를 사용하여 메소드를 호출한 문장으로 결과를 넘겨준다.



6. void 라는 예약어는 해당 메소드의 리턴 값이 없다는 것을 의미한다.



7. static 메소드는 클래스의 객체를 생성하지 않고 클래스 이름만으로 참조할 수 있다. 

많이 사용하는 System.out.println()의 경우는 System클래스에 out이라는 이름으로 선언된 클래스에 static으로 선언된 println()메소드를 호출하는 것이다.

8.메소드의 이름을 동일하게하고, 매개변수만을 다르게 하는 것은 overloading이다. 

9. 모든 기본 자료형과 참조 자료형은 매개변수로 넘어갈 때 값이 넘어가는 Pass by Value이다. 



10. 모든 기본 자료형과 참조 자료형은 매개변수로 넘어갈 때 값이 넘어가는 Pass by Value이다. 

단, 참조 자료형 안에 있는 변수들은 매개변수로 넘어갈 때 참조가 넘어가는 Pass by Reference 이다. 

11. 가변 매개변수를 지정할 때에는 "변수타입...변수명"으로 선언하면 된다. 이 선언을 할 때, 해당 변수는 매개변수 선언의 가장 마지막에 위치해야만 한다. 
