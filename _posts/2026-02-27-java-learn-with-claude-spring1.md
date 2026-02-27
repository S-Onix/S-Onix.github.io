---
title: Spring 깊이 이해하기 1편 - Web Serve vs Web Application Server
date: 2026-02-27 16:12:35 +0900
categories: [자바, 클로드, F-lab]  # 예: [개발, Python]
tags: [자바, 스프링, Web]        # 예: [python, tutorial]
---

## 📌 소개

- 소개 : 클로드 문답형식을 활용한 스프링 공부
- 목표 : Web Server와 WAS의 차이를 공부한다.

## 📝 본문

## 1. Web Server와 WAS, 뭐가 다를까?

### Web Server — 있는 걸 그냥 주는 카운터 직원

Web Server는 **정적 리소스**(HTML, CSS, JS, 이미지)를 클라이언트에게 전달하는 서버입니다. 별도의 연산 없이, 요청받은 파일을 그대로 응답합니다. 대표적으로 **Nginx**, **Apache HTTP Server**가 있습니다.

### WAS (Web Application Server) — 주문에 맞게 만들어주는 주방

WAS는 **동적 콘텐츠**를 처리합니다. 클라이언트의 요청에 따라 비즈니스 로직을 실행하고, 데이터베이스와 통신하여 그 결과를 동적으로 생성해서 응답합니다. 대표적으로 **Tomcat**, **Jetty**, **Undertow**가 있습니다.

### 실무에서는 둘을 함께 사용합니다

```
클라이언트 → Nginx(Web Server) → Spring Boot / Tomcat(WAS)
```

Nginx가 정적 파일 서빙, SSL 처리, 로드밸런싱 등을 담당하고, 동적 요청만 Spring Boot로 넘기는 구조가 일반적입니다. 이렇게 하면 WAS의 부담이 줄어들고, 각 구성 요소가 자기 역할에 집중할 수 있습니다.

------



## 2. Embedded Server — Spring Boot가 선택한 방식

### WAR vs JAR

Spring Boot 이전에는 WAR(Web Application Archive) 파일을 만들어 외장 Tomcat에 배포했습니다.

bash

```bash
# 옛날 방식
mvn package → myapp.war → /tomcat/webapps/에 복사 → catalina.sh start
```

Spring Boot는 Tomcat을 의존성으로 내장시켜, JAR 하나로 실행할 수 있게 만들었습니다.

bash

```bash
# Spring Boot 방식
mvn package → myapp.jar (Tomcat 내장) → java -jar myapp.jar
```

이렇게 만들어진 JAR를 **Fat JAR(또는 Uber JAR)**라고 부릅니다. 애플리케이션 코드와 모든 의존성 라이브러리(Tomcat 포함)를 하나의 파일에 합친 것입니다. "Uber"는 독일어로 "초월"이라는 뜻으로, 일반 JAR를 넘어선다는 의미입니다.

### spring-boot-starter-web

이 하나의 의존성만 추가하면 Spring MVC 개발에 필요한 모든 것이 함께 포함됩니다.

```
spring-boot-starter-web
├── spring-web              (Spring MVC 핵심)
├── spring-webmvc           (DispatcherServlet 등)
├── spring-boot-starter-tomcat   (내장 Tomcat)
├── spring-boot-starter-json     (Jackson, JSON 변환)
└── spring-boot-starter-validation (Bean Validation)
```

Tomcat 대신 Jetty나 Undertow를 사용하고 싶다면, 기본 Tomcat을 제외하고 원하는 서버 스타터를 추가하면 됩니다.

### Docker와의 궁합

Fat JAR 방식은 컨테이너화와 매우 잘 어울립니다. 이미지 하나에 앱과 서버가 모두 들어있기 때문입니다.

dockerfile

```dockerfile
FROM eclipse-temurin:17-jre
COPY myapp.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

이 구조가 Auto Scaling 환경에서 빛을 발합니다. 새 서버를 띄울 때 이미지 하나만 실행하면 되니까요.

------



## 핵심 키워드

| 키워드                      | 설명                                                         |
| --------------------------- | ------------------------------------------------------------ |
| **Web Server**              | 정적 리소스를 전달하는 서버 (Nginx, Apache)                  |
| **WAS**                     | 비즈니스 로직을 실행하여 동적 콘텐츠를 생성하는 서버 (Tomcat, Jetty) |
| **Embedded Server**         | 애플리케이션 안에 서버가 라이브러리로 포함된 것              |
| **Fat JAR (Uber JAR)**      | 코드 + 모든 의존성을 하나의 JAR에 합친 것                    |
| **WAR**                     | 외장 서블릿 컨테이너에 배포하기 위한 웹 앱 패키징 형식       |
| **spring-boot-starter-web** | Spring MVC 개발에 필요한 의존성을 한번에 가져오는 스타터     |



## 🎯 면접 예상 질문

### Q1. Web Server와 WAS의 차이를 설명해주세요.

**모범 답안:**

> Web Server는 HTML, CSS, JS, 이미지 같은 정적 리소스를 클라이언트에 전달하는 서버이고, 대표적으로 Nginx와 Apache HTTP Server가 있습니다. WAS는 비즈니스 로직을 실행하여 동적 콘텐츠를 생성하는 서버로, 대표적으로 Tomcat, Jetty, Undertow가 있습니다. 실무에서는 Nginx를 앞단에 두어 정적 파일 서빙, SSL Termination, 로드밸런싱을 담당하게 하고, 동적 요청만 WAS로 전달하는 구조를 사용합니다.

**주의할 점:**

- Apache HTTP Server와 Apache Tomcat은 완전히 다른 소프트웨어입니다. 전자는 Web Server, 후자는 WAS(Servlet Container)입니다.
- Netty는 WAS(Servlet Container)가 아닙니다. 비동기 네트워크 프레임워크입니다. WAS 예시로는 Tomcat, Jetty, Undertow가 적절합니다.
- SSL 암복호화는 "정적 데이터"가 아닙니다. 통신 구간을 암호화하는 기능이며, Nginx의 Reverse Proxy 역할에 해당합니다.

### Q2. Spring Boot는 내장 Tomcat을 사용하는데, WAR 배포 대신 JAR 배포를 선택한 이유는 무엇일까요?

**모범 답안:**

> WAR 방식에서는 외장 Tomcat의 버전 관리, 설정 관리, 여러 WAR의 충돌 등 운영 부담이 컸습니다. Spring Boot가 내장 Tomcat을 채택하면서 `java -jar` 한 줄로 실행 가능해졌고, 애플리케이션과 서버의 버전이 함께 관리되어 환경 간 불일치 문제가 해소되었습니다.

### Q3. Fat JAR(Uber JAR)란 무엇이며, 이 방식이 컨테이너 환경(Docker)에서 유리한 이유는 무엇인가요?

**모범 답안:**

> Fat JAR는 애플리케이션 코드, 모든 의존성 라이브러리, 내장 서버를 하나의 JAR에 합친 것입니다. Docker 환경에서는 베이스 이미지(JRE) 위에 JAR 하나만 올리면 되어 이미지 구성이 단순하고, Auto Scaling 시 새 인스턴스를 빠르게 띄울 수 있습니다.
