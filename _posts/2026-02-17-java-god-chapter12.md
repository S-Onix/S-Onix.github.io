---
title: 자바의 신 12장
date: 2026-02-17 15:17:10 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 12장
- 목표 : 최상위 클래스 Object에 대한 이해도를 높인다.

## 📝 본문

###  모든 자바 클래스의 부모인 java.lang.Object클래스

- 모든 자바 클래스는 Object 클래스의 영향을 받으며 Object 클래스의 기능을 사용할 수 있다.
- 객체를 처리하기 위해 제공해주는 메소드
  - `protected Object clone()` : 객체의 복사본을 만들고 리턴
  - `public boolean equals(Object obj)` : 현재 객체와 매개변수로 넘겨받은 객체가 같은지 확인하는 메소드
  - `protected void finalize()` : 객체를 더 이상 사용하지 않을 때에 가비지 컬렉터에 의해서 호출되는 함수
  - `public Class<?> getClass()` : 현재 객체의 클래스를 반환
  - `public int hashCode()` : 객체에 대한 해시 코드값 리턴 (16진수로 된 객체의 메모리 주소)
  - `public String toString()` : 객체를 문자열로 표현하는 값을 리턴
- 쓰레드를 처리하기 위해 제공해주는 메소드
  - `public void notify()` : 객체 모니터에 대기하는 단일 쓰레드를 깨움
  - `public void notifyAll()` : 객체 모니터에 대기하는 모든 쓰레드를 깨움
  - `public void wait()` : 다른 쓰레드가 notify 혹은 norifyAll 을 호출해주기 전까지 대기
  - `public void wait(long timeout)` : timeout 시간만큼 대기
  - `public void wait(long timeout, int nanos)` : timeout + nanos  시간만큼 대기



###  toString() 메소드

- 해당 클래스가 어떤 객체인지 쉽게 나타낼 수 있는 메소드

- 기본적으로 `패키지경로 + 클래스명 + @ + 주소값(16진수)` 으로 출력된다.

- 보통 `toString()`메소드를 Overriding 후 객체의 정보를 출력하게 변환한다.

  ```java
  public class MemberDTO {
      String name;
      int age;
      String email;
      
      @Override
      public String toString(){
          return "[name = " + this.name + ", age = " + this.age + ", email = " + this.email + "]";
      }
  }
  
  /**
  	MemberDTO 를 타 객체에서 호출시
  	toString() 으로 정의된 내용으로 출력된다.
  */
  
  ```



###  equals()

- 객체의 동일 여부를 확인하기 위해서 사용되는 메소드이다.

- 객체의 값을 비교하는 것이 아니라 객체의 **주소 값(hashCode)**을 비교하는 것이다.

- `toString()` 과 마찬가지로 Overriding 후 객체의 정보가 같으면 동일한 것으로 판단하게 할 수 있다.

  ```java
  public static void main(String [] args) {
      MemberDTO menber1 = new MemberDTO();
      MemberDTO member2 = new MemberDTO();
      
      if(member1.equals(member2)) {
          System.out.println("two object is equal");
      }else {
          System.out.println("two object is not equal");
      }
      /**
      두 객체의 주소값을 다르기 때문에
      two object is not equal 이 출력된다.
      */
      
  }
  ```

  ```java
  public class MemberDTO{
      ....
      
      public boolean equals(Object obj){
          if(this == obj) return true;
          if(obj == null) return false;
          
          if (getClass() != obj.getClass()) return false;
          
          MemberDTO other = (MemberDTO) obj;
          
          if(name == null) {
              if(other.name != null) return false;
          }else if(!name.equals(other.name)) return false;
          
          if(email == null) {
              if(other.email != null) return false;
          }else if(!email.equals(other.email)) return false;
          
          if(age != other.age) return false;
          
          return true;
      }
      
      public int hashCode(){
          final int prime = 31;
          int result = 1;
          result = prime*result + ((email) == null) ? 0 : email.hashCode();
          result = prime*result + ((age) == null) ? 0 : email.hashCode();
          result = prime*result + ((name) == null) ? 0 : email.hashCode();
          
          return result;
      }
  }
  ```

- `equals()` 뿐만 아니라 `hashCode()` 까지 Overriding 해야 주소 값도 같은 것으로 인지가 된다.



###  객체의 고유값을 나타내는 hashCode()

- 기본적으로 객체의 메모리 주소를 16진수로 리턴한다.



## 🎯 마무리

####  직접해 봅시다

```java
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
    
    @Override
    public String toString(){
        return name + " " + address + " " + phone + " " + email;
    }   
    
    @Override
    public boolean equals(Object obj){
        if(this == obj) return true;
        if(obj == null) return false;
        if(getClass() != obj.getClass()) return false;
        
        
        Student other = (Student) obj;
        
        if(name.equals(obj.name) 
           && phone.equals(obj.phone)
           && address.equals(obj.address)
           && email.equals(obj.email))
            ) {
            return true;
        }else 
            return false;
    }
    
    @Override
    public int hashCode(){
        final int prime = 31;
        int result = 1;
        result = prime * result + ((address == null) ? 0 : address.hashCode());
        result = prime * result + ((phone == null) ? 0 : address.hashCode());
        result = prime * result + ((email == null) ? 0 : address.hashCode());
        result = prime * result + ((name == null) ? 0 : address.hashCode());
        
        return result;
        
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
    
    public void checkEquals(){
        Student a = new Student("Min","Seoul", "010XXXXXXXX", "test@gmail.com");
        Student b = new Student("Min","Seoul", "010XXXXXXXX", "test@gmail.com");
        
        if(a.equals(b)) {
            System.out.println("Equal");
        }else {
            System.out.println("Not Equal");
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

1. Object 클래스는 java.lang 패키지에 선언되어 있다.



2. 클래스 파일만 갖고 클래스가 어떻게 선언되어 있는지 확인하려면 javap 명령을 사용하면 된다. 



3. Object 클래스에 선언되어 있는 메소드 중에서 필요한 메소드만 Overriding하여 사용하면 된다.



4. clone() 메소드는 객체를 복제하기 위해서 사용한다.



5. 참조 자료형을 System.out.println() 메소드에서 출력하면 toString() 메소드가 호출된 결과가 제공된다.



6. 참조 자료형의 비교는 equals() 메소드를 사용해야 확실히 비교가 가능하다.

만약 직접 구현한 클래스의 비교를 정확하게 하려면, 이 equals() 메소드를 Overriding하는 것이 좋다.

7. hashCode() 메소드는 int 타입의 결과를 리턴한다. 
