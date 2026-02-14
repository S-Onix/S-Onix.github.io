---
title: 자바의 신 7장
date: 2026-02-14 22:39:11 +0900
categories: [도서, 자바의 신]  # 예: [개발, Python]
tags: [자바의 신, 자바]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 자바의 신 7장 리뷰
- 목표 : 배열에 대해서 다시 복습한다.



## 🎯 마무리

####  직접해 봅시다

```java
public class ManageHeight {
    int [][] gradeHeights;
    
    public void setData(){
        gradeHeights = {
            {170, 180, 173, 175,177}
          , {160, 165, 167, 186}
          , {158, 177, 187, 176}
          , {172, 182, 181}
          , {170, 180, 165, 177, 172}
        }
    }
    
    public void printHeight(int classNo) {
        for(int height : gradeHeights[classNo-1]) {
            System.out.println(height);
        }
    }
    
    public void printAverage(int classNo) {
		double totalHeights = 0;
        double classMemberNum = gradeHeights[classNo-1].length;
        
        for(int height : gradeHeights[classNo-1]) {
            totalHeights += height;
        }
        
        
        System.out.println("Class No." + classNo + " average heights is" + totalHeights/classMemberNum);
    }
    
    public static void main(String [] args) {
        for(int i = 0; i < gradeHeights.length; i++) {
            System.out.println("Class No.:" + i+1);
            //printHeight(i);
            printAverage(i+1);
        }
    }
}
```





####  정리해 봅시다

1. 배열을 선언할 때에는 대괄호 [ ] 를 사용해야 한다.



2. 배열의 위치는 0부터 시작한다.



3. 숫자 배열의 초기 값은 0, boolean 배열의 초기 값은 false이다.



4. ArrayIndexOutOfBoundsException 은 배열의 범위를 벗어난 위치를 참조하려고 할 때 발생한다. 즉, 10자리 배열에 12번째 위치를 참조하려는 경우에 발생한다.



5. 중괄호를 이용하여 배열을 선언할 때, 중괄호를 닫은 다음에 반드시 세미콜론 ; 을 입력해야만 한다.



6. 2차원 배열을 지정할 때에는 대괄호를 2개 지정한다. 



7. 배열을 처리하는 for 루프는 다음과 같이 사용할 수 있다. 

```java
int[] a;로 선언되어 있는 배열은

for(int data:a) { 
... 
}
와 같이 콜론을 사용하여 사용 가능하다. 
```



8.main() 메소드의 String args[] 라는 매개변수는 java명령 실행시 클래스 이름 뒤에 나열된 값을 취한다. 

```java
예를 들어 ArrayTest라는 클래스가 시작하면서 값을 전달하려면
java ArrayTest a b c
와 같이 사용 가능하며, ArrayTest클래스의 main() 메소드의 매개변수인 args[] 배열의 0,1,2 위치에 있는 배열은 각각 a,b,c의 값이 할당된다.
    
```

9. 8번 문제의 답에서 이야기한 대로 String의 1차원 배열로 값이 전달된다.

